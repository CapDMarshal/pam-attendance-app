import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://kdfyjkkhmobkhlyyhnhl.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkZnlqa2tobW9ia2hseXlobmhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNjc4MDAsImV4cCI6MjA4Mjk0MzgwMH0.R3PH-esivBymG8NPBDKBKwZILIhBZc-pJvSCAmcxQUA'; // User needs to replace this

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}
