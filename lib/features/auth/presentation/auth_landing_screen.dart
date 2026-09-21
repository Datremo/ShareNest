import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F6), // Soft off-white clay color
      body: Stack(
        children: [
          // Decorative leaves at top right
          Positioned(
            top: -50,
            right: -50,
            child: Hero(
              tag: 'auth_leaves_top',
              child: Image.asset(
                'assets/images/leaves_top.png', 
                width: 250, 
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Back button
                  Hero(
                    tag: 'auth_back_button',
                    child: Material(
                      type: MaterialType.transparency,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
                        onPressed: () {}, // Splash or previous
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Titles
                  Hero(
                    tag: 'auth_title',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        'Welcome to\nShareNest',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Hero(
                    tag: 'auth_subtitle',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryDark.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Continue with Email Card
                  Hero(
                    tag: 'auth_card_email',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/login'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined, color: AppColors.primaryDark),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Continue with Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: AppColors.primaryDark.withValues(alpha: 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Continue with Username Card
                  Hero(
                    tag: 'auth_card_username',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/login_username'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, color: AppColors.primaryDark),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Continue with Username',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: AppColors.primaryDark.withValues(alpha: 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Sign up
                  Center(
                    child: Hero(
                      tag: 'auth_signup_text',
                      child: Material(
                        type: MaterialType.transparency,
                        child: GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: AppColors.primaryDark.withValues(alpha: 0.6), 
                                  fontSize: 14,
                                ),
                                children: [
                                  const TextSpan(text: 'Don\'t have an account? '),
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Decorative leaves at bottom left
          Positioned(
            bottom: -50,
            left: -50,
            child: Hero(
              tag: 'auth_leaves_bottom',
              child: Image.asset(
                'assets/images/leaves_bottom.png', 
                width: 250,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
