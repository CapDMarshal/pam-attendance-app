"""
Face Recognition API Server
FastAPI server for face recognition using MTCNN and FaceNet
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import joblib
import numpy as np
from keras_facenet import FaceNet
from mtcnn import MTCNN
from PIL import Image
import io
import logging
from typing import Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Face Recognition API",
    description="API for face recognition using MTCNN and FaceNet",
    version="1.0.0"
)

# Configure CORS - allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for models
detector = None
embedder = None
knn_model = None

# Model path
MODEL_PATH = 'model_wajah_knn.pkl'


@app.on_event("startup")
async def load_models():
    """Load face recognition models on startup"""
    global detector, embedder, knn_model
    
    try:
        logger.info("Loading MTCNN detector...")
        detector = MTCNN()
        
        logger.info("Loading FaceNet embedder...")
        embedder = FaceNet()
        
        logger.info(f"Loading KNN model from {MODEL_PATH}...")
        knn_model = joblib.load(MODEL_PATH)
        
        logger.info("All models loaded successfully!")
        
    except FileNotFoundError:
        logger.error(f"Model file not found: {MODEL_PATH}")
        logger.error("Please ensure model_wajah_knn.pkl is in the project directory")
    except Exception as e:
        logger.error(f"Error loading models: {str(e)}")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Face Recognition API",
        "status": "running",
        "docs": "/docs"
    }


@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    models_loaded = all([detector is not None, embedder is not None, knn_model is not None])
    
    return {
        "status": "healthy" if models_loaded else "unhealthy",
        "models_loaded": models_loaded,
        "detector": detector is not None,
        "embedder": embedder is not None,
        "knn_model": knn_model is not None
    }


@app.post("/api/recognize")
async def recognize_face(file: UploadFile = File(...)):
    """
    Recognize face from uploaded image
    
    Args:
        file: Image file (JPEG, PNG)
        
    Returns:
        JSON response with recognition result
    """
    # Check if models are loaded
    if not all([detector, embedder, knn_model]):
        raise HTTPException(
            status_code=503,
            detail="Models not loaded. Please check server logs."
        )
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=400,
            detail="File must be an image (JPEG, PNG)"
        )
    
    try:
        # Read image file
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Convert to numpy array
        img_array = np.array(image)
        
        # Detect face
        logger.info("Detecting face...")
        faces = detector.detect_faces(img_array)
        
        if not faces:
            return JSONResponse(
                status_code=200,
                content={
                    "success": False,
                    "message": "No face detected in the image",
                    "name": None,
                    "confidence": None
                }
            )
        
        # Get the first detected face
        face = faces[0]
        x, y, width, height = face['box']
        
        # Ensure coordinates are within image bounds
        x, y = max(0, x), max(0, y)
        x2, y2 = min(img_array.shape[1], x + width), min(img_array.shape[0], y + height)
        
        # Extract face region
        face_img = img_array[y:y2, x:x2]
        
        # Resize face to 160x160 (required by FaceNet)
        face_img = Image.fromarray(face_img).resize((160, 160))
        face_array = np.array(face_img)
        
        # Add batch dimension
        face_array = np.expand_dims(face_array, axis=0)
        
        # Get face embedding
        logger.info("Generating face embedding...")
        embedding = embedder.embeddings(face_array)
        
        # Predict using KNN model
        logger.info("Predicting identity...")
        prediction = knn_model.predict(embedding)
        distances, indices = knn_model.kneighbors(embedding)
        
        # Get the predicted name and distance
        predicted_name = prediction[0]
        distance = distances[0][0]
        
        # Calculate confidence (inverse of distance, normalized)
        # Lower distance = higher confidence
        confidence = max(0, 1 - distance)
        
        logger.info(f"Prediction: {predicted_name}, Distance: {distance:.4f}, Confidence: {confidence:.4f}")
        
        return {
            "success": True,
            "message": "Face recognized successfully",
            "name": predicted_name,
            "distance": float(distance),
            "confidence": float(confidence),
            "face_detected": True,
            "face_box": {
                "x": int(x),
                "y": int(y),
                "width": int(width),
                "height": int(height)
            }
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
    
    Args:
        file: Image file (JPEG, PNG)
        
    Returns:
        JSON response with clock-in result
    """
    # Check if models are loaded
    if not all([detector, embedder, knn_model]):
        raise HTTPException(
            status_code=503,
            detail="Models not loaded. Please check server logs."
        )
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=400,
            detail="File must be an image (JPEG, PNG)"
        )
    
    try:
        # Read image file
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Convert to numpy array
        img_array = np.array(image)
        
        # Detect face
        logger.info("Detecting face...")
        faces = detector.detect_faces(img_array)
        
        if not faces:
            return JSONResponse(
                status_code=200,
                content={
                    "success": False,
                    "message": "No face detected in the image",
                    "timestamp": None
                }
            )
        
        # Get the first detected face
        face = faces[0]
        x, y, width, height = face['box']
        
        # Ensure coordinates are within image bounds
        x, y = max(0, x), max(0, y)
        x2, y2 = min(img_array.shape[1], x + width), min(img_array.shape[0], y + height)
        
        # Extract face region
        face_img = img_array[y:y2, x:x2]
        
        # Resize face to 160x160 (required by FaceNet)
        face_img = Image.fromarray(face_img).resize((160, 160))
        face_array = np.array(face_img)
        
        # Add batch dimension
        face_array = np.expand_dims(face_array, axis=0)
        
        # Get face embedding
        logger.info("Generating face embedding...")
        embedding = embedder.embeddings(face_array)
        
        # Predict using KNN model
        logger.info("Predicting identity...")
        prediction = knn_model.predict(embedding)
        distances, indices = knn_model.kneighbors(embedding)
        
        # Get the predicted name and distance
        predicted_name = prediction[0]
        distance = distances[0][0]
        
        # Calculate confidence (inverse of distance, normalized)
        confidence = max(0, 1 - distance)
        
        logger.info(f"Prediction: {predicted_name}, Distance: {distance:.4f}, Confidence: {confidence:.4f}")
        
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
            "name": predicted_name,
            "type": "clock-in",
            "timestamp": timestamp,
            "confidence": float(confidence),
            "distance": float(distance)
        }
        
        attendance_data.append(clock_in_record)
        
        # Save to file
        with open(attendance_file, "w") as f:
            json.dump(attendance_data, f, indent=2)
        
        logger.info(f"Clock-in recorded for {predicted_name} at {timestamp}")
        
        return {
            "success": True,
            "message": f"Clock-in successful for {predicted_name}",
            "name": predicted_name,
            "timestamp": timestamp,
            "confidence": float(confidence)
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
    
    Args:
        file: Image file (JPEG, PNG)
        
    Returns:
        JSON response with clock-out result
    """
    # Check if models are loaded
    if not all([detector, embedder, knn_model]):
        raise HTTPException(
            status_code=503,
            detail="Models not loaded. Please check server logs."
        )
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=400,
            detail="File must be an image (JPEG, PNG)"
        )
    
    try:
        # Read image file
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Convert to numpy array
        img_array = np.array(image)
        
        # Detect face
        logger.info("Detecting face...")
        faces = detector.detect_faces(img_array)
        
        if not faces:
            return JSONResponse(
                status_code=200,
                content={
                    "success": False,
                    "message": "No face detected in the image",
                    "timestamp": None
                }
            )
        
        # Get the first detected face
        face = faces[0]
        x, y, width, height = face['box']
        
        # Ensure coordinates are within image bounds
        x, y = max(0, x), max(0, y)
        x2, y2 = min(img_array.shape[1], x + width), min(img_array.shape[0], y + height)
        
        # Extract face region
        face_img = img_array[y:y2, x:x2]
        
        # Resize face to 160x160 (required by FaceNet)
        face_img = Image.fromarray(face_img).resize((160, 160))
        face_array = np.array(face_img)
        
        # Add batch dimension
        face_array = np.expand_dims(face_array, axis=0)
        
        # Get face embedding
        logger.info("Generating face embedding...")
        embedding = embedder.embeddings(face_array)
        
        # Predict using KNN model
        logger.info("Predicting identity...")
        prediction = knn_model.predict(embedding)
        distances, indices = knn_model.kneighbors(embedding)
        
        # Get the predicted name and distance
        predicted_name = prediction[0]
        distance = distances[0][0]
        
        # Calculate confidence (inverse of distance, normalized)
        confidence = max(0, 1 - distance)
        
        logger.info(f"Prediction: {predicted_name}, Distance: {distance:.4f}, Confidence: {confidence:.4f}")
        
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
            "name": predicted_name,
            "type": "clock-out",
            "timestamp": timestamp,
            "confidence": float(confidence),
            "distance": float(distance)
        }
        
        attendance_data.append(clock_out_record)
        
        # Save to file
        with open(attendance_file, "w") as f:
            json.dump(attendance_data, f, indent=2)
        
        logger.info(f"Clock-out recorded for {predicted_name} at {timestamp}")
        
        return {
            "success": True,
            "message": f"Clock-out successful for {predicted_name}",
            "name": predicted_name,
            "timestamp": timestamp,
            "confidence": float(confidence)
        }
        
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing image: {str(e)}"
        )


@app.get("/api/attendance/{name}")
async def get_attendance(name: str):
    """
    Get attendance records for a specific person
    
    Args:
        name: Person's name
        
    Returns:
        JSON response with attendance records
    """
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
