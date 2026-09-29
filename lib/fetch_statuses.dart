import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neighbor_share/core/data/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  try {
    final response = await Supabase.instance.client
        .rpc('get_enum_values', params: {'enum_type': 'listing_status'});
    print("Enum values: \$response");
  } catch (e) {
    print("RPC failed: \$e");
    // Fallback: get distinct statuses
    try {
      final res = await Supabase.instance.client
          .from('listings')
          .select('status');
      final statuses = res.map((e) => e['status']).toSet().toList();
      print("Distinct statuses used: \$statuses");
    } catch(err) {
      print("Select failed: \$err");
    }
  }
}
