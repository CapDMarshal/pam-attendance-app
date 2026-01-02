"""
FaceNet Model Validation Script - GPU Optimized
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
from concurrent.futures import ThreadPoolExecutor
import queue
import threading

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

# Force GPU Configuration for FaceNet
try:
    import tensorflow as tf
    # Set logging to error to suppress excessive device placement logs unless needed for debugging
    tf.get_logger().setLevel('ERROR') 
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        logger.info(f"✅ GPU ENABLED: {gpus}")
    else:
        logger.warning("❌ NO GPU FOUND! Running on CPU.")
except Exception as e:
    logger.error(f"Error configuring GPU: {e}")

# Import FaceNet model and MTCNN
from facenet_model import FaceNetRecognitionModel
from mtcnn import MTCNN

# Paths
BASE_DIR = Path(__file__).parent
DATA_TRAIN = BASE_DIR / "datasets" / "new_dataset"
DATA_TEST = BASE_DIR / "datasets" / "DataTest"
TEMP_EMBEDDINGS = BASE_DIR / "temp_gpu_facenet_embeddings.pkl"
CONFUSION_MATRIX_FILE = BASE_DIR / "confusion_matrix_facenet_gpu.png"

# Filename pattern: expects format like "1_John Doe_1.jpg"
NAME_PATTERN = re.compile(r"^\d+_([A-Za-z0-9 ]+)_\d+\.(jpg|jpeg|png)$", re.IGNORECASE)

# Threading parameters
NUM_THREADS = 8  # Number of threads for parallel face detection
BATCH_SIZE = 64  # Batch size for GPU embedding generation
MAX_QUEUE_SIZE = 128 # Queue size to buffer detected faces

def extract_name(filename):
    """Extract person name from filename"""
    match = NAME_PATTERN.match(filename)
    if match:
        return match.group(1).strip()
    return None

def resize_image(image, max_dim=640):
    """Resize image to specific max dimension while keeping aspect ratio"""
    height, width = image.shape[:2]
    if max(height, width) <= max_dim:
        return image, 1.0
        
    scale = max_dim / max(height, width)
    new_width = int(width * scale)
    new_height = int(height * scale)
    
    # Use cv2.INTER_LINEAR for speed
    resized_image = cv2.resize(image, (new_width, new_height))
    return resized_image, scale

class OptimizedFaceDetector:
    """Wrapper for MTCNN to handle resizing and coordinate scaling safely"""
    
    def __init__(self):
        # We need separate detectors for threads if MTCNN isn't thread-safe (it usually is if instantiated per-thread or globally but used carefully).
        # Actually, MTCNN uses TensorFlow. Using it in threads can be tricky with TF sessions.
        # Best approach: Use a single detector but safeguard it, or instantiate in thread.
        # However, for this script, we'll try initializing one MTCNN instance per thread if needed,
        # but standard MTCNN library usage often works if we treat it as an inference call.
        # Let's try with a global one first, if it fails, we make it thread-local.
        pass

def process_file_path(args):
    """Worker function to load image and detect face"""
    file_path, detector = args
    
    try:
        # Load image
        image = cv2.imread(str(file_path))
        if image is None:
            return None
            
        # 1. Resize for detection speed
        # Optimization: Resize large images to max 640px
        process_image, scale = resize_image(image, max_dim=640)
        
        # 2. Detect Faces
        # MTCNN expects RGB
        rgb_image = cv2.cvtColor(process_image, cv2.COLOR_BGR2RGB)
        
        # We assume 'detector' is a thread-safe MTCNN instance or we handle it carefully.
        # Note: In TF 2.x, models are generally thread-safe for inference.
        results = detector.detect_faces(rgb_image)
        
        if not results:
            return None
            
        # Filter weak detections
        valid_faces = [res for res in results if res['confidence'] > 0.9]
        if not valid_faces:
            return None
            
        # Use largest face
        if len(valid_faces) > 1:
            valid_faces = sorted(valid_faces, key=lambda x: x['box'][2] * x['box'][3], reverse=True)
            
        res = valid_faces[0]
        x, y, w, h = res['box']
        
        # Scale back coordinates
        if scale != 1.0:
            x = int(x / scale)
            y = int(y / scale)
            w = int(w / scale)
            h = int(h / scale)
            
        # Ensure coordinates are valid
        x = max(0, x)
        y = max(0, y)
        w = min(w, image.shape[1] - x)
        h = min(h, image.shape[0] - y)
        
        if w <= 0 or h <= 0:
            return None
            
        # 3. Crop Face (High Res from original image)
        
        # Add padding (logic copied from original _extract_face)
        padding = int(0.2 * max(w, h))
        x1 = max(0, x - padding)
        y1 = max(0, y - padding)
        x2 = min(image.shape[1], x + w + padding)
        y2 = min(image.shape[0], y + h + padding)
        
        face = image[y1:y2, x1:x2]
        
        if face.size == 0:
            return None
            
        # Resize to target size for FaceNet (160x160)
        face = cv2.resize(face, (160, 160))
        face = cv2.cvtColor(face, cv2.COLOR_BGR2RGB) # RGB for FaceNet
        
        return face, file_path
        
    except Exception as e:
        # logger.error(f"Error processing {file_path}: {e}")
        return None

def build_training_embeddings(model):
    """
    Build embeddings from training dataset using parallel processing
    """
    if TEMP_EMBEDDINGS.exists():
        logger.info("Loading embeddings from cache...")
        with open(TEMP_EMBEDDINGS, 'rb') as f:
            data = pickle.load(f)
        logger.info(f"Loaded {len(data['embeddings'])} embeddings from cache.")
        return data['embeddings'], data['labels']
    
    logger.info("Building embeddings from training dataset...")
    
    files = list(DATA_TRAIN.glob("*.*"))
    valid_extensions = ['.jpg', '.jpeg', '.png']
    training_files = [f for f in files if f.suffix.lower() in valid_extensions]
    
    # Initialize MTCNN detector
    detector = MTCNN()
    
    embeddings = []
    labels = []
    
    # Process sequentially/parallel
    # For training data (small set 50+ images), sequential or simple parallel is fine
    # Let's reuse the batch pipeline structure for consistency
    
    logger.info(f"Processing {len(training_files)} training images...")
    
    faces_buffer = []
    names_buffer = []
    
    # We'll just run this loop simply as training set is small
    for file_path in tqdm(training_files, desc="Training"):
        name = extract_name(file_path.name)
        if not name:
            continue
            
        result = process_file_path((file_path, detector))
        if result:
            face, _ = result
            faces_buffer.append(face)
            names_buffer.append(name)
            
            if len(faces_buffer) >= BATCH_SIZE:
                batch_embeddings = model.get_embeddings_batch(faces_buffer)
                embeddings.extend(batch_embeddings)
                labels.extend(names_buffer)
                faces_buffer = []
                names_buffer = []
                
    # Process remaining
    if faces_buffer:
        batch_embeddings = model.get_embeddings_batch(faces_buffer)
        embeddings.extend(batch_embeddings)
        labels.extend(names_buffer)

    
    logger.info(f"Built {len(embeddings)} embeddings from training data")
    
    # Save cache
    embeddings_array = np.array(embeddings)
    with open(TEMP_EMBEDDINGS, 'wb') as f:
        pickle.dump({'embeddings': embeddings_array, 'labels': labels}, f)
    logger.info(f"Embeddings saved to {TEMP_EMBEDDINGS}")
    
    return embeddings_array, labels

def find_best_match(target_embedding, db_embeddings, db_labels, threshold=0.45):
    """Vectorized best match finding"""
    from sklearn.metrics.pairwise import cosine_similarity
    
    # Calculate similarities: (1, 512) x (N, 512).T -> (1, N)
    similarities = cosine_similarity(
        target_embedding.reshape(1, -1),
        db_embeddings
    )[0]
    
    best_idx = np.argmax(similarities)
    best_similarity = similarities[best_idx]
    
    if best_similarity >= threshold:
        return db_labels[best_idx], best_similarity
    
    return "Unknown", best_similarity

def run_validation():
    """Run validation - GPU Optimized Pipeline"""
    
    # Check if datasets exist
    if not DATA_TRAIN.exists():
        logger.error(f"Training dataset not found: {DATA_TRAIN}")
        return
        
    if not DATA_TEST.exists():
        logger.error(f"Test dataset not found: {DATA_TEST}")
        return

    logger.info("="*60)
    logger.info("FaceNet Model Validation (GPU OPTIMIZED)")
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
        
    known_classes = set(db_labels)
    logger.info(f"Known classes: {len(known_classes)}")
    
    # Use rglob for recursive search
    test_files = list(DATA_TEST.rglob("*.*"))
    valid_extensions = ['.jpg', '.jpeg', '.png']
    test_files = [f for f in test_files if f.suffix.lower() in valid_extensions]
    
    logger.info(f"Found {len(test_files)} test images")
    logger.info("Starting validation pipeline...")
    
    start_time = time.time()
    
    y_true = []
    y_pred = []
    confidences = []
    
    # --- PIPELINE SETUP ---
    
    # 1. Detection Workers
    # We initialize one detector per thread to be safe with TF session handling in sub-threads if necessary.
    # Actually, initializing MTCNN outside and passing it might cause issues if MTCNN uses global session.
    # To be safe, we will execute detection strictly in the simple ThreadPool but we must ensure TF is thread-safe.
    # Since TF 2.x is eager by default, it usually handles this well.
    # To maximize safety, we will instantiate a *single* detector in the main thread and lock it, OR usage simple sequential detection in threads?
    # MTCNN performance is best on GPU, but we are resizing on CPU.
    # Let's try creating a pool where we pass a thread-local detector if possible.
    # Simplification: Create one detector, pass to threads. If it crashes, we'll fix.
    
    detector = MTCNN() # Main detector
    
    # Buffer for batching
    batch_faces = [] 
    batch_metadata = [] # (true_name, file_path)
    
    processed_count = 0
    
    # Iterate with TSplit Execution
    # We submit tasks to ThreadPoolExecutor
    
    with ThreadPoolExecutor(max_workers=NUM_THREADS) as executor:
        # Create generator for tasks
        # We need to filter known classes first to avoid processing irrelevant files if we want to match original logic EXACTLY?
        # Original logic: "if true_name not in known_classes: continue"
        # We should replicate that check BEFORE submission
        
        valid_tasks = []
        for f in test_files:
            true_name = extract_name(f.name)
            if true_name and true_name in known_classes:
               valid_tasks.append((f, detector))
               # Track y_true only if we actually process it? 
               # Original script added to y_true inside loop. We need to be careful.
               # Actually, original script skips if face not detected -> y_pred="Unknown"
               # So we must include all valid files in y_true eventually.
        
        logger.info(f"Validating {len(valid_tasks)} files for known classes...")
        
        # Submit all tasks
        futures = {executor.submit(process_file_path, task): task[0] for task in valid_tasks}
        
        # Process results as they complete
        from concurrent.futures import as_completed
        
        for future in tqdm(as_completed(futures), total=len(valid_tasks), desc="Processing"):
            file_path = futures[future]
            true_name = extract_name(file_path.name)
            
            try:
                result = future.result()
                
                if result:
                    face, fpath = result
                    batch_faces.append(face)
                    batch_metadata.append(true_name)
                else:
                    # Face detection failed
                    y_true.append(true_name)
                    y_pred.append("Unknown")
                    confidences.append(0.0)
                
                # If batch is full, process on GPU
                if len(batch_faces) >= BATCH_SIZE:
                    embeddings = model.get_embeddings_batch(batch_faces)
                    
                    # Match each embedding
                    for i in range(len(embeddings)):
                        emb = embeddings[i]
                        t_name = batch_metadata[i]
                        
                        pred_name, conf = find_best_match(emb, db_embeddings, db_labels, recognition_threshold)
                        
                        y_true.append(t_name)
                        y_pred.append(pred_name)
                        confidences.append(conf)
                    
                    # Clear buffer
                    batch_faces = []
                    batch_metadata = []
                    
            except Exception as e:
                logger.error(f"Pipeline error on {file_path}: {e}")
                y_true.append(true_name)
                y_pred.append("Error")
                confidences.append(0.0)
                
    # Process remaining items in buffer
    if batch_faces:
        embeddings = model.get_embeddings_batch(batch_faces)
        for i in range(len(embeddings)):
            emb = embeddings[i]
            t_name = batch_metadata[i]
            
            pred_name, conf = find_best_match(emb, db_embeddings, db_labels, recognition_threshold)
            
            y_true.append(t_name)
            y_pred.append(pred_name)
            confidences.append(conf)

    total_time = time.time() - start_time
    logger.info(f"Validation completed in {total_time:.2f}s")
    
    # --- METRICS CALCULATION (Same as original) ---
    
    # Overall accuracy
    acc = accuracy_score(y_true, y_pred)
    logger.info(f"Accuracy: {acc:.4f} ({acc*100:.2f}%)")
    
    # F1 Score
    f1_weighted = f1_score(y_true, y_pred, average='weighted', zero_division=0)
    logger.info(f"F1 Score (Weighted): {f1_weighted:.4f}")
    
    f1_macro = f1_score(y_true, y_pred, average='macro', zero_division=0)
    logger.info(f"F1 Score (Macro): {f1_macro:.4f}")
    
    avg_confidence = np.mean(confidences) if confidences else 0.0
    logger.info(f"Average Confidence: {avg_confidence:.4f}")
    
    # Classification report
    logger.info("\nDetailed Classification Report:")
    logger.info("\n" + classification_report(y_true, y_pred, zero_division=0))
    
    # Confusion Matrix
    unique_labels = sorted(list(set(y_true + y_pred)))
    cm = confusion_matrix(y_true, y_pred, labels=unique_labels)
    
    plt.figure(figsize=(max(20, len(unique_labels)), max(20, len(unique_labels))))
    sns.heatmap(cm, annot=False, fmt='d', cmap='Blues', 
                xticklabels=unique_labels, yticklabels=unique_labels)
    plt.title(f'FaceNet GPU Confusion Matrix\nAccuracy: {acc:.4f}, F1: {f1_weighted:.4f}')
    plt.xlabel('Predicted')
    plt.ylabel('True')
    plt.tight_layout()
    plt.savefig(CONFUSION_MATRIX_FILE)
    logger.info(f"\nConfusion matrix saved to {CONFUSION_MATRIX_FILE}")
    
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
    except KeyboardInterrupt:
        logger.info("\nValidation stopped by user.")
