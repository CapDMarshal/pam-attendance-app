"""
Face Recognition API Server
FastAPI server for face recognition using InsightFace
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import numpy as np
from PIL import Image
import io
import logging
import cv2
from face_recognition import FaceRecognitionModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Face Recognition API",
    description="API for face recognition using InsightFace",
    version="2.0.0"
)

# Configure CORS - allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variable for model
face_model = None


@app.on_event("startup")
async def load_models():
    """Load face recognition model on startup"""
    global face_model
    
    try:
        logger.info("Initializing InsightFace model...")
        face_model = FaceRecognitionModel()
        logger.info("Face recognition model loaded successfully!")
        
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Face Recognition API - InsightFace",
        "status": "running",
        "version": "2.0.0",
        "docs": "/docs"
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
    Recognize face from uploaded image
    
    Returns:
        - status: 'recognized', 'unrecognized', or 'undetected'
        - message: Human-readable message
        - name: Person's name (if recognized)
        - confidence: Similarity score
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
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Convert to OpenCV format (BGR)
        img_array = np.array(image)
        img_bgr = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
        
        # Recognize face
        result = face_model.recognize(img_bgr)
        
        # Return result with success=true for all valid responses
        return {
            "success": True,
            **result
        }
        
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing image: {str(e)}"
        )


@app.post("/api/clock-in")
async def clock_in(file: UploadFile = File(...)):
    """
    Clock-in with face recognition
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
        
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        img_array = np.array(image)
        img_bgr = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
        
        # Recognize face
        result = face_model.recognize(img_bgr)
        
        # Only proceed if face is recognized
        if result['status'] == 'recognized':
            # Record clock-in time
            from datetime import datetime
            import json
            import os
            
            timestamp = datetime.now().isoformat()
            
            # Load or create attendance records
            attendance_file = "attendance.json"
            if os.path.exists(attendance_file):
                with open(attendance_file, "r") as f:
                    attendance_data = json.load(f)
            else:
                attendance_data = []
            
            # Add clock-in record
            clock_in_record = {
                "name": result['name'],
                "type": "clock-in",
                "timestamp": timestamp,
                "confidence": result['confidence']
            }
            
            attendance_data.append(clock_in_record)
            
            # Save to file
            with open(attendance_file, "w") as f:
                json.dump(attendance_data, f, indent=2)
            
            logger.info(f"Clock-in recorded for {result['name']} at {timestamp}")
            
            return {
                "success": True,
                "status": "recognized",
                "message": f"Clock-in successful for {result['name']}",
                "name": result['name'],
                "timestamp": timestamp,
                "confidence": result['confidence']
            }
        
        else:
            # Face not recognized or not detected
            return {
                "success": True,
                "status": result['status'],
                "message": result['message'],
                "name": None,
                "timestamp": None,
                "confidence": result.get('confidence', 0)
            }
        
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing image: {str(e)}"
        )


@app.post("/api/clock-out")
async def clock_out(file: UploadFile = File(...)):
    """
    Clock-out with face recognition
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
        
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        img_array = np.array(image)
        img_bgr = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
        
        # Recognize face
        result = face_model.recognize(img_bgr)
        
        # Only proceed if face is recognized
        if result['status'] == 'recognized':
            # Record clock-out time
            from datetime import datetime
            import json
            import os
            
            timestamp = datetime.now().isoformat()
            
            # Load or create attendance records
            attendance_file = "attendance.json"
            if os.path.exists(attendance_file):
                with open(attendance_file, "r") as f:
                    attendance_data = json.load(f)
            else:
                attendance_data = []
            
            # Add clock-out record
            clock_out_record = {
                "name": result['name'],
                "type": "clock-out",
                "timestamp": timestamp,
                "confidence": result['confidence']
            }
            
            attendance_data.append(clock_out_record)
            
            # Save to file
            with open(attendance_file, "w") as f:
                json.dump(attendance_data, f, indent=2)
            
            logger.info(f"Clock-out recorded for {result['name']} at {timestamp}")
            
            return {
                "success": True,
                "status": "recognized",
                "message": f"Clock-out successful for {result['name']}",
                "name": result['name'],
                "timestamp": timestamp,
                "confidence": result['confidence']
            }
        
        else:
            # Face not recognized or not detected
            return {
                "success": True,
                "status": result['status'],
                "message": result['message'],
                "name": None,
                "timestamp": None,
                "confidence": result.get('confidence', 0)
            }
        
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing image: {str(e)}"
        )


@app.post("/api/register")
async def register_face(name: str, file: UploadFile = File(...)):
    """
    Register a new face
    
    Args:
        name: Person's name
        file: Image file with clear face
    """
    if face_model is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded"
        )
    
    if not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=400,
            detail="File must be an image"
        )
    
    try:
        # Read and convert image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        img_array = np.array(image)
        img_bgr = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
        
        # Register face
        result = face_model.register_face(img_bgr, name)
        
        return result
        
    except Exception as e:
        logger.error(f"Error registering face: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error registering face: {str(e)}"
        )


@app.get("/api/registered-faces")
async def get_registered_faces():
    """Get list of registered faces"""
    if face_model is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded"
        )
    
    return {
        "success": True,
        "registered_faces": list(face_model.registered_faces.keys()),
        "count": len(face_model.registered_faces)
    }


@app.get("/api/attendance/{name}")
async def get_attendance(name: str):
    """Get attendance records for a specific person"""
    import json
    import os
    
    attendance_file = "attendance.json"
    
    if not os.path.exists(attendance_file):
        return {
            "success": True,
            "name": name,
            "records": [],
            "message": "No attendance records found"
        }
    
    with open(attendance_file, "r") as f:
        attendance_data = json.load(f)
    
    # Filter records for the specified person
    person_records = [
        record for record in attendance_data 
        if record.get("name") == name
    ]
    
    return {
        "success": True,
        "name": name,
        "records": person_records,
        "total_records": len(person_records)
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000, log_level="info")
