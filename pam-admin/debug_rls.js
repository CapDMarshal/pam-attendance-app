
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

// Use ANON Key to simulate frontend access
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkVisibility() {
    console.log('Testing visibility with ANON key...');

    const bulan = 1;
    const tahun = 2026;

    const { data, error } = await supabase
        .from('slip_gaji')
        .select('*, slip_gaji_detail(*)')
        .eq('bulan', bulan)
        .eq('tahun', tahun)
        .limit(2);

    if (error) {
        console.error('Error fetching slip_gaji:', error);
    } else {
        console.log(`Fetched ${data.length} slips.`);
        if (data.length > 0) {
            console.log('Sample:', JSON.stringify(data[0], null, 2));
        }
    }
}

checkVisibility();
