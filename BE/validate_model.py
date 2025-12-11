import os
import sys
import re
import shutil
import cv2
import numpy as np
import logging
from pathlib import Path
from tqdm import tqdm
import time

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

# Force GPU Configuration
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

# Paths
BASE_DIR = Path(__file__).parent.parent
DATA_TRAIN = BASE_DIR / "datasets" / "Data Train"
DATA_TEST = BASE_DIR / "datasets" / "Data Test"
TEMP_DB = BASE_DIR / "datasets" / "temp_aligned_db"
CONFUSION_MATRIX_FILE = BASE_DIR / "BE" / "confusion_matrix.png"

# Patch for Keras 3 compatibility
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"
os.environ["TF_USE_LEGACY_KERAS"] = "1"
os.environ["DEEPFACE_HOME"] = str(BASE_DIR / "BE")

def setup_weights():
    """Copy custom weights to DeepFace home"""
    deepface_home = Path(BASE_DIR / "BE" / ".deepface")
    weights_dir = deepface_home / "weights"
    weights_dir.mkdir(parents=True, exist_ok=True)
    custom_model = BASE_DIR / "BE" / "deepfacemodel" / "retinaface.h5"
    target_model = weights_dir / "retinaface.h5"
    if custom_model.exists() and not target_model.exists():
        shutil.copy2(custom_model, target_model)

setup_weights()

try:
    import tensorflow as tf
    try:
        from tensorflow import keras
    except ImportError:
        import tf_keras
        sys.modules["tensorflow.keras"] = tf_keras
        tf.keras = tf_keras
except Exception:
    pass

from deepface import DeepFace
from sklearn.metrics import accuracy_score, f1_score, confusion_matrix, classification_report
import matplotlib.pyplot as plt
import seaborn as sns

NAME_PATTERN = re.compile(r"^\d+_([A-Za-z0-9 ]+)_\d+\.(jpg|jpeg|png)$", re.IGNORECASE)

def extract_name(filename):
    match = NAME_PATTERN.match(filename)
    if match:
        return match.group(1).strip()
    return None

def prepare_database():
    if TEMP_DB.exists():
        return
    TEMP_DB.mkdir(parents=True, exist_ok=True)
    logger.info("Preparing temporary database from Data Train...")
    files = list(DATA_TRAIN.glob("*.*"))
    for file_path in tqdm(files, desc="Copying training images"):
        if not file_path.suffix.lower() in ['.jpg', '.jpeg', '.png']:
            continue
        name = extract_name(file_path.name)
        if not name: continue
        person_dir = TEMP_DB / name
        person_dir.mkdir(exist_ok=True)
        shutil.copy2(file_path, person_dir / file_path.name)

import pickle

def generate_db_embeddings():
    """
    Pre-calculates embeddings for all images in the training set.
    Returns:
        embeddings: List of embedding vectors
        labels: List of names corresponding to embeddings
    """
    CACHE_FILE = BASE_DIR / "BE" / "embeddings_cache.pkl"
    
    if CACHE_FILE.exists():
        logger.info("Loading embeddings from cache...")
        with open(CACHE_FILE, 'rb') as f:
            data = pickle.load(f)
        logger.info(f"Loaded {len(data['embeddings'])} embeddings from cache.")
        return data['embeddings'], data['labels']

    logger.info("Generating embeddings for Training Database (This may take a while)...")
    embeddings = []
    labels = []
    
    # Iterate through each person folder in TEMP_DB
    person_dirs = [d for d in TEMP_DB.iterdir() if d.is_dir()]
    
    for person_dir in tqdm(person_dirs, desc="Building Index"):
        person_name = person_dir.name
        images = list(person_dir.glob("*.*"))
        
        for img_path in images:
            try:
                # Generate embedding
                # We use specific function to avoid overhead
                embedding_objs = DeepFace.represent(
                    img_path=str(img_path),
                    model_name="ArcFace",
                    detector_backend="retinaface",
                    enforce_detection=False,
                    align=True
                )
                
                # represent returns a list of detected faces, we take the first one
                if len(embedding_objs) > 0:
                    embedding = embedding_objs[0]["embedding"]
                    embeddings.append(embedding)
                    labels.append(person_name)
                    
            except Exception as e:
                logger.error(f"Failed to process {img_path.name}: {e}")

    logger.info(f"Index built! Total known faces: {len(embeddings)}")
    
    # Save cache
    with open(CACHE_FILE, 'wb') as f:
        pickle.dump({'embeddings': np.array(embeddings), 'labels': labels}, f)
    logger.info(f"Embeddings saved to {CACHE_FILE}")

    return np.array(embeddings), labels

