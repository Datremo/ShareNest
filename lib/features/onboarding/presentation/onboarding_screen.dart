import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  double _currentPage = 0.0;
  
  // Animation controllers for micro-interactions on the active image
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Everyday Things.\nExtraordinary Impact.',
      'subtitle': 'Borrow what you need, lend what you can, and help your neighbours.',
      'image': 'assets/images/onboarding_objects.jpg',
    },
    {
      'title': 'Real People.\nReal Connections.',
      'subtitle': 'Meet neighbours, help each other and make everyday life easier.',
      'image': 'assets/images/onboarding_people.jpg',
    },
    {
      'title': 'A Cleaner, Greener\nTomorrow.',
      'subtitle': 'Share more. Buy less. Reduce waste together for a healthier planet.',
      'image': 'assets/images/onboarding_earth.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });

    _bounceController = AnimationController(vsync: this, duration: AppMotion.normal);
    _bounceAnimation = Tween<double>(begin: 0.0, end: -15.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic),
    );
  }
  
  void _triggerMicroInteraction() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F6),
      body: Stack(
        children: [
          // Parallax Content
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              // Calculate parallax offset for this page
              double offset = (_currentPage - index);
              
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Text Content (moves slower)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 40,
                    left: 24,
                    right: 24,
                    child: Transform.translate(
                      offset: Offset(offset * 200, 0), // Strong parallax for text
                      child: Opacity(
                        opacity: (1 - offset.abs().clamp(0.0, 1.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _pages[index]['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDark,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _pages[index]['subtitle']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryDark.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Image Content (moves faster)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.35,
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    child: GestureDetector(
                      onTap: _triggerMicroInteraction,
                      child: AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          // Only bounce the currently active image
                          final yOffset = (_currentPage.round() == index) ? _bounceAnimation.value : 0.0;
                          return Transform.translate(
                            offset: Offset(offset * -100, yOffset), // Reverse parallax for image
                            child: Opacity(
                              opacity: (1 - offset.abs().clamp(0.0, 1.0)),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 20,
                                      spreadRadius: -5,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Image.asset(
                                    _pages[index]['image']!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Bottom Navigation Area
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Indicators
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage.round() == index
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                
                // Next / Get Started Button
                AnimatedContainer(
                  duration: AppMotion.normal,
                  curve: AppMotion.emphasizeDecelerate,
                  width: _currentPage.round() == _pages.length - 1 ? 160 : 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      if (_currentPage.round() < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: AppMotion.normal,
                          curve: AppMotion.smooth,
                        );
                      } else {
                        // Morph transition to Auth Landing
                        context.go('/auth');
                      }
                    },
                    child: Center(
                      child: _currentPage.round() == _pages.length - 1
                          ? const Text(
                              'Get Started →',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
