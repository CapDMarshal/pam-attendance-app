
import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
    try {
        const body = await request.json();
        console.log("DEBUG API: Received body:", body);
        const { userId, password } = body;

        if (!userId || !password) {
            console.error("DEBUG API: Missing userId or password. userId:", userId, "password:", !!password);
            return NextResponse.json(
                { success: false, message: 'Missing userId or password' },
                { status: 400 }
            );
        }

        const supabaseAdmin = createClient(
            process.env.NEXT_PUBLIC_SUPABASE_URL!,
            process.env.SUPABASE_SERVICE_ROLE_KEY!,
            {
                auth: {
                    autoRefreshToken: false,
                    persistSession: false,
                },
            }
        );

        // 1. Get user's email from 'karyawan' table using the provided ID (NIP)
        const { data: karyawanData, error: dbError } = await supabaseAdmin
            .from('karyawan')
            .select('email')
            .eq('nip', userId) // userId is NIP
            .single();

        if (dbError || !karyawanData || !karyawanData.email) {
            console.error('Database Error: Karyawan not found or no email', dbError);
            return NextResponse.json(
                { success: false, message: 'User not found in karyawan table' },
                { status: 404 }
            );
        }

        const userEmail = karyawanData.email;
        console.log(`DEBUG API: Found email ${userEmail} for ID ${userId}`);

        // 2. Find the Auth User UUID by email
        const { data: { users }, error: listError } = await supabaseAdmin.auth.admin.listUsers({
            page: 1,
            perPage: 1000
        });

        if (listError) {
            console.error('Auth List Error:', listError);
            return NextResponse.json({ success: false, message: 'Failed to list auth users' }, { status: 500 });
        }

        const authUser = users.find(u => u.email?.toLowerCase() === userEmail.toLowerCase());

        if (!authUser) {
            console.error(`DEBUG API: No Auth user found for email ${userEmail}`);
            return NextResponse.json(
                { success: false, message: `Auth user not found for email ${userEmail}` },
                { status: 404 }
            );
        }

        console.log(`DEBUG API: Found Auth UUID ${authUser.id} for email ${userEmail}`);

        // 3. Update the password using the resolving Auth UUID
        const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
            authUser.id,
            { password: password }
        );

        if (updateError) {
            console.error('Supabase Auth Update Error:', updateError);
            return NextResponse.json(
                { success: false, message: updateError.message },
                { status: 500 }
            );
        }

        return NextResponse.json({ success: true, message: 'Password updated successfully' });

    } catch (error) {
        console.error('API Error:', error);
        return NextResponse.json(
            { success: false, message: 'Internal Server Error' },
            { status: 500 }
        );
    }
}
