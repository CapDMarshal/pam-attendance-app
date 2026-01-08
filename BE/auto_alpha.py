import os
from datetime import datetime, timedelta
from supabase import create_client, Client
from dotenv import load_dotenv

# Load env from .env file (make sure this file is in the same dir or use absolute path)
load_dotenv()

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Error: Missing SUPABASE_URL or SUPABASE_KEY")
    exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def main():
    # 1. Determine Target Date (Yesterday default, or run for today if running nightly)
    # Assumption: Cron runs at 00:01 AM for the previous day.
    yesterday_date = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
    print(f"🔄 Running Auto-Alpha for Date: {yesterday_date}")

    try:
        # 2. Get All active Karyawan NIPs
        # Note: In production, maybe filter by 'is_active' if you have that column
        users_res = supabase.table("karyawan").select("nip").execute()
        all_nips = {user['nip'] for user in users_res.data}
        print(f"👥 Total Employees: {len(all_nips)}")

        # 3. Get Attendance for that Date
        # Fetch status='in' or 'out' to see who attended
        attendance_res = supabase.table("kehadiran")\
            .select("nip")\
            .eq("tanggal", yesterday_date)\
            .execute()
        
        present_nips = {record['nip'] for record in attendance_res.data}
        print(f"✅ Present Employees: {len(present_nips)}")

        # 4. Identify Absent Users (Set difference)
        absent_nips = all_nips - present_nips
        print(f"❌ Absent Employees: {len(absent_nips)}")

        if not absent_nips:
            print("🎉 Everyone attended yesterday! No Alpha records needed.")
            # Do not return here, continue to Today's logic


        # 5. Bulk Insert Alpha Records
        insert_payload = []
        for nip in absent_nips:
            insert_payload.append({
                "nip": nip,
                "tanggal": yesterday_date,
                "waktu_clockin": f"{yesterday_date} 00:00:00", # Dummy time or null
                "status": "out", # Ensure they aren't marked as 'in'
                "status_presensi": "alpha"
            })

            res = supabase.table("kehadiran").upsert(
                insert_payload, 
                on_conflict="nip, tanggal" 
            ).execute()
            print(f"💾 [Yesterday] Successfully inserted/upserted {len(insert_payload)} Alpha records.")

        # --- NEW LOGIC: Initialize TODAY's records ---
        today_date = datetime.now().strftime('%Y-%m-%d')
        print(f"☀️ Initializing Attendance for Today: {today_date}")
        
        # Check who already has a record for today (in case script runs multiple times)
        today_res = supabase.table("kehadiran").select("nip").eq("tanggal", today_date).execute()
        today_present_nips = {record['nip'] for record in today_res.data}
        
        today_missing_nips = all_nips - today_present_nips
        print(f"🆕 Employees needing initialization: {len(today_missing_nips)}")

        if today_missing_nips:
            today_payload = []
            for nip in today_missing_nips:
                today_payload.append({
                    "nip": nip,
                    "tanggal": today_date,
                    # No waktu_clockin yet, they haven't clocked in
                    "status": "out", 
                    "status_presensi": "alpha" # Default to alpha until they clock in
                })
            
            res_today = supabase.table("kehadiran").upsert(
                today_payload,
                on_conflict="nip, tanggal"
            ).execute()
            print(f"� [Today] Successfully initialized {len(today_payload)} records.")


    except Exception as e:
        print(f"🚨 Error: {e}")

if __name__ == "__main__":
    main()
