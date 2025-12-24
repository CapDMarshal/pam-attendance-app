"""
Face Recognition API Server
FastAPI server for face recognition using FaceNet with OpenCV optimizations
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
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
    description="API for face recognition using FaceNet with OpenCV optimizations",
    version="3.0.0"
)

# Configure CORS - allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static file directories to serve images
app.mount("/datasets", StaticFiles(directory="datasets"), name="datasets")
app.mount("/registered_faces", StaticFiles(directory="registered_faces"), name="registered_faces")

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
        "message": "Face Recognition API - FaceNet",
        "status": "running",
        "version": "3.0.0",
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
        
        # Log image info from upload
        logger.info(f"=== RECOGNIZE REQUEST ===")
        logger.info(f"📁 File: {file.filename}")
        logger.info(f"📦 Content type: {file.content_type}")
        logger.info(f"📏 File size: {len(contents) / 1024:.2f} KB")
        logger.info(f"📐 Image mode: {image.mode}")
        logger.info(f"📐 Image size (before EXIF): {image.size}")
        
        # FIX: Apply EXIF orientation to handle portrait/landscape correctly
        from PIL import ImageOps
        try:
            # This automatically rotates the image based on EXIF orientation tag
            image = ImageOps.exif_transpose(image)
            logger.info(f"✅ EXIF orientation applied")
            logger.info(f"📐 Image size (after EXIF): {image.size}")
        except Exception as e:
            logger.warning(f"⚠️ Could not apply EXIF orientation: {e}")
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Convert to OpenCV format (BGR)
        img_array = np.array(image)
        img_bgr = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
        
        logger.info(f"🖼️ NumPy array shape: {img_array.shape}")
        logger.info(f"🎨 Mean pixel value (BGR): {img_bgr.mean(axis=(0,1))}")
        
        # Recognize face
        result = face_model.recognize(img_bgr)
        
        logger.info(f"📊 Recognition result:")
        logger.info(f"  Status: {result['status']}")
        logger.info(f"  Confidence: {result.get('confidence', 0):.4f}")
        logger.info(f"  Name: {result.get('name', 'None')}")
        logger.info(f"=========================")
        
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
        
        # Apply EXIF orientation (portrait/landscape fix)
        from PIL import ImageOps
        try:
            image = ImageOps.exif_transpose(image)
        except:
            pass  # If no EXIF data, continue
        
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
        
        # Apply EXIF orientation (portrait/landscape fix)
        from PIL import ImageOps
        try:
            image = ImageOps.exif_transpose(image)
        except:
            pass  # If no EXIF data, continue
        
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
        
        # Apply EXIF orientation (portrait/landscape fix)
        from PIL import ImageOps
        try:
            image = ImageOps.exif_transpose(image)
        except:
            pass  # If no EXIF data, continue
        
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




# ============= NEW ENDPOINTS FOR ADMIN AND PORTAL =============


@app.get("/api/users")
async def get_users():
    """Get all users with their attendance summary"""
    import json
    import os
    from datetime import datetime
    
    users_file = "users.json"
    attendance_file = "attendance.json"
    
    if not os.path.exists(users_file):
        return {"success": False, "message": "Users file not found"}
    
    with open(users_file, "r") as f:
        users = json.load(f)
    
    # Get today's attendance if available
    today = datetime.now().date().isoformat()
    attendance_data = []
    
    if os.path.exists(attendance_file):
        with open(attendance_file, "r") as f:
            attendance_data = json.load(f)
    
    # Load status overrides
    statuses_file = "attendance_statuses.json"
    status_overrides = []
    if os.path.exists(statuses_file):
        with open(statuses_file, "r") as f:
            status_overrides = json.load(f)
    
    # Add today's attendance status to each user
    for user in users:
        today_attendance = None
        
        # First, check if there's a status override for today
        for override in status_overrides:
            if override["userId"] == user["id"] and override["date"] == today:
                today_attendance = override["status"]
                break
        
        # If no override, check clock-in records
        if today_attendance is None:
            for record in attendance_data:
                if record.get("name") == user["name"]:
                    record_date = record.get("timestamp", "")[:10]
                    if record_date == today:
                        today_attendance = "attend"
                        break
        
        # Default to alpha if no attendance found
        user["todayAbsention"] = today_attendance or "alpha"
    
    return {
        "success": True,
        "users": users,
        "count": len(users)
    }


@app.get("/api/users/{user_id}")
async def get_user(user_id: str):
    """Get user details by ID"""
    import json
    import os
    
    users_file = "users.json"
    
    if not os.path.exists(users_file):
        raise HTTPException(status_code=404, detail="Users file not found")
    
    with open(users_file, "r") as f:
        users = json.load(f)
    
    user = next((u for u in users if u["id"] == user_id), None)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "success": True,
        "user": user
    }


@app.post("/api/users")
async def create_user(name: str, phone: str, password: str, faceImage: str = ""):
    """Create a new user"""
    import json
    import os
    
    users_file = "users.json"
    
    if not os.path.exists(users_file):
        users = []
    else:
        with open(users_file, "r") as f:
            users = json.load(f)
    
    # Generate new user ID
    max_id = max([int(u["id"]) for u in users], default=0)
    new_id = str(max_id + 1)
    
    new_user = {
        "id": new_id,
        "name": name,
        "phone": phone,
        "password": password,
        "faceImage": faceImage or "/images/avatar-placeholder.png"
    }
    
    users.append(new_user)
    
    with open(users_file, "w") as f:
        json.dump(users, f, indent=2)
    
    return {
        "success": True,
        "message": "User created successfully",
        "user": new_user
    }


@app.put("/api/users/{user_id}")
async def update_user(user_id: str, name: str = None, phone: str = None, password: str = None, faceImage: str = None):
    """Update user information"""
    import json
    import os
    
    users_file = "users.json"
    
    if not os.path.exists(users_file):
        raise HTTPException(status_code=404, detail="Users file not found")
    
    with open(users_file, "r") as f:
        users = json.load(f)
    
    user = next((u for u in users if u["id"] == user_id), None)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update fields if provided
    if name:
        user["name"] = name
    if phone:
        user["phone"] = phone
    if password:
        user["password"] = password
    if faceImage:
        user["faceImage"] = faceImage
    
    with open(users_file, "w") as f:
        json.dump(users, f, indent=2)
    
    return {
        "success": True,
        "message": "User updated successfully",
        "user": user
    }


@app.get("/api/attendance/all")
async def get_all_attendance():
    """Get all attendance records"""
    import json
    import os
    
    attendance_file = "attendance.json"
    
    if not os.path.exists(attendance_file):
        return {
            "success": True,
            "records": [],
            "message": "No attendance records found"
        }
    
    with open(attendance_file, "r") as f:
        attendance_data = json.load(f)
    
    return {
        "success": True,
        "records": attendance_data,
        "total_records": len(attendance_data)
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


@app.get("/api/attendance/user/{user_id}")
async def get_user_attendance(user_id: str):
    """Get attendance records for a specific user by ID"""
    import json
    import os
    
    users_file = "users.json"
    attendance_file = "attendance.json"
    
    # Get user name from ID
    if not os.path.exists(users_file):
        raise HTTPException(status_code=404, detail="Users file not found")
    
    with open(users_file, "r") as f:
        users = json.load(f)
    
    user = next((u for u in users if u["id"] == user_id), None)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if not os.path.exists(attendance_file):
        return {
            "success": True,
            "userId": user_id,
            "userName": user["name"],
            "records": [],
            "message": "No attendance records found"
        }
    
    with open(attendance_file, "r") as f:
        attendance_data = json.load(f)
    
    # Filter records for this user
    user_records = [
        record for record in attendance_data 
        if record.get("name") == user["name"]
    ]
    
    return {
        "success": True,
        "userId": user_id,
        "userName": user["name"],
        "records": user_records,
        "total_records": len(user_records)
    }


@app.get("/api/attendance/user/{user_id}/month/{month}")
async def get_user_attendance_by_month(user_id: str, month: str):
    """Get attendance records for a specific user and month (format: YYYY-MM)"""
    import json
    import os
    
    users_file = "users.json"
    attendance_file = "attendance.json"
    
    # Get user name from ID
    if not os.path.exists(users_file):
        raise HTTPException(status_code=404, detail="Users file not found")
    
    with open(users_file, "r") as f:
        users = json.load(f)
    
    user = next((u for u in users if u["id"] == user_id), None)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if not os.path.exists(attendance_file):
        return {
            "success": True,
            "userId": user_id,
            "userName": user["name"],
            "month": month,
            "records": [],
            "message": "No attendance records found"
        }
    
    with open(attendance_file, "r") as f:
        attendance_data = json.load(f)
    
    # Filter records for this user and month
    user_records = [
        record for record in attendance_data 
        if record.get("name") == user["name"] and record.get("timestamp", "").startswith(month)
    ]
    
    return {
        "success": True,
        "userId": user_id,
        "userName": user["name"],
        "month": month,
        "records": user_records,
        "total_records": len(user_records)
    }


@app.get("/api/attendance/status/month/{month}")
async def get_attendance_with_status(month: str):
    """Get all attendance with status for a specific month"""
    import json
    import os
    from datetime import datetime, timedelta
    
    users_file = "users.json"
    attendance_file = "attendance.json"
    statuses_file = "attendance_statuses.json"
    
    # Load users
    if not os.path.exists(users_file):
        raise HTTPException(status_code=404, detail="Users file not found")
    
    with open(users_file, "r") as f:
        users = json.load(f)
    
    # Load attendance
    attendance_data = []
    if os.path.exists(attendance_file):
        with open(attendance_file, "r") as f:
            attendance_data = json.load(f)
    
    # Load status overrides
    status_overrides = []
    if os.path.exists(statuses_file):
        with open(statuses_file, "r") as f:
            status_overrides = json.load(f)
    
    # Parse month
    year, month_num = map(int, month.split('-'))
    
    # Calculate working days in month (Mon-Fri)
    from calendar import monthrange
    _, days_in_month = monthrange(year, month_num)
    
    working_days = []
    for day in range(1, days_in_month + 1):
        date_obj = datetime(year, month_num, day)
        # 0 = Monday, 6 = Sunday
        if date_obj.weekday() < 5:  # Mon-Fri
            working_days.append(date_obj.strftime("%Y-%m-%d"))
    
    # Build status records for each user
    result = []
    for user in users:
        user_data = {
            "userId": user["id"],
            "userName": user["name"],
            "days": {}
        }
        
        # Initialize all working days as alpha
        for date in working_days:
            user_data["days"][date] = {
                "status": "alpha",
                "timestamp": None,
                "type": None
            }
        
        # Mark clock-in days as attend
        for record in attendance_data:
            if record.get("name") == user["name"]:
                timestamp = record.get("timestamp", "")
                if timestamp.startswith(month):
                    date = timestamp[:10]  # YYYY-MM-DD
                    if date in user_data["days"]:
                        user_data["days"][date]["status"] = "attend"
                        user_data["days"][date]["timestamp"] = timestamp
                        user_data["days"][date]["type"] = record.get("type")
        
        # Apply status overrides
        for override in status_overrides:
            if override["userId"] == user["id"]:
                date = override["date"]
                if date in user_data["days"]:
                    user_data["days"][date]["status"] = override["status"]
                    user_data["days"][date]["reason"] = override.get("reason", "")
        
        result.append(user_data)
    
    return {
        "success": True,
        "month": month,
        "workingDays": working_days,
        "records": result
    }


@app.get("/api/salary/{user_id}")
async def get_user_salary(user_id: str):
    """Get salary information for a user"""
    import json
    import os
    from datetime import datetime
    
    salaries_file = "salaries.json"
    users_file = "users.json"
    
    # Get user info
    if not os.path.exists(users_file):
        raise HTTPException(status_code=404, detail="Users file not found")
    
    with open(users_file, "r") as f:
        users = json.load(f)
    
    user = next((u for u in users if u["id"] == user_id), None)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if not os.path.exists(salaries_file):
        return {
            "success": True,
            "userId": user_id,
            "userName": user["name"],
            "salaries": [],
            "message": "No salary records found"
        }
    
    with open(salaries_file, "r") as f:
        salaries = json.load(f)
    
    # Filter salaries for this user
    user_salaries = [
        salary for salary in salaries 
        if salary.get("userId") == user_id
    ]
    
    return {
        "success": True,
        "userId": user_id,
        "userName": user["name"],
        "salaries": user_salaries
    }


@app.get("/api/salary/{user_id}/slip/{month}")
async def get_salary_slip(user_id: str, month: str):
    """Get salary slip for a specific user and month (format: YYYY-MM)"""
    import json
    import os
    
    salaries_file = "salaries.json"
    users_file = "users.json"
    
    # Get user info
    if not os.path.exists(users_file):
        raise HTTPException(status_code=404, detail="Users file not found")
    
    with open(users_file, "r") as f:
        users = json.load(f)
    
    user = next((u for u in users if u["id"] == user_id), None)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if not os.path.exists(salaries_file):
        raise HTTPException(status_code=404, detail="Salary records not found")
    
    with open(salaries_file, "r") as f:
        salaries = json.load(f)
    
    # Find salary for this user and month
    salary = next(
        (s for s in salaries if s.get("userId") == user_id and s.get("month") == month),
        None
    )
    
    if not salary:
        raise HTTPException(status_code=404, detail="Salary slip not found for this month")
    
    return {
        "success": True,
        "userId": user_id,
        "userName": user["name"],
        "month": month,
        "salary": salary
    }


@app.post("/api/auth/login")
async def login(phone: str, password: str):
    """Login endpoint for admin and portal"""
    import json
    import os
    
    users_file = "users.json"
    
    if not os.path.exists(users_file):
        raise HTTPException(status_code=404, detail="Users file not found")
    
    with open(users_file, "r") as f:
        users = json.load(f)
    
    # Find user by phone and password
    user = next(
        (u for u in users if u.get("phone") == phone and u.get("password") == password),
        None
    )
    
    if not user:
        raise HTTPException(status_code=401, detail="Invalid phone or password")
    
    # Return user data (excluding password)
    user_data = {k: v for k, v in user.items() if k != "password"}
    
    return {
        "success": True,
        "message": "Login successful",
        "user": user_data
    }


@app.post("/api/attendance/status/update")
async def update_attendance_status(userId: str, date: str, status: str, reason: str = ""):
    """Update attendance status for a specific user and date"""
    import json
    import os
    
    statuses_file = "attendance_statuses.json"
    
    # Validate status
    if status not in ["alpha", "permission", "sick"]:
        raise HTTPException(status_code=400, detail="Invalid status. Must be alpha, permission, or sick")
    
    # Load existing statuses
    if os.path.exists(statuses_file):
        with open(statuses_file, "r") as f:
            statuses = json.load(f)
    else:
        statuses = []
    
    # Remove existing status for this user/date
    statuses = [s for s in statuses if not (s["userId"] == userId and s["date"] == date)]
    
    # Add new status (only if not attend - attend is determined by clock-in)
    if status != "attend":
        statuses.append({
            "userId": userId,
            "date": date,
            "status": status,
            "reason": reason
        })
    
    # Save statuses
    with open(statuses_file, "w") as f:
        json.dump(statuses, f, indent=2)
    
    return {
        "success": True,
        "message": f"Status updated to {status} for user {userId} on {date}"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000, log_level="info")
