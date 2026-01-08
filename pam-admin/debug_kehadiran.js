
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

async function checkKehadiran() {
    const { data, error } = await supabase.from('kehadiran').select('*').limit(5);
    if (error) {
        console.error('Error fetching kehadiran:', error);
    } else {
        console.log('Kehadiran sample:', JSON.stringify(data, null, 2));
    }
}

checkKehadiran();
