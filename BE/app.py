"""
Face Recognition API Server
FastAPI server for face recognition using FaceNet with OpenCV optimizations
Stateless Version (Supabase Architecture)
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
import numpy as np
from PIL import Image
import io
import logging
import cv2
from facenet_model import FaceNetRecognitionModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Face Recognition API",
    description="Stateless API for face recognition using FaceNet. Returns NIP/ID for Frontend to handle logic.",
    version="3.1.0"
)

# Configure CORS - allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static file directories to serve images (if needed for debugging)
app.mount("/datasets", StaticFiles(directory="datasets"), name="datasets")
# app.mount("/registered_faces", StaticFiles(directory="registered_faces"), name="registered_faces")

# Global variable for model
face_model = None


@app.on_event("startup")
async def load_models():
    """Load face recognition model on startup"""
    global face_model
    
    try:
        logger.info("Initializing FaceNet model with OpenCV optimizations...")
        face_model = FaceNetRecognitionModel()
        logger.info("Face recognition model loaded successfully!")
        
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Face Recognition API - FaceNet (Stateless)",
        "status": "running",
        "version": "3.1.0",
        "doc": "/docs"
    }


@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    model_loaded = face_model is not None
    num_registered = len(face_model.registered_faces) if face_model else 0
    
    return {
        "status": "healthy" if model_loaded else "unhealthy",
        "model_loaded": model_loaded,
        "registered_faces": num_registered
    }


@app.post("/api/recognize")
async def recognize_face(file: UploadFile = File(...)):
    """
    Recognize face from uploaded image.
    Returns the recognized NIP and Name.
    """
    # Check if model is loaded
    if face_model is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Please check server logs."
        )
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=400,
            detail="File must be an image (JPEG, PNG)"
        )
    
    try:
        # Read and convert image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Apply EXIF orientation
        from PIL import ImageOps
        try:
            image = ImageOps.exif_transpose(image)
        except Exception:
            pass
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Convert to OpenCV format (BGR)
        img_array = np.array(image)
        img_bgr = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
        
        # Recognize face
        result = face_model.recognize(img_bgr)
        
        response_data = {
            "success": True,
            "status": result['status'],
            "message": result['message'],
            "confidence": result.get('confidence', 0.0),
            "face_detected": result.get('face_detected', False),
            "nip": None,
            "name": None
        }
        
        # Parse Name (ID_Name) -> NIP & Name
        if result['status'] == 'recognized' and result.get('name'):
            full_identifier = result['name'] # e.g. "5221911012_Debora"
            
            # Heuristic: Split by first underscore to separate ID from Name
            parts = full_identifier.split('_', 1)
            
            if len(parts) == 2 and parts[0].isdigit():
                response_data['nip'] = parts[0]
                response_data['name'] = parts[1].replace('_', ' ')
            else:
                # Fallback if naming convention isn't followed perfectly
                # Try to use the whole string or handle specific cases
                response_data['nip'] = None
                response_data['name'] = full_identifier

        logger.info(f"📊 Recognition: {response_data['status']} - {response_data.get('name')} ({response_data.get('nip')})")
        
        return response_data
        
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing image: {str(e)}"
        )
