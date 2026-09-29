import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neighbor_share/core/data/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  final testStatuses = ['DRAFT', 'INACTIVE', 'RESERVED', 'AVAILABLE', 'UNAVAILABLE', 'PAUSED', 'PENDING', 'DELETED'];
  
  for (var status in testStatuses) {
    try {
      final res = await Supabase.instance.client.from('listings').insert({
        'owner_id': Supabase.instance.client.auth.currentUser?.id ?? '29d2b5c8-c01f-4b82-8ada-350388d7fe2e',
        'title': 'Test Constraint',
        'mode': 'LEND',
        'category_id': 'urgent_category',
        'status': status
      }).select('id').single();
      
      print("SUCCESS: \$status is valid!");
      await Supabase.instance.client.from('listings').delete().eq('id', res['id']);
    } catch (e) {
      print("FAILED: \$status -> \$e");
    }
  }
}
