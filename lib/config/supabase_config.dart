import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://hvymxpwvtdpbdfeuoszs.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2eW14cHd2dGRwYmRmZXVvc3pzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAwMDA5NzQsImV4cCI6MjA2NTU3Njk3NH0.ntoy5bT9anptitSqtIDIpQunRVA7lliXRmkilaISEaE';

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}

final supabase = Supabase.instance.client;
