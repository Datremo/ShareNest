import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'auth_landing_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        if (mounted) {
          context.go('/home');
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          context.go('/auth');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If user is already signed in on initial load
    if (Supabase.instance.client.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
        ),
      );
    }

    return const AuthLandingScreen();
  }
}
