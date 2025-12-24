// API Configuration
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://hypocycloidal-intensely-raven.ngrok-free.dev';

export interface User {
    id: string;
    name: string;
    phone: string;
    password?: string;
    faceImage: string;
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
}

// Helper function for API requests
async function apiRequest<T>(
    endpoint: string,
    options: RequestInit = {}
): Promise<T> {
    const url = `${API_BASE_URL}${endpoint}`;

    const response = await fetch(url, {
        ...options,
        headers: {
            'Content-Type': 'application/json',
            ...options.headers,
        },
    });

    if (!response.ok) {
        const error = await response.json().catch(() => ({ detail: 'Request failed' }));
        throw new Error(error.detail || `HTTP error! status: ${response.status}`);
    }

    return response.json();
}

// User Management
export async function getUsers(): Promise<{ success: boolean; users: User[]; count: number }> {
    return apiRequest('/api/users');
}

export async function getUser(userId: string): Promise<{ success: boolean; user: User }> {
    return apiRequest(`/api/users/${userId}`);
}

export async function createUser(data: {
    name: string;
    phone: string;
    password: string;
    faceImage?: string;
}): Promise<{ success: boolean; message: string; user: User }> {
    const params = new URLSearchParams({
        name: data.name,
        phone: data.phone,
        password: data.password,
        ...(data.faceImage && { faceImage: data.faceImage }),
    });

    return apiRequest(`/api/users?${params}`, {
        method: 'POST',
    });
}

export async function updateUser(
    userId: string,
    data: {
        name?: string;
        phone?: string;
        password?: string;
        faceImage?: string;
    }
): Promise<{ success: boolean; message: string; user: User }> {
    const params = new URLSearchParams();
    if (data.name) params.append('name', data.name);
    if (data.phone) params.append('phone', data.phone);
    if (data.password) params.append('password', data.password);
    if (data.faceImage) params.append('faceImage', data.faceImage);

    return apiRequest(`/api/users/${userId}?${params}`, {
        method: 'PUT',
    });
}

// Attendance
export async function getAllAttendance(): Promise<{ success: boolean; records: Absention[]; total_records: number }> {
    return apiRequest('/api/attendance/all');
}

export async function getUserAttendance(userId: string): Promise<{
    success: boolean;
    userId: string;
    userName: string;
    records: Absention[];
    total_records: number;
}> {
    return apiRequest(`/api/attendance/user/${userId}`);
}

export async function getUserAttendanceByMonth(
    userId: string,
    month: string
): Promise<{
    success: boolean;
    userId: string;
    userName: string;
    month: string;
    records: Absention[];
    total_records: number;
}> {
    return apiRequest(`/api/attendance/user/${userId}/month/${month}`);
}

// Authentication
export async function login(phone: string, password: string): Promise<{
    success: boolean;
    message: string;
    user: User;
}> {
    const params = new URLSearchParams({
        phone,
        password,
    });

    return apiRequest(`/api/auth/login?${params}`, {
        method: 'POST',
    });
}

// Attendance Status Management
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
        }>;
    }>;
}> {
    return apiRequest(`/api/attendance/status/month/${month}`);
}

export async function updateAttendanceStatus(
    userId: string,
    date: string,
    status: 'alpha' | 'permission' | 'sick' | 'attend',
    reason?: string
): Promise<{ success: boolean; message: string }> {
    const params = new URLSearchParams({
        userId,
        date,
        status,
        ...(reason && { reason }),
    });

    return apiRequest(`/api/attendance/status/update?${params}`, {
        method: 'POST',
    });
}
