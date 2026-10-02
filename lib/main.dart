import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'core/presentation/widgets/liquid_glass_widgets.dart';
import 'core/actions/quick_actions_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize notifications
  await NotificationService().initialize();
  
  // Initialize Quick Actions (App Icon Shortcuts)
  QuickActionsService.initialize();

  runApp(const ProviderScope(child: NeighborShareApp()));
}

class NeighborShareApp extends StatelessWidget {
  const NeighborShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NeighborShare',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(0.85),
          ),
          child: AnimatedLiquidBackground(
            child: child!,
          ),
        );
      },
    );
  }
}