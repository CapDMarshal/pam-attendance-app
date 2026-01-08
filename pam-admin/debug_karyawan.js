
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

async function checkKaryawan() {
    const { data, error } = await supabase.from('karyawan').select('*').limit(5);
    if (error) {
        console.error('Error fetching karyawan:', error);
    } else {
        console.log('Karyawan sample:', JSON.stringify(data, null, 2));
    }
}

checkKaryawan();