def find_closest_match(target_embedding, db_embeddings, db_labels, threshold=0.68):
    """
    Finds the closest match using Cosine Similarity (DeepFace default for ArcFace).
    ArcFace Threshold is typically 0.68 for Cosine.
    """
    # Calculate Cosine Distance
    # distance = 1 - cosine_similarity
    # We can use DeepFace's verify logic or manual calculation
    
    min_dist = float("inf")
    best_label = "Unknown"
    
    # Vectorized calculation is faster
    # Cosine distance = 1 - (A . B) / (||A|| * ||B||)
    # DeepFace embeddings are usually not normalized by default in 'represent', let's check.
    # Actually DeepFace's find/verify uses functions from deepface.commons.distance
    
    # Simple Loop for clarity (or vectorized if db is large)
    # Using L2 (Euclidean) is often easier, but ArcFace prefers Cosine.
    
    # Optimized Vectorized Cosine Distance
    target_norm = np.linalg.norm(target_embedding)
    
    # Avoid div by zero
    if target_norm == 0: return "Unknown"
    
    # array of norms
    db_norms = np.linalg.norm(db_embeddings, axis=1)
    
    # dot products
    dots = np.dot(db_embeddings, target_embedding)
    
    # cosine similarities
    similarities = dots / (db_norms * target_norm)
    
    # cosine distances = 1 - similarity
    distances = 1 - similarities
    
    # Find min distance
    min_index = np.argmin(distances)
    min_dist = distances[min_index]
    
    # Log logic (optional debug)
    # logger.info(f"Min Dist: {min_dist} (Threshold: {threshold})")
    
    if min_dist <= threshold:
        return db_labels[min_index]
    
    return "Unknown"

def run_validation():
    if not TEMP_DB.exists():
        prepare_database()
        
    # 1. Build In-Memory Index (The magic fix for speed)
    db_embeddings, db_labels = generate_db_embeddings()
    
    if len(db_embeddings) == 0:
        logger.error("No training data found!")
        return

    logger.info("Starting validation on Test Data...")
    
    y_true = []
    y_pred = []
    
    files = list(DATA_TEST.glob("*.*"))
    known_classes = set(db_labels)
    
    start_time = time.time()
    
    for file_path in tqdm(files, desc="Validating"):
        if not file_path.suffix.lower() in ['.jpg', '.jpeg', '.png']:
            continue
        
        true_name = extract_name(file_path.name)
        if not true_name: continue
        if true_name not in known_classes: continue

        y_true.append(true_name)
        
        try:
            # Generate embedding for ID
            embedding_objs = DeepFace.represent(
                img_path=str(file_path),
                model_name="ArcFace",
                detector_backend="retinaface",
                enforce_detection=False,
                align=True
            )
            
            predicted_name = "Unknown"
            
            if len(embedding_objs) > 0:
                target_embedding = embedding_objs[0]["embedding"]
                
                # 2. Fast In-Memory Search
                predicted_name = find_closest_match(target_embedding, db_embeddings, db_labels)
            
            y_pred.append(predicted_name)
            
        except Exception as e:
            y_pred.append("Error")

    total_time = time.time() - start_time
    logger.info(f"Validation finished in {total_time:.2f}s")
    
    # Metrics
    unique_labels = sorted(list(set(y_true + y_pred)))
    acc = accuracy_score(y_true, y_pred)
    f1 = f1_score(y_true, y_pred, average='weighted', zero_division=0)
    
    logger.info("="*50)
    logger.info(f"Validation Results:")
    logger.info(f"Accuracy: {acc:.4f}")
    logger.info(f"F1 Score (Weighted): {f1:.4f}")
    logger.info("="*50)
    
    cm = confusion_matrix(y_true, y_pred, labels=unique_labels)
    plt.figure(figsize=(20, 20))
    sns.heatmap(cm, annot=False, fmt='d', cmap='Blues', xticklabels=unique_labels, yticklabels=unique_labels)
    plt.title('Confusion Matrix')
    plt.tight_layout()
    plt.savefig(CONFUSION_MATRIX_FILE)
    logger.info(f"Confusion Matrix saved to {CONFUSION_MATRIX_FILE}")

if __name__ == "__main__":
    try:
        run_validation()
    except KeyboardInterrupt:
        logger.info("Validation stopped by user.")
