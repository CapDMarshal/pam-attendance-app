import { supabase } from './supabase';

export interface User {
    id: string; // Supabase UUID
    name: string; // nama_lengkap
    phone: string; // nip
    password?: string;
    faceImage?: string; // foto_wajah
    todayAbsention?: 'alpha' | 'attend' | 'permission' | 'sick';
}

export interface Absention {
    id?: string;
    userId?: string;
    name?: string;
    datetime?: string;
    timestamp?: string;
    type?: string;
    absention?: string;
    confidence?: number;
    tanggal?: string;
}

// ================= USER MANAGEMENT =================
import bcrypt from 'bcryptjs';

export async function verifyAdmin(username: string, password: string): Promise<{ success: boolean; message?: string }> {
    const { data, error } = await supabase
        .from('admin')
        .select('*')
        .eq('username', username)
        .single();

    if (error || !data) {
        return { success: false, message: 'Invalid username' };
    }

    const isValid = await bcrypt.compare(password, data.password_hash);
    if (!isValid) {
        return { success: false, message: 'Invalid password' };
    }

    return { success: true };
}

export async function getUsers(): Promise<{ success: boolean; users: User[]; count: number }> {
    const { data, error } = await supabase
        .from('karyawan')
        .select('*');

    if (error) throw error;

    const today = new Date().toISOString().split('T')[0];
    const { data: attendanceData } = await supabase
        .from('kehadiran')
        .select('nip, status_presensi')
        .eq('tanggal', today);

    const attendanceMap = new Map(attendanceData?.map((a: any) => [a.nip, a.status_presensi]) || []);

    const users = data.map((item: any) => ({
        id: item.id || item.nip, // Use NIP if ID is missing (PK is likely NIP)
        name: item.nama_lengkap,
        phone: item.nip,
        faceImage: item.foto_wajah,
        todayAbsention: (attendanceMap.get(item.nip) as any) || 'alpha'
    }));

    return { success: true, users, count: users.length };
}

export async function getUser(userId: string): Promise<{ success: boolean; user: User }> {
    const { data, error } = await supabase.from('karyawan').select('*').eq('id', userId).single();
    if (error) throw error;

    return {
        success: true,
        user: {
            id: data.id || data.nip,
            name: data.nama_lengkap,
            phone: data.nip,
            faceImage: data.foto_wajah
        }
    };
}

export async function createUser(data: {
    name: string;
    phone: string; // NIP
    password: string;
    faceImage?: string;
}): Promise<{ success: boolean; message: string }> {
    const { error } = await supabase.from('karyawan').insert({
        nama_lengkap: data.name,
        nip: data.phone,
        foto_wajah: data.faceImage,
    });
    if (error) throw error;
    return { success: true, message: "User created" };
}

export async function updateUser(
    userId: string,
    data: {
        name?: string;
        phone?: string;
        password?: string;
        faceImage?: string;
    }
): Promise<{ success: boolean; message: string }> {
    const updates: any = {};
    if (data.name) updates.nama_lengkap = data.name;
    if (data.phone) updates.nip = data.phone;
    if (data.faceImage) updates.foto_wajah = data.faceImage;

    // 1. Update Password via API (Server-side) if provided
    if (data.password) {
        const response = await fetch('/api/admin/update-password', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId, password: data.password }),
        });

        const result = await response.json();
        if (!result.success) {
            throw new Error(result.message || 'Failed to update password');
        }
    }

    // 2. Update Profile in Karyawan table
    if (Object.keys(updates).length > 0) {
        const { error } = await supabase.from('karyawan').update(updates).eq('id', userId);
        if (error) throw error;
    }

    return { success: true, message: "User updated" };
}

// ================= ATTENDANCE =================

// ... (previous code)

export async function getAllAttendance(): Promise<{ success: boolean; records: Absention[]; total_records: number }> {
    const { data, error } = await supabase
        .from('kehadiran')
        .select('*, karyawan(nama_lengkap)')
        .order('tanggal', { ascending: false }) // Order by Date first
        .order('waktu_clockin', { ascending: false });

    if (error) throw error;

    const records = data.map((item: any) => ({
        id: item.id?.toString(),
        userId: item.nip,
        name: item.karyawan?.nama_lengkap || item.nip,
        datetime: item.waktu_clockin || `${item.tanggal}T00:00:00`, // Fallback for sorting if null
        timestamp: item.waktu_clockin,
        absention: item.status_presensi, // Critical: this is the real status
        tanggal: item.tanggal,
        type: item.status // 'in' or 'out'
    }));

    return { success: true, records, total_records: records.length };
}

export async function getUserAttendance(userId: string): Promise<{
    success: boolean;
    userId: string;
    userName: string;
    records: Absention[];
    total_records: number;
}> {
    // userId passed from URL is UUID (from Users list). We need NIP.
    const { data: userData } = await supabase.from('karyawan').select('nip, nama_lengkap').eq('id', userId).single();
    if (!userData) throw new Error("User not found: " + userId);

    // Fetch records by NIP
    const { data, error } = await supabase
        .from('kehadiran')
        .select('*')
        .eq('nip', userData.nip)
        .order('tanggal', { ascending: false }); // Sort by Date desc

    if (error) throw error;

    const records = data.map((item: any) => ({
        id: item.id?.toString(),
        userId: item.nip,
        name: userData.nama_lengkap,
        datetime: item.waktu_clockin || `${item.tanggal}T00:00:00`,
        timestamp: item.waktu_clockin,
        type: item.status, // in/out
        absention: item.status_presensi,
        confidence: 1.0,
        tanggal: item.tanggal
    }));

    return {
        success: true,
        userId: userId,
        userName: userData.nama_lengkap,
        records,
        total_records: records.length
    };
}

