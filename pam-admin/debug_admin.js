
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

async function checkAdmin() {
    const { data, error } = await supabase.from('admin').select('*');
    if (error) {
        console.error('Error fetching admin:', error);
    } else {
        console.log('Admin table data:', data);
    }
}

checkAdmin();
