import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  await dotenv.load(fileName: ".env");
  final client = SupabaseClient(dotenv.env['SUPABASE_URL']!, dotenv.env['SUPABASE_ANON_KEY']!);

  try {
    final data = await client.from('urgent_requests').select('*, profiles!requester_id(*)');
    print(data);
    print("Success profiles!requester_id");
  } catch (e) {
    print("Error with profiles!requester_id: $e");
    try {
      final data2 = await client.from('urgent_requests').select('*, profiles(*)');
      print(data2);
      print("Success profiles(*)");
    } catch (e2) {
      print("Error with profiles(*): $e2");
    }
  }
}
