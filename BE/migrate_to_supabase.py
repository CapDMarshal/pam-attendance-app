import os
import json
import logging
from pathlib import Path
from supabase import create_client, Client
from dotenv import load_dotenv
from tqdm import tqdm
import mimetypes

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

# Load env
load_dotenv()

# Config
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
BUCKET_NAME = "karyawan-photos"

if not SUPABASE_URL or not SUPABASE_KEY:
    logger.error("❌ Missing SUPABASE_URL or SUPABASE_KEY in .env file")
    exit(1)

# Initialize Supabase
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def generate_password(nip, name):
    """
    Generate password: Last 3 digits of NIP + First Name.
    Example: 5221911012 + Debora -> 012Debora
    """
    if not nip or len(nip) < 3:
        suffix = "000"
    else:
        suffix = nip[-3:]
    
    first_name = name.split()[0]
    return f"{suffix}{first_name}"

def main():
    BASE_DIR = Path(__file__).parent
    USERS_FILE = BASE_DIR / "users.json"
    DATASET_DIR = BASE_DIR / "datasets" / "new_dataset"
    
    if not USERS_FILE.exists():
        logger.error(f"❌ Users file not found: {USERS_FILE}")
        return

    # Load users
    with open(USERS_FILE, 'r') as f:
        users = json.load(f)
    
    logger.info(f"Loaded {len(users)} users from JSON.")
    
    success_count = 0
    fail_count = 0
    
    for user in tqdm(users, desc="Migrating Users"):
        try:
            # 1. Prepare User Data
            nip = user.get("phone") # Phone maps to NIP
            name = user.get("name")
            
            if not nip or not name:
                logger.warning(f"⚠️ Skipping user with missing NIP/Name: {user}")
                fail_count += 1
                continue
                
            # Generate Password
            password = generate_password(nip, name)
            
            # 2. Find and Upload Photo
            # The JSON has 'faceImage' path like "datasets/new_dataset/..."
            # We need to resolve it relative to BE folder
            relative_path = user.get("faceImage", "")
            # Fix path format if needed (windows vs unix)
            relative_path = relative_path.replace("\\", "/")
            
            # Since relative_path already includes "datasets/new_dataset", we construct full path
            # But wait, looking at user's structure, the JSON says "datasets/new_dataset/..."
            # So we should be able to find it in BASE_DIR / relative_path
            
            # Clean up path to just filename if it's messy, OR construct from ID if file missing
            # Let's try to trust the JSON path first
            
            # Wait, the JSON path is relative to BE root usually. 
            # Let's clean it.
            if relative_path.startswith("datasets/new_dataset/"):
                 filename = relative_path.split("/")[-1]
                 local_photo_path = DATASET_DIR / filename
            else:
                 # Fallback logic if path is weird
                 local_photo_path = BASE_DIR / relative_path

            public_url = None
            
            if local_photo_path.exists():
                # Upload to Storage
                file_ext = local_photo_path.suffix
                storage_path = f"public/{nip}_{name.replace(' ', '_')}{file_ext}"
                
                with open(local_photo_path, 'rb') as f:
                    file_content = f.read()
                
                content_type = mimetypes.guess_type(local_photo_path)[0] or "image/jpeg"
                
                # Upload
                res = supabase.storage.from_(BUCKET_NAME).upload(
                    path=storage_path,
                    file=file_content,
                    file_options={"content-type": content_type, "upsert": "true"}
                )
                
                # Get Public URL
                # Manually construct because get_public_url method varies by version
                # Correct pattern: https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>
                public_url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET_NAME}/{storage_path}"
                
            else:
                logger.warning(f"⚠️ Photo not found for {name}: {local_photo_path}")
            
            # 3. Create Supabase Auth User
            email = f"{nip}@pam.com"  # Generate dummy email for Auth
            
            try:
                # Check if user exists (by email) - this part is tricky in batch, 
                # but create_user will fail if exists.
                # We use admin.create_user to set specific password and Confirm email automatically
                auth_response = supabase.auth.admin.create_user({
                    "email": email,
                    "password": password,
                    "email_confirm": True,
                    "user_metadata": {
                        "nip": nip,
                        "full_name": name
                    }
                })
                # auth_user_id = auth_response.user.id
                logger.info(f"✅ Created Auth User: {nip}")
                
            except Exception as auth_error:
                # If user already exists, we might get an error.
                # We'll log it but continue to update the profile (photo/name)
                logger.warning(f"⚠️ Auth User creation skipped/failed for {nip} (might exist): {auth_error}")

            # 4. Insert into 'karyawan' Table (Profile)
            data = {
                "nip": nip,
                "nama_lengkap": name,
                "foto_wajah": public_url,
                "email": email
            }
            
            # Upsert (using NIP as conflict key)
            supabase.table("karyawan").upsert(data).execute()
            
            success_count += 1
            
        except Exception as e:
            logger.error(f"❌ Error migrating {user.get('name')}: {e}")
            fail_count += 1
            
    logger.info("="*50)
    logger.info("MIGRATION COMPLETED")
    logger.info(f"✅ Success: {success_count}")
    logger.info(f"❌ Failed: {fail_count}")
    logger.info("="*50)

if __name__ == "__main__":
    main()
