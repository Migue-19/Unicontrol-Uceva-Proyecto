import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://hncwcwbybkxqtmbgheqd.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhuY3djd2J5Ymt4cXRtYmdoZXFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzYyMjEsImV4cCI6MjA5MDA1MjIyMX0.o_zpO1Us5jGgBikwpfgNfvDmGwiKrOAssIJdfPA9-Ag';
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com',
  );

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
}