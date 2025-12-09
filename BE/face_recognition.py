"""
Face Recognition Module using DeepFace
Handles face detection, embedding generation, and recognition
"""

from deepface import DeepFace
import numpy as np
import cv2
import json
import os
from pathlib import Path
import logging
import shutil

logger = logging.getLogger(__name__)


class FaceRecognitionModel:
    """
    Face recognition using DeepFace (with ArcFace backend)
    
    Three states:
    - recognized: Face detected and matched to registered user
    - unrecognized: Face detected but not in database
    - undetected: No face found in image
    """
    
    def __init__(self, db_path='registered_faces'):
        """Initialize DeepFace model and database path"""
        self.db_path = db_path
        self.recognition_threshold = 0.6  # Distance threshold (lower = more strict)
        self.model_name = "ArcFace"  # Can use: VGG-Face, Facenet, ArcFace, etc.
        
        # Create database directory if it doesn't exist
        Path(self.db_path).mkdir(parents=True, exist_ok=True)
        
        logger.info(f"DeepFace initialized with {self.model_name} model")
        logger.info(f"Database path: {self.db_path}")
        
        # Count registered faces
        registered_count = self._count_registered_faces()
        logger.info(f"Loaded {registered_count} registered faces")
    
    def _count_registered_faces(self):
        """Count number of registered users"""
        if not os.path.exists(self.db_path):
            return 0
        return len([d for d in os.listdir(self.db_path) if os.path.isdir(os.path.join(self.db_path, d))])
    
    @property
    def registered_faces(self):
        """Get dictionary of registered faces (for compatibility)"""
        faces = {}
        if os.path.exists(self.db_path):
            for name in os.listdir(self.db_path):
                user_path = os.path.join(self.db_path, name)
                if os.path.isdir(user_path):
                    faces[name] = user_path
        return faces
    
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
            # Verify face is detectable
            result = DeepFace.extract_faces(
                img_path=image,
                detector_backend='opencv',
                enforce_detection=True
            )
            
            if len(result) == 0:
                return {
                    'success': False,
                    'message': 'No face detected in image'
                }
            
            if len(result) > 1:
                return {
                    'success': False,
                    'message': 'Multiple faces detected. Please use image with single face.'
                }
            
            # Create user directory
            user_dir = os.path.join(self.db_path, name)
            Path(user_dir).mkdir(parents=True, exist_ok=True)
            
            # Save image
            img_path = os.path.join(user_dir, f"{name}_1.jpg")
            cv2.imwrite(img_path, image)
            
            logger.info(f"Registered face for {name}")
            return {
                'success': True,
                'message': f'Successfully registered {name}'
            }
            
        except ValueError as e:
            # Face not detected
            return {
                'success': False,
                'message': 'No face detected in image'
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
            # Save temp image for DeepFace
            temp_path = "temp_recognize.jpg"
            cv2.imwrite(temp_path, image)
            
            # Check if database has any faces
            if self._count_registered_faces() == 0:
                os.remove(temp_path)
                return {
                    'status': 'unrecognized',
                    'message': 'Face not recognized',
                    'name': None,
                    'confidence': 0.0,
                    'face_detected': True
                }
            
            # Try to find face in database
            try:
                results = DeepFace.find(
                    img_path=temp_path,
                    db_path=self.db_path,
                    model_name=self.model_name,
                    detector_backend='retinaface',  # More accurate detector
                    enforce_detection=False,  # More lenient - don't fail if face not detected
                    silent=True
                )
                
                os.remove(temp_path)
                
                # Check if any matches found
                if len(results) == 0 or len(results[0]) == 0:
                    return {
                        'status': 'unrecognized',
                        'message': 'Face not recognized',
                        'name': None,
                        'confidence': 0.0,
                        'face_detected': True
                    }
                
                # Get best match
                best_match = results[0].iloc[0]
                identity_path = best_match['identity']
                distance = best_match['distance']
                
                # Extract name from path (registered_faces/name/image.jpg -> name)
                name = identity_path.split(os.sep)[-2]
                
                # Check if distance meets threshold
                if distance <= self.recognition_threshold:
                    confidence = 1 - (distance / 2)  # Normalize to 0-1
                    return {
                        'status': 'recognized',
                        'message': f'Welcome, {name}!',
                        'name': name,
                        'confidence': float(confidence),
                        'face_detected': True
                    }
                else:
                    return {
                        'status': 'unrecognized',
                        'message': 'Face not recognized',
                        'name': None,
                        'confidence': float(1 - distance),
                        'face_detected': True
                    }
                
            except ValueError as e:
                # Face not detected
                if os.path.exists(temp_path):
                    os.remove(temp_path)
                return {
                    'status': 'undetected',
                    'message': 'No face detected in image',
                    'name': None,
                    'confidence': 0.0,
                    'face_detected': False
                }
                
        except Exception as e:
            if os.path.exists(temp_path):
                os.remove(temp_path)
            logger.error(f"Error recognizing face: {str(e)}")
            return {
                'status': 'undetected',
                'message': 'No face detected in image',
                'name': None,
                'confidence': 0.0,
                'face_detected': False
            }
