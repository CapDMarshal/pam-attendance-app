
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

// Use Service Role Key to bypass RLS for seeding
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('Missing Supabase URL or Key in .env.local');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function seedSlipGaji() {
    console.log('Fetching employees...');
    // 1. Get all employees
    const { data: employees, error: empError } = await supabase
        .from('karyawan')
        .select('nip, nama_lengkap');

    if (empError) {
        console.error('Error fetching employees:', empError);
        return;
    }

    console.log(`Found ${employees.length} employees.`);

    // 2. Prepare Slip Gaji data for January 2026
    const bulan = 1; // January
    const tahun = 2026;

    console.log(`Checking/Seeding Slip Gaji for ${bulan}/${tahun}...`);

    for (const emp of employees) {
        // A. Check if slip exists for this employee/month/year
        let { data: slip, error: slipError } = await supabase
            .from('slip_gaji')
            .select('id')
            .eq('nip', emp.nip)
            .eq('bulan', bulan)
            .eq('tahun', tahun)
            .single();

        if (slipError && slipError.code !== 'PGRST116') { // PGRST116 is 'Row not found'
            console.error(`Error fetching slip for ${emp.nip}:`, slipError);
            continue;
        }

        // B. If not exists, create it
        if (!slip) {
            const { data: newSlip, error: createError } = await supabase
                .from('slip_gaji')
                .insert({
                    nip: emp.nip,
                    bulan: bulan,
                    tahun: tahun,
                    status: 'belum'
                })
                .select('id')
                .single();

            if (createError) {
                console.error(`Error creating slip for ${emp.nip}:`, createError);
                continue;
            }
            slip = newSlip;
            console.log(`Created slip for ${emp.nip}`);
        }

        // C. Check/Insert Details for this slip
        const { data: existingDetails } = await supabase
            .from('slip_gaji_detail')
            .select('id')
            .eq('slip_gaji_id', slip.id);

        if (existingDetails && existingDetails.length > 0) {
            continue; // Details already exist
        }

        // D. Insert Details
        // Randomize slightly for variety
        const salaryBase = 5000000 + (Math.floor(Math.random() * 5) * 500000);
        const transport = 500000;
        const bpjs = 100000;

        const details = [
            {
                slip_gaji_id: slip.id,
                kategori: 'penerimaan',
                nama_komponen: 'Gaji Pokok',
                jumlah: salaryBase
            },
            {
                slip_gaji_id: slip.id,
                kategori: 'penerimaan',
                nama_komponen: 'Tunjangan Transport',
                jumlah: transport
            },
            {
                slip_gaji_id: slip.id,
                kategori: 'potongan',
                nama_komponen: 'BPJS Kesehatan',
                jumlah: bpjs
            }
        ];

        const { error: insertError } = await supabase
            .from('slip_gaji_detail')
            .insert(details);

        if (insertError) {
            console.error(`Error inserting details for slip ${slip.id}:`, insertError);
        } else {
            console.log(`Inserted details for ${emp.nama_lengkap} (Slip ID: ${slip.id})`);
        }
    }
    console.log('Seeding complete.');
}

seedSlipGaji();
