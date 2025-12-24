"""
Face Recognition Module using FaceNet and OpenCV
Optimized for speed with OpenCV DNN face detection and FaceNet embeddings
"""

import numpy as np
import cv2
import json
import os
from pathlib import Path
import logging
from keras_facenet import FaceNet
from sklearn.metrics.pairwise import cosine_similarity
import pickle

logger = logging.getLogger(__name__)


class FaceNetRecognitionModel:
    """
    Face recognition using FaceNet and OpenCV optimizations
    
    Three states:
    - recognized: Face detected and matched to registered user
    - unrecognized: Face detected but not in database
    - undetected: No face found in image
    """
    
    def __init__(self, db_path='registered_faces'):
        """Initialize FaceNet model and OpenCV face detector"""
        self.db_path = db_path
        self.embeddings_file = 'face_embeddings_facenet.pkl'
        self.recognition_threshold = 0.45  # Cosine similarity threshold (lowered for mobile camera variance)
        
        # Create database directory if it doesn't exist
        Path(self.db_path).mkdir(parents=True, exist_ok=True)
        
        logger.info("Initializing FaceNet model...")
        # Initialize FaceNet
        try:
            self.facenet = FaceNet()
            logger.info("✅ FaceNet model loaded successfully")
        except Exception as e:
            logger.error(f"Error loading FaceNet: {e}")
            raise
        
        # Initialize OpenCV face detector (DNN-based for better accuracy and speed)
        logger.info("Initializing OpenCV DNN face detector...")
        try:
            # Download these files if not present
            model_file = "models/res10_300x300_ssd_iter_140000.caffemodel"
            config_file = "models/deploy.prototxt"
            
            # Check if model files exist, if not use Haar Cascade as fallback
            if os.path.exists(model_file) and os.path.exists(config_file):
                self.face_detector = cv2.dnn.readNetFromCaffe(config_file, model_file)
                # Try to use GPU if available (but don't fail if not available)
                gpu_enabled = False
                try:
                    self.face_detector.setPreferableBackend(cv2.dnn.DNN_BACKEND_CUDA)
                    self.face_detector.setPreferableTarget(cv2.dnn.DNN_TARGET_CUDA)
                    # Test if it actually works
                    test_blob = cv2.dnn.blobFromImage(np.zeros((100, 100, 3), dtype=np.uint8), 1.0, (100, 100))
                    self.face_detector.setInput(test_blob)
                    _ = self.face_detector.forward()
                    gpu_enabled = True
                    logger.info("✅ OpenCV DNN face detector loaded with GPU acceleration")
                except Exception as gpu_error:
                    # GPU failed, fall back to CPU
                    logger.info(f"⚠️ GPU acceleration not available: {str(gpu_error)[:50]}...")
                    logger.info("✅ Using CPU backend for OpenCV DNN")
                    # Reset to CPU backend
                    self.face_detector.setPreferableBackend(cv2.dnn.DNN_BACKEND_DEFAULT)
                    self.face_detector.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)
                self.detector_type = 'dnn'
            else:
                # Fallback to Haar Cascade (faster but less accurate)
                cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
                self.face_detector = cv2.CascadeClassifier(cascade_path)
                logger.info("⚠️ Using Haar Cascade detector (DNN models not found)")
                self.detector_type = 'haar'
        except Exception as e:
            logger.error(f"Error loading face detector: {e}")
            # Fallback to Haar Cascade
            cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
            self.face_detector = cv2.CascadeClassifier(cascade_path)
            self.detector_type = 'haar'
            logger.info("✅ Using Haar Cascade detector (fallback)")
        
        # Load registered face embeddings
        self.face_embeddings = {}
        self._load_embeddings()
        
        logger.info(f"Database path: {self.db_path}")
        logger.info(f"Loaded {len(self.face_embeddings)} registered faces")
    
    def _detect_faces_dnn(self, image):
        """Detect faces using OpenCV DNN"""
        h, w = image.shape[:2]
        
        # Prepare blob
        blob = cv2.dnn.blobFromImage(image, 1.0, (300, 300), 
                                     (104.0, 177.0, 123.0), False, False)
        
        self.face_detector.setInput(blob)
        detections = self.face_detector.forward()
        
        faces = []
        for i in range(detections.shape[2]):
            confidence = detections[0, 0, i, 2]
            
            # Filter weak detections
            if confidence > 0.5:
                box = detections[0, 0, i, 3:7] * np.array([w, h, w, h])
                (x1, y1, x2, y2) = box.astype("int")
                
                # Ensure coordinates are within image bounds
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)
                
                faces.append((x1, y1, x2 - x1, y2 - y1))
        
        return faces
    
    def _detect_faces_haar(self, image):
        """Detect faces using Haar Cascade"""
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        faces = self.face_detector.detectMultiScale(
            gray,
            scaleFactor=1.1,
            minNeighbors=5,
            minSize=(30, 30)
        )
        return faces
    
    def detect_faces(self, image):
        """Detect faces in image using configured detector"""
        if self.detector_type == 'dnn':
            return self._detect_faces_dnn(image)
        else:
            return self._detect_faces_haar(image)
    
    def _extract_face(self, image, box, target_size=(160, 160)):
        """Extract and preprocess face from image"""
        x, y, w, h = box
        
        # Add padding
        padding = int(0.2 * max(w, h))
        x1 = max(0, x - padding)
        y1 = max(0, y - padding)
        x2 = min(image.shape[1], x + w + padding)
        y2 = min(image.shape[0], y + h + padding)
        
        # Extract face
        face = image[y1:y2, x1:x2]
        
        if face.size == 0:
            return None
        
        # Resize to target size for FaceNet
        face = cv2.resize(face, target_size)
        
        # Convert BGR to RGB
        face = cv2.cvtColor(face, cv2.COLOR_BGR2RGB)
        
        return face
    
    def _get_embedding(self, face):
        """Get FaceNet embedding for a face"""
        # FaceNet expects batch input
        face_batch = np.expand_dims(face, axis=0)
        embedding = self.facenet.embeddings(face_batch)
        return embedding[0]
    
    def _load_embeddings(self):
        """Load saved face embeddings"""
        if os.path.exists(self.embeddings_file):
            try:
                with open(self.embeddings_file, 'rb') as f:
                    self.face_embeddings = pickle.load(f)
                logger.info(f"Loaded {len(self.face_embeddings)} embeddings from {self.embeddings_file}")
            except Exception as e:
                logger.error(f"Error loading embeddings: {e}")
                self.face_embeddings = {}
        else:
            self.face_embeddings = {}
    
    def _save_embeddings(self):
        """Save face embeddings to disk"""
        try:
            with open(self.embeddings_file, 'wb') as f:
                pickle.dump(self.face_embeddings, f)
            logger.info(f"Saved {len(self.face_embeddings)} embeddings to {self.embeddings_file}")
        except Exception as e:
            logger.error(f"Error saving embeddings: {e}")
    
    @property
    def registered_faces(self):
        """Get dictionary of registered faces (for compatibility)"""
        return {name: True for name in self.face_embeddings.keys()}
    
    def register_face(self, image, name):
        """
        Register a new face
        
        Args:
            image: numpy array (BGR format from cv2)
            name: str, person's name
            
        Returns:
            dict with status and message
        """
        try:
            # Detect faces
            faces = self.detect_faces(image)
            
            if len(faces) == 0:
                return {
                    'success': False,
                    'message': 'No face detected in image'
                }
            
            if len(faces) > 1:
                return {
                    'success': False,
                    'message': 'Multiple faces detected. Please use image with single face.'
                }
            
            # Extract face
            face_box = faces[0]
            face = self._extract_face(image, face_box)
            
            if face is None:
                return {
                    'success': False,
                    'message': 'Failed to extract face from image'
                }
            
            # Get embedding
            embedding = self._get_embedding(face)
            
            # Save embedding
            self.face_embeddings[name] = embedding
            self._save_embeddings()
            
            # Also save image for reference
            user_dir = os.path.join(self.db_path, name)
            Path(user_dir).mkdir(parents=True, exist_ok=True)
            img_path = os.path.join(user_dir, f"{name}_1.jpg")
            cv2.imwrite(img_path, image)
            
            logger.info(f"Registered face for {name}")
            return {
                'success': True,
                'message': f'Successfully registered {name}'
            }
            
        except Exception as e:
            logger.error(f"Error registering face: {str(e)}")
            return {
                'success': False,
                'message': f'Error: {str(e)}'
            }
    
    def recognize(self, image):
        """
        Recognize face in image
        
        Args:
            image: numpy array (BGR format from cv2)
            
        Returns:
            dict with status, message, name, and confidence
            - status: 'recognized', 'unrecognized', or 'undetected'
        """
        try:
            # Detect faces
            faces = self.detect_faces(image)
            
            if len(faces) == 0:
                return {
                    'status': 'undetected',
                    'message': 'No face detected in image',
                    'name': None,
                    'confidence': 0.0,
                    'face_detected': False
                }
            
            # Use the first/largest face
            if len(faces) > 1:
                # Get largest face
                faces = sorted(faces, key=lambda x: x[2] * x[3], reverse=True)
            
            face_box = faces[0]
            
            # Extract face
            face = self._extract_face(image, face_box)
            
            if face is None:
                return {
                    'status': 'undetected',
                    'message': 'Failed to extract face',
                    'name': None,
                    'confidence': 0.0,
                    'face_detected': False
                }
            
            # Get embedding
            embedding = self._get_embedding(face)
            
            # Check if database has any faces
            if len(self.face_embeddings) == 0:
                return {
                    'status': 'unrecognized',
                    'message': 'Face not recognized',
                    'name': None,
                    'confidence': 0.0,
                    'face_detected': True
                }
            
            # Compare with all registered faces
            best_match_name = None
            best_similarity = -1
            
            for name, stored_embedding in self.face_embeddings.items():
                # Calculate cosine similarity
                similarity = cosine_similarity(
                    embedding.reshape(1, -1),
                    stored_embedding.reshape(1, -1)
                )[0][0]
                
                if similarity > best_similarity:
                    best_similarity = similarity
                    best_match_name = name
            
            # Check if best match meets threshold
            if best_similarity >= self.recognition_threshold:
                return {
                    'status': 'recognized',
                    'message': f'Welcome, {best_match_name}!',
                    'name': best_match_name,
                    'confidence': float(best_similarity),
                    'face_detected': True
                }
            else:
                return {
                    'status': 'unrecognized',
                    'message': 'Face not recognized',
                    'name': None,
                    'confidence': float(best_similarity),
                    'face_detected': True
                }
                
        except Exception as e:
            logger.error(f"Error recognizing face: {str(e)}")
            return {
                'status': 'undetected',
                'message': 'Error processing image',
                'name': None,
                'confidence': 0.0,
                'face_detected': False
            }
