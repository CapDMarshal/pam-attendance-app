import time
import os
import logging
import numpy as np
import cv2

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

from deepface import DeepFace

def benchmark():
    logger.info("Generating dummy image...")
    # Create a dummy image (1024x1024)
    img = np.random.randint(0, 255, (1024, 1024, 3), dtype=np.uint8)
    
    logger.info("Warming up RetinaFace...")
    # Warmup
    try:
        DeepFace.extract_faces(img, detector_backend='retinaface', enforce_detection=False)
    except Exception as e:
        logger.error(f"Warmup failed: {e}")
        return

    logger.info("Starting Benchmark (5 iterations)...")
    times = []
    for i in range(5):
        start = time.time()
        DeepFace.extract_faces(img, detector_backend='retinaface', enforce_detection=False)
        end = time.time()
        duration = end - start
        times.append(duration)
        logger.info(f"Iter {i+1}: {duration:.4f}s")

    avg_time = sum(times) / len(times)
    logger.info(f"Average Time: {avg_time:.4f}s")
    
    if avg_time > 1.0:
        logger.warning("⚠️ High latency detected! Likely running on CPU.")
    else:
        logger.info("🚀 Performance looks good (GPU likely active).")

if __name__ == "__main__":
    benchmark()
