import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/location/location_autocomplete_field.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _locationController = TextEditingController();
  final _interestsController = TextEditingController();

  LocationSuggestion? _selectedLocation;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreeTerms = true;
  bool _receiveUpdates = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty) {
        _showMessage('Please fill all fields in this step.');
        return;
      }
    } else if (_currentStep == 1) {
      if (_usernameController.text.trim().isEmpty ||
          (_selectedLocation == null && _locationController.text.trim().isEmpty)) {
        _showMessage('Please provide a username and location.');
        return;
      }
    }

    if (_currentStep < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _signup();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _signup() async {
    if (!_agreeTerms) {
      _showMessage('Please agree to the terms to continue.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'username': _usernameController.text.trim(),
        },
      );
      
      final userId = res.user?.id;
      if (userId != null) {
          final interestsList = _interestsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          final locName = _selectedLocation?.displayName ?? _locationController.text.trim();

          // Update because the auth trigger creates the row
          await Supabase.instance.client.from('profiles').update({
             'full_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
             'display_name': _firstNameController.text.trim(),
             'username': _usernameController.text.trim(),
             'location_name': locName,
             'lat': _selectedLocation?.lat,
             'lon': _selectedLocation?.lon,
             if (interestsList.isNotEmpty) 'interests': interestsList,
          }).eq('id', userId);
      }

      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      _showMessage(e.message ?? 'Signup failed. Please try again.');
    } catch (e) {
      _showMessage('An error occurred during signup.');
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
          onPressed: _prevStep,
        ),
      ),
      body: Column(
        children: [
          // Header & Stepper
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.eco, color: Color(0xFF1B5E20), size: 32),
                    SizedBox(width: 8),
                    Text(
                      'ShareNest',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepIndicator('1', 'Account', _currentStep >= 0),
                    _stepLine(),
                    _stepIndicator('2', 'Profile', _currentStep >= 1),
                    _stepLine(),
                    _stepIndicator('3', 'Interests', _currentStep >= 2),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create your account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Join a community that believes in sharing\nand supporting each other.', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
            decoration: BoxDecoration(color: const Color(0xFFE9F5E9), borderRadius: BorderRadius.circular(8)),
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
          const SizedBox(height: 32),
          _nextButton('Continue'),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Setup your Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tell your neighbors who you are and where you are located.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 32),
          _buildTextField(controller: _usernameController, hint: 'Username (unique)', icon: Icons.alternate_email),
          const SizedBox(height: 16),
          
          LocationAutocompleteField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Your area / neighbourhood',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
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
            onSelected: (loc) {
              setState(() {
                _selectedLocation = loc;
              });
            },
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text('Helps us show relevant listings near you.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          const SizedBox(height: 32),
          _nextButton('Continue'),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Interests & Policy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Select what you are interested in sharing.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 32),
          _buildTextField(controller: _interestsController, hint: 'Interests (comma separated)', icon: Icons.favorite_border),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text('e.g. Tools, Gardening, Books', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _checkbox(_agreeTerms, (v) => setState(() => _agreeTerms = v!)),
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
              _checkbox(_receiveUpdates, (v) => setState(() => _receiveUpdates = v!)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "I'd like to receive community updates and helpful tips (optional)",
                  style: TextStyle(color: Colors.black87, fontSize: 13),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          _nextButton('Create account', isFinal: true),
        ],
      ),
    );
  }

  Widget _nextButton(String text, {bool isFinal = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading && isFinal
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
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
            child: Text(num, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
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
}
