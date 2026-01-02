"""
FaceNet Model Validation Script
Tests F1 score and accuracy using:
- Training: new_dataset
- Testing: DataTest
"""

import os
import sys
import re
import numpy as np
import cv2
import logging
from pathlib import Path
from tqdm import tqdm
import time
import pickle
from sklearn.metrics import accuracy_score, f1_score, confusion_matrix, classification_report
import matplotlib.pyplot as plt
import seaborn as sns

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

# Force GPU Configuration for FaceNet
try:
    import tensorflow as tf
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        logger.info(f"✅ GPU ENABLED: {gpus}")
    else:
        logger.warning("❌ NO GPU FOUND! Running on CPU.")
except Exception as e:
    logger.error(f"Error configuring GPU: {e}")

# Import FaceNet model
from facenet_model import FaceNetRecognitionModel

# Paths
BASE_DIR = Path(__file__).parent
DATA_TRAIN = BASE_DIR / "datasets" / "new_dataset"
DATA_TEST = BASE_DIR / "datasets" / "DataTest"
TEMP_EMBEDDINGS = BASE_DIR / "temp_facenet_embeddings.pkl"
CONFUSION_MATRIX_FILE = BASE_DIR / "confusion_matrix_facenet.png"

# Filename pattern: expects format like "1_John Doe_1.jpg"
NAME_PATTERN = re.compile(r"^\d+_([A-Za-z0-9 ]+)_\d+\.(jpg|jpeg|png)$", re.IGNORECASE)

def extract_name(filename):
    """Extract person name from filename"""
    match = NAME_PATTERN.match(filename)
    if match:
        return match.group(1).strip()
    return None

def build_training_embeddings(model):
    """
    Build embeddings from training dataset
    Returns:
        embeddings: numpy array of embeddings
        labels: list of corresponding names
    """
    if TEMP_EMBEDDINGS.exists():
        logger.info("Loading embeddings from cache...")
        with open(TEMP_EMBEDDINGS, 'rb') as f:
            data = pickle.load(f)
        logger.info(f"Loaded {len(data['embeddings'])} embeddings from cache.")
        return data['embeddings'], data['labels']
    
    logger.info("Building embeddings from training dataset...")
    embeddings = []
    labels = []
    
    files = list(DATA_TRAIN.glob("*.*"))
    valid_extensions = ['.jpg', '.jpeg', '.png']
    
    for file_path in tqdm(files, desc="Processing training images"):
        if not file_path.suffix.lower() in valid_extensions:
            continue
        
        # Extract name from filename
        name = extract_name(file_path.name)
        if not name:
            logger.warning(f"Skipping {file_path.name} - couldn't extract name")
            continue
        
        try:
            # Load image
            image = cv2.imread(str(file_path))
            if image is None:
                logger.warning(f"Failed to load {file_path.name}")
                continue
            
            # Detect face
            faces = model.detect_faces(image)
            
            if len(faces) == 0:
                logger.warning(f"No face detected in {file_path.name}")
                continue
            
            # Use first/largest face
            if len(faces) > 1:
                faces = sorted(faces, key=lambda x: x[2] * x[3], reverse=True)
            
            face_box = faces[0]
            
            # Extract face
            face = model._extract_face(image, face_box)
            
            if face is None:
                logger.warning(f"Failed to extract face from {file_path.name}")
                continue
            
            # Get embedding
            embedding = model._get_embedding(face)
            
            embeddings.append(embedding)
            labels.append(name)
            
        except Exception as e:
            logger.error(f"Error processing {file_path.name}: {e}")
    
    logger.info(f"Built {len(embeddings)} embeddings from training data")
    
    # Save cache
    embeddings_array = np.array(embeddings)
    with open(TEMP_EMBEDDINGS, 'wb') as f:
        pickle.dump({'embeddings': embeddings_array, 'labels': labels}, f)
    logger.info(f"Embeddings saved to {TEMP_EMBEDDINGS}")
    
    return embeddings_array, labels

def find_best_match(target_embedding, db_embeddings, db_labels, threshold=0.45):
    """
    Find best match using cosine similarity
    
    Args:
        target_embedding: The embedding to match
        db_embeddings: Array of database embeddings
        db_labels: List of labels corresponding to embeddings
        threshold: Similarity threshold (default 0.45 from FaceNet model)
    
    Returns:
        Matched name or "Unknown"
    """
    from sklearn.metrics.pairwise import cosine_similarity
    
    # Calculate similarities
    similarities = cosine_similarity(
        target_embedding.reshape(1, -1),
        db_embeddings
    )[0]
    
    # Find best match
    best_idx = np.argmax(similarities)
    best_similarity = similarities[best_idx]
    
    if best_similarity >= threshold:
        return db_labels[best_idx], best_similarity
    
    return "Unknown", best_similarity

