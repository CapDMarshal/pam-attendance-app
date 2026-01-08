
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

async function testAttendanceLogic() {
    console.log('Starting test...');
    const month = '2026-01'; // Use current month

    try {
        // 1. Get users
        const { data: users, error: userError } = await supabase.from('karyawan').select('id, nip, nama_lengkap');
        if (userError) throw userError;
        console.log(`Fetched ${users.length} users.`);

        // 2. Date ranges
        const [yearStr, monthStr] = month.split('-');
        const year = parseInt(yearStr);
        const monthInt = parseInt(monthStr);
        const startDate = `${year}-${monthStr.padStart(2, '0')}-01`;
        const lastDay = new Date(year, monthInt, 0).getDate();
        const endDate = `${year}-${monthStr.padStart(2, '0')}-${lastDay.toString().padStart(2, '0')}`;

        console.log(`Range: ${startDate} to ${endDate}`);

        // 3. Fetch attendance
        const { data: attendanceData, error: attendanceError } = await supabase
            .from('kehadiran')
            .select('*')
            .gte('tanggal', startDate)
            .lte('tanggal', endDate);

        if (attendanceError) throw attendanceError;
        console.log(`Fetched ${attendanceData.length} attendance records.`);

        // 4. Build map
        const attendanceMap = new Map();
        attendanceData.forEach(record => {
            if (!attendanceMap.has(record.nip)) {
                attendanceMap.set(record.nip, new Map());
            }
            attendanceMap.get(record.nip).set(record.tanggal, record);
        });

        console.log('Map built successfully.');

    } catch (error) {
        console.error('Logic failed:', error);
    }
}

testAttendanceLogic();
