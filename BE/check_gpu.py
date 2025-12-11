import tensorflow as tf
import os

# Suppress warnings
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

print("="*50)
print(f"TensorFlow Version: {tf.__version__}")
print("="*50)

print("\nSearching for GPU...")
gpus = tf.config.list_physical_devices('GPU')

if gpus:
    print(f"SUCCESS: {len(gpus)} GPU(s) found!")
    for i, gpu in enumerate(gpus):
        print(f"  GPU {i}: {gpu.name}")
        
    try:
        # Test basic tensor operation on GPU
        with tf.device('/GPU:0'):
            a = tf.constant([[1.0, 2.0], [3.0, 4.0]])
            b = tf.constant([[1.0, 1.0], [0.0, 1.0]])
            c = tf.matmul(a, b)
            print("\nTest Matrix Multiplication on GPU:")
            print(c)
            print("\nGPU SETUP IS WORKING CORRECTLY!")
    except Exception as e:
        print(f"\nERROR running on GPU: {e}")
else:
    print("FAILURE: No GPU found. TensorFlow is running on CPU.")
    print("\nPossible causes:")
    print("1. CUDA/cuDNN not installed or path not set.")
    print("2. Incompatible TensorFlow/CUDA versions (TF 2.10 requires CUDA 11.2).")
    print("3. GPU not compatible.")

print("="*50)