def run_validation():
    """Run validation on test dataset"""
    
    # Check if datasets exist
    if not DATA_TRAIN.exists():
        logger.error(f"Training dataset not found: {DATA_TRAIN}")
        return
    
    if not DATA_TEST.exists():
        logger.error(f"Test dataset not found: {DATA_TEST}")
        return
    
    logger.info("="*60)
    logger.info("FaceNet Model Validation")
    logger.info(f"Training Dataset: {DATA_TRAIN}")
    logger.info(f"Test Dataset: {DATA_TEST}")
    logger.info("="*60)
    
    # Initialize model
    logger.info("Initializing FaceNet model...")
    model = FaceNetRecognitionModel()
    recognition_threshold = model.recognition_threshold
    logger.info(f"Recognition threshold: {recognition_threshold}")
    
    # Build training embeddings
    db_embeddings, db_labels = build_training_embeddings(model)
    
    if len(db_embeddings) == 0:
        logger.error("No training embeddings created!")
        return
    
    # Get unique classes from training data
    known_classes = set(db_labels)
    logger.info(f"Known classes: {len(known_classes)}")
    
    # Validation on test data
    logger.info("Starting validation on test dataset...")
    y_true = []
    y_pred = []
    confidences = []
    
    test_files = list(DATA_TEST.glob("*.*"))
    valid_extensions = ['.jpg', '.jpeg', '.png']
    
    start_time = time.time()
    
    for file_path in tqdm(test_files, desc="Validating"):
        if not file_path.suffix.lower() in valid_extensions:
            continue
        
        # Extract true name
        true_name = extract_name(file_path.name)
        if not true_name:
            continue
        
        # Only evaluate on classes that exist in training data
        if true_name not in known_classes:
            continue
        
        y_true.append(true_name)
        
        try:
            # Load image
            image = cv2.imread(str(file_path))
            if image is None:
                y_pred.append("Unknown")
                confidences.append(0.0)
                continue
            
            # Detect face
            faces = model.detect_faces(image)
            
            if len(faces) == 0:
                y_pred.append("Unknown")
                confidences.append(0.0)
                continue
            
            # Use first/largest face
            if len(faces) > 1:
                faces = sorted(faces, key=lambda x: x[2] * x[3], reverse=True)
            
            face_box = faces[0]
            
            # Extract face
            face = model._extract_face(image, face_box)
            
            if face is None:
                y_pred.append("Unknown")
                confidences.append(0.0)
                continue
            
            # Get embedding
            embedding = model._get_embedding(face)
            
            # Find best match
            predicted_name, confidence = find_best_match(
                embedding, 
                db_embeddings, 
                db_labels, 
                threshold=recognition_threshold
            )
            
            y_pred.append(predicted_name)
            confidences.append(confidence)
            
        except Exception as e:
            logger.error(f"Error processing {file_path.name}: {e}")
            y_pred.append("Error")
            confidences.append(0.0)
    
    total_time = time.time() - start_time
    logger.info(f"Validation completed in {total_time:.2f}s")
    
    # Calculate metrics
    logger.info("\n" + "="*60)
    logger.info("VALIDATION RESULTS")
    logger.info("="*60)
    
    # Overall accuracy
    acc = accuracy_score(y_true, y_pred)
    logger.info(f"Accuracy: {acc:.4f} ({acc*100:.2f}%)")
    
    # F1 Score (weighted average for multi-class)
    f1_weighted = f1_score(y_true, y_pred, average='weighted', zero_division=0)
    logger.info(f"F1 Score (Weighted): {f1_weighted:.4f}")
    
    # F1 Score (macro average)
    f1_macro = f1_score(y_true, y_pred, average='macro', zero_division=0)
    logger.info(f"F1 Score (Macro): {f1_macro:.4f}")
    
    # Average confidence
    avg_confidence = np.mean(confidences)
    logger.info(f"Average Confidence: {avg_confidence:.4f}")
    
    logger.info("="*60)
    
    # Classification report
    logger.info("\nDetailed Classification Report:")
    logger.info("\n" + classification_report(y_true, y_pred, zero_division=0))
    
    # Confusion Matrix
    unique_labels = sorted(list(set(y_true + y_pred)))
    cm = confusion_matrix(y_true, y_pred, labels=unique_labels)
    
    # Plot confusion matrix
    plt.figure(figsize=(max(20, len(unique_labels)), max(20, len(unique_labels))))
    sns.heatmap(cm, annot=False, fmt='d', cmap='Blues', 
                xticklabels=unique_labels, yticklabels=unique_labels)
    plt.title(f'FaceNet Confusion Matrix\nAccuracy: {acc:.4f}, F1: {f1_weighted:.4f}')
    plt.xlabel('Predicted')
    plt.ylabel('True')
    plt.tight_layout()
    plt.savefig(CONFUSION_MATRIX_FILE)
    logger.info(f"\nConfusion matrix saved to {CONFUSION_MATRIX_FILE}")
    
    # Summary statistics
    logger.info(f"\nTest Statistics:")
    logger.info(f"Total test samples: {len(y_true)}")
    logger.info(f"Known classes: {len(known_classes)}")
    logger.info(f"Training samples: {len(db_embeddings)}")
    
    return {
        'accuracy': acc,
        'f1_weighted': f1_weighted,
        'f1_macro': f1_macro,
        'avg_confidence': avg_confidence,
        'total_samples': len(y_true)
    }

if __name__ == "__main__":
    try:
        results = run_validation()
        
        if results:
            logger.info("\n" + "="*60)
            logger.info("FINAL SUMMARY")
            logger.info("="*60)
            logger.info(f"✅ Accuracy: {results['accuracy']*100:.2f}%")
            logger.info(f"✅ F1 Score (Weighted): {results['f1_weighted']:.4f}")
            logger.info(f"✅ F1 Score (Macro): {results['f1_macro']:.4f}")
            logger.info(f"✅ Average Confidence: {results['avg_confidence']:.4f}")
            logger.info("="*60)
            
    except KeyboardInterrupt:
        logger.info("\nValidation stopped by user.")
    except Exception as e:
        logger.error(f"\nValidation failed: {e}")
        import traceback
        traceback.print_exc()
