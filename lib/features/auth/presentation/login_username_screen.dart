import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class LoginUsernameScreen extends StatefulWidget {
  const LoginUsernameScreen({super.key});

  @override
  State<LoginUsernameScreen> createState() => _LoginUsernameScreenState();
}

class _LoginUsernameScreenState extends State<LoginUsernameScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Please enter username and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch email associated with this username using RPC
      final emailResponse = await Supabase.instance.client
          .rpc('get_email_by_username', params: {'p_username': username});
          
      if (emailResponse == null) {
        _showMessage('Username not found.');
        setState(() => _isLoading = false);
        return;
      }

      final email = emailResponse.toString();

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Login failed. Please check your credentials.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F6),
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
            child: SingleChildScrollView(
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
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Hero(
                    tag: 'auth_title',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        'Login with Username',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
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
                        'Enter your username and password',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryDark.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Form Fields
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'yourusername',
                    label: 'Username',
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _passwordController,
                    hint: '••••••••',
                    label: 'Password',
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // context.push('/forgot_password');
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Or continue with
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: AppColors.primaryDark.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.2))),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Hero(
                    tag: 'auth_card_email',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.pushReplacement('/login'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined, color: AppColors.primaryDark),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Login with Email',
                                  style: TextStyle(
                                    fontSize: 14,
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
                  
                  const SizedBox(height: 40),
                  
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primaryDark.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
