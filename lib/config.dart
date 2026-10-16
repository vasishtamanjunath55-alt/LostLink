import 'package:supabase_flutter/supabase_flutter.dart';

/// 1. Create a free project at https://supabase.com
/// 2. Project Settings -> API: copy "Project URL" and the "anon public" key here.
/// (The anon key is safe to put in an app; the database rules in
/// supabase_setup.sql are what protect your data.)
class AppConfig {
  static const supabaseUrl = 'https://woobxsdrtbbiqxefnyvl.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_Meks76UFtuyAmsznOhLa_A_rI4sCO2s';
  
  /// Set to your college email domain (e.g. 'college.edu.in') to only allow
  /// campus emails to sign up. Leave empty to allow any email.
  static const allowedEmailDomain = '';

  static const categories = [
    'ID Card',
    'Phone',
    'Wallet',
    'Keys',
    'Books',
    'Bag',
    'Laptop / Charger',
    'Clothing',
    'Other',
  ];
}

SupabaseClient get supabase => Supabase.instance.client;
