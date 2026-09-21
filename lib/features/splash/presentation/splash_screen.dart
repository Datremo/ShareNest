import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _leafController;
  late final AnimationController _textController;

  late final Animation<double> _bgOpacity;
  late final Animation<double> _bgScale;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _leafRotation;
  late final Animation<double> _leafScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textOffset;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(vsync: this, duration: AppMotion.splash);
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _leafController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _textController = AnimationController(vsync: this, duration: AppMotion.slow);

    _bgOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeIn),
    );
    _bgScale = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: AppMotion.emphasizeDecelerate),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _leafScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _leafController, curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)),
    );
    
    // Natural sway
    _leafRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2).chain(CurveTween(curve: Curves.easeInOutSine)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.1).chain(CurveTween(curve: Curves.easeInOutSine)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.05).chain(CurveTween(curve: Curves.easeInOutSine)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0).chain(CurveTween(curve: Curves.easeInOutSine)), weight: 40),
    ]).animate(_leafController);

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textOffset = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: AppMotion.smooth),
    );

    _playChoreography();
  }

  Future<void> _playChoreography() async {
    // 1. Background appears softly
    _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 2. Logo emerges
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 3 & 4. Leaf unfolds and sways
    _leafController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    
    // 6. Tagline fades upward
    _textController.forward();
    
    // Wait for reading time
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      // Check auth state
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _leafController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Parallax
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Opacity(
                opacity: _bgOpacity.value,
                child: Transform.scale(
                  scale: _bgScale.value,
                  child: Image.asset(
                    'assets/images/splash_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          
          // Gradient Overlay to ensure text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.8),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          
          // Foreground Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_logoController, _leafController]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base House icon
                          Icon(
                            Icons.home_outlined, 
                            size: 100, 
                            color: AppColors.primaryDark,
                          ),
                          // Inner object
                          Positioned(
                            bottom: 12,
                            child: Icon(
                              Icons.eco, 
                              size: 40, 
                              color: AppColors.primary,
                            ),
                          ),
                          // The Unfolding Leaf
                          Positioned(
                            top: -5,
                            right: -10,
                            child: Transform.rotate(
                              angle: _leafRotation.value,
                              alignment: Alignment.bottomLeft,
                              child: Transform.scale(
                                scale: _leafScale.value,
                                child: Icon(
                                  Icons.energy_savings_leaf,
                                  size: 45,
                                  color: const Color(0xFF388E3C), // Fresh green
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: SlideTransition(
                      position: _textOffset,
                      child: Column(
                        children: [
                          const Text(
                            'ShareNest',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Borrow • Lend • Belong',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark.withValues(alpha: 0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
