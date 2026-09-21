import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreeTerms = true;
  bool _receiveUpdates = true;

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty || !_agreeTerms) {
      _showMessage('Please enter email, password and agree to terms.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      // Wait a bit, then pop back. AuthGate will automatically redirect to HomePage
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      _showMessage(e.message ?? 'Signup failed. Please try again.');
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
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          children: [
            // Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.eco, color: Color(0xFF1B5E20), size: 32),
                SizedBox(width: 8),
                Text(
                  'ShareNest',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stepIndicator('1', 'Account', true),
                _stepLine(),
                _stepIndicator('2', 'Profile', false),
                _stepLine(),
                _stepIndicator('3', 'Interests', false),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Create your account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join a community that believes in sharing\nand supporting each other.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _firstNameController, hint: 'First name', icon: Icons.person_outline)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(controller: _lastNameController, hint: 'Last name', icon: Icons.person_outline)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(controller: _emailController, hint: 'Email address', icon: Icons.email_outlined),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              hint: 'Create a password',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Color(0xFF388E3C), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use at least 8 characters with a mix of letters, numbers and symbols.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Your area / neighbourhood', style: TextStyle(fontSize: 14, color: Colors.black54)),
                        SizedBox(height: 4),
                        Text('Helps us show relevant listings near you.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _checkbox(
                  _agreeTerms,
                  (v) => setState(() => _agreeTerms = v!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                      children: [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(text: 'Terms of Service', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                        TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _checkbox(
                  _receiveUpdates,
                  (v) => setState(() => _receiveUpdates = v!),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "I'd like to receive community updates and helpful tips (optional)",
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or sign up with', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _socialButton('Google', Icons.g_mobiledata, Colors.blue),
                _socialButton('Apple', Icons.apple, Colors.black),
                _socialButton('Phone', Icons.phone, Colors.black),
              ],
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  children: [
                    TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Log in',
                      style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _stepIndicator(String num, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1B5E20) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: active ? const Color(0xFF1B5E20) : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              num,
              style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFF1B5E20) : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _stepLine() {
    return Container(
      width: 40,
      height: 1,
      margin: const EdgeInsets.only(bottom: 14, left: 8, right: 8),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5E20)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _checkbox(bool value, Function(bool?) onChanged) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1B5E20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _socialButton(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
