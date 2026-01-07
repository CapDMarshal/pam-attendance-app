import os
import glob
import re
import logging
from pathlib import Path
import cv2
from tqdm import tqdm
from facenet_model import FaceNetRecognitionModel

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

def parse_name(filename):
    """
    Parse filename to extract ID_Name.
    Example: '5221911012_Debora_10.jpg' -> '5221911012_Debora'
    Strategy: Remove the last underscore and number part.
    """
    # Remove file extension
    base = os.path.splitext(filename)[0]
    
    # Check if format matches Name_Number or ID_Name_Number
    # We want to remove the last segment if it's a number
    parts = base.split('_')
    
    if len(parts) > 1 and parts[-1].isdigit():
        return '_'.join(parts[:-1])
    
    return base

def main():
    # Paths
    BASE_DIR = Path(__file__).parent
    SOURCE_DIR = BASE_DIR / "datasets" / "new_dataset"
    
    if not SOURCE_DIR.exists():
        logger.error(f"Source directory not found: {SOURCE_DIR}")
        return

    logger.info("Initializing FaceNet model...")
    model = FaceNetRecognitionModel()
    
    # Get list of images
    extensions = ['*.jpg', '*.jpeg', '*.png']
    files = []
    for ext in extensions:
        files.extend(list(SOURCE_DIR.glob(ext)))
    
    logger.info(f"Found {len(files)} images in {SOURCE_DIR}")
    
    # Track processed names to avoid overwriting (since we only support 1 embedding per person currently)
    processed_names = set()
    
    # Pre-fill with already registered names
    for name in model.registered_faces.keys():
        processed_names.add(name)
        
    logger.info(f"Already registered: {len(processed_names)} faces")
    
    success_count = 0
    skip_count = 0
    fail_count = 0
    
    # Sort files to ensure deterministic order (maybe prioritize lower numbers like _01.jpg?)
    files.sort()
    
    for file_path in tqdm(files, desc="Importing Faces"):
        filename = file_path.name
        
        # Parse target name (ID_Name)
        target_name = parse_name(filename)
        
        if target_name in processed_names:
            # logger.info(f"Skipping {target_name} (already registered)")
            skip_count += 1
            continue
            
        try:
            # Load image
            img = cv2.imread(str(file_path))
            if img is None:
                logger.error(f"Failed to load image: {filename}")
                fail_count += 1
                continue
            
            # Register face
            # This handles detection, extraction, embedding generation, and saving to registered_faces/
            result = model.register_face(img, target_name)
            
            if result['success']:
                logger.info(f"✅ Registered: {target_name} (from {filename})")
                processed_names.add(target_name)
                success_count += 1
            else:
                logger.warning(f"❌ Failed to register {target_name}: {result['message']}")
                fail_count += 1
                
        except Exception as e:
            logger.error(f"Error processing {filename}: {e}")
            fail_count += 1

    logger.info("="*50)
    logger.info("IMPORT COMPLETED")
    logger.info(f"✅ Successfully Registered: {success_count}")
    logger.info(f"⏭️ Skipped (Already Exists): {skip_count}")
    logger.info(f"❌ Failed: {fail_count}")
    logger.info("="*50)

if __name__ == "__main__":
    main()
