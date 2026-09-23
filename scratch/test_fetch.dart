import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:demo/core/data/repositories/listing_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: '...', // We don't have the URL here? Wait, we can just run it in the app's context.
  );
}