export async function updateAttendanceStatus(
    userId: string, // This is the NIP passed from frontend
    date: string,
    status: 'alpha' | 'permission' | 'sick' | 'attend',
    reason?: string
): Promise<{ success: boolean; message: string }> {
    // userId is actually the NIP now.
    const nip = userId;

    // Map admin status to DB status
    let dbStatus = status as string;
    if (status === 'attend') dbStatus = 'hadir';
    else if (status === 'permission') dbStatus = 'izin';
    else if (status === 'sick') dbStatus = 'sakit';

    const { error } = await supabase.from('kehadiran').upsert({
        nip: nip,
        tanggal: date,
        status_presensi: dbStatus,
        status: status === 'attend' ? 'in' : 'out',
    }, { onConflict: 'nip, tanggal' });

    if (error) throw error;
    return { success: true, message: "Status updated" };
}

export async function getAttendanceWithStatus(month: string): Promise<{
    success: boolean;
    month: string;
    workingDays: string[];
    records: Array<{
        userId: string;
        userName: string;
        days: Record<string, {
            status: 'attend' | 'alpha' | 'permission' | 'sick';
            timestamp?: string;
            type?: string;
            reason?: string;
            clockIn?: string;
            clockOut?: string;
            statusKehadiran?: string;
        }>;
    }>;
}> {
    // 1. Get all employees. Select ONLY fields that exist (nip, nama_lengkap). 
    // ID DOES NOT EXIST in karyawan table.
    const { data: users, error: userError } = await supabase.from('karyawan').select('nip, nama_lengkap');
    if (userError) throw userError;

    // 2. Determine date range for the month
    const [yearStr, monthStr] = month.split('-');
    const year = parseInt(yearStr);
    const monthInt = parseInt(monthStr);

    const startDate = `${year}-${monthStr.padStart(2, '0')}-01`;
    const lastDay = new Date(year, monthInt, 0).getDate();
    const endDate = `${year}-${monthStr.padStart(2, '0')}-${lastDay.toString().padStart(2, '0')}`;

    // 3. Generate array of working days
    const workingDays: string[] = [];
    for (let d = 1; d <= lastDay; d++) {
        workingDays.push(`${year}-${monthStr.padStart(2, '0')}-${d.toString().padStart(2, '0')}`);
    }

    // 4. Fetch attendance records for this range
    const { data: attendanceData, error: attendanceError } = await supabase
        .from('kehadiran')
        .select('*')
        .gte('tanggal', startDate)
        .lte('tanggal', endDate);

    if (attendanceError) throw attendanceError;

    // 5. Build the matrix
    const attendanceMap = new Map<string, Map<string, any>>();

    attendanceData.forEach((record: any) => {
        if (!attendanceMap.has(record.nip)) {
            attendanceMap.set(record.nip, new Map());
        }
        attendanceMap.get(record.nip)!.set(record.tanggal, record);
    });

    const records = users.map((user: any) => {
        const days: Record<string, any> = {};
        const userAttendance = attendanceMap.get(user.nip) || new Map();

        workingDays.forEach((date: string) => {
            const record = userAttendance.get(date);
            let status = 'alpha';
            let timestamp = undefined;

            if (record) {
                const dbStatus = record.status_presensi?.toLowerCase() || 'alpha';
                if (dbStatus === 'hadir') status = 'attend';
                else if (dbStatus === 'sakit') status = 'sick';
                else if (dbStatus === 'izin') status = 'permission';
                else status = 'alpha';

                timestamp = record.waktu_clockin;
            } else {
                if (new Date(date) > new Date()) {
                    status = 'alpha';
                }
            }

            days[date] = {
                status: status as any,
                timestamp: timestamp,
                clockIn: record?.waktu_clockin,
                clockOut: record?.waktu_clockout,
                statusKehadiran: record?.status // in or out
            };
        });

        return {
            userId: user.nip, // Use NIP as the ID
            userName: user.nama_lengkap,
            days: days
        };
    });

    return {
        success: true,
        month: month,
        workingDays: workingDays,
        records: records
    };
}

export async function getAllSlipGaji(month: number, year: number): Promise<{
    success: boolean;
    data: Array<{
        userId: string;
        userName: string;
        month: number;
        year: number;
        status: string;
        basicSalary: number;
        allowance: number;
        deductions: number;
        totalSalary: number;
        details: any[];
    }>;
}> {
    const { data: slips, error: slipError } = await supabase
        .from('slip_gaji')
        .select(`
            id,
            nip,
            bulan,
            tahun,
            status,
            karyawan (
                nama_lengkap
            ),
            slip_gaji_detail (
                kategori,
                nama_komponen,
                jumlah
            )
        `)
        .eq('bulan', month)
        .eq('tahun', year);

    if (slipError) throw slipError;

    const formattedSlips = slips.map((item: any) => {
        let basicSalary = 0;
        let allowance = 0;
        let deductions = 0;

        if (item.slip_gaji_detail) {
            item.slip_gaji_detail.forEach((detail: any) => {
                const amount = Number(detail.jumlah) || 0;

                if (detail.kategori === 'penerimaan') {
                    if (detail.nama_komponen === 'Gaji Pokok') {
                        basicSalary += amount;
                    } else {
                        allowance += amount;
                    }
                } else if (detail.kategori === 'potongan') {
                    deductions += amount;
                }
            });
        }

        const totalSalary = (basicSalary + allowance) - deductions;

        return {
            userId: item.nip,
            userName: item.karyawan?.nama_lengkap || item.nip,
            month: item.bulan,
            year: item.tahun,
            status: item.status,
            basicSalary,
            allowance,
            deductions,
            totalSalary,
            details: item.slip_gaji_detail || [] // Pass raw details
        };
    });

    return { success: true, data: formattedSlips };
}
