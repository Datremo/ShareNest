import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class UrgentRequestPage extends StatefulWidget {
  const UrgentRequestPage({super.key});

  @override
  State<UrgentRequestPage> createState() => _UrgentRequestPageState();
}

class _UrgentRequestPageState extends State<UrgentRequestPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0 = Form, 1 = Review

  // Colors based on mockup
  final Color _darkGreen = const Color(0xFF0F6937); // Primary dark green
  final Color _redGradientStart = const Color(0xFFFF5269);
  final Color _redGradientEnd = const Color(0xFFFF334B);

  // Form states
  String _selectedCategory = 'Electronics';
  String _selectedUrgency = 'Now';
  String _selectedDistance = '500 m';
  String _selectedDuration = '2 hours';
  bool _meetSafePlace = true;
  bool _verifiedOnly = false;

  void _nextStep() {
    if (_currentStep == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
      setState(() => _currentStep = 1);
    } else {
      // Show success dialog or go to confirmed
      _showSuccessDialog();
    }
  }

  void _prevStep() {
    if (_currentStep == 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
      setState(() => _currentStep = 0);
    } else {
      context.pop();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _darkGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: _darkGreen, size: 64),
              ),
              const SizedBox(height: 24),
              const Text('Request Sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              const Text('We are notifying verified neighbours within 500m. You will get a notification soon.', 
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () {
                    context.pop(); // dismiss dialog
                    context.go('/home'); // back to home
                  },
                  child: const Text('Return to Home', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Off-white background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: _prevStep,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, color: _darkGreen, size: 22),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ShareNest', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: -0.5)),
                Text('People • Things • A Kinder Tomorrow', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          if (_currentStep == 0)
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.primaryDark),
              label: const Text('Need Help?', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildFormPage(),
          _buildReviewPage(),
        ],
      ),
    );
  }

  // =====================================
  // PAGE 1: FORM
  // =====================================

  Widget _buildFormPage() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  title: 'Need It Now',
                  titleIcon: Icons.bolt_rounded,
                  iconColor: _redGradientStart,
                  subtitle: 'Get urgent help from nearby neighbours.\nWhen you need something quickly, your community is here.',
                ),
                const SizedBox(height: 32),
                
                // Search Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: TextField(
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'What do you need right now?',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(CupertinoIcons.search, color: Colors.grey[500], size: 22),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text('e.g. Phone charger, Umbrella, Medicine, Power bank...', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ),
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select a category (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    Text('See all', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      _buildCategoryItem('Electronics', Icons.phone_iphone_rounded, _selectedCategory == 'Electronics'),
                      const SizedBox(width: 12),
                      _buildCategoryItem('Home & Kitchen', Icons.home_rounded, _selectedCategory == 'Home & Kitchen'),
                      const SizedBox(width: 12),
                      _buildCategoryItem('Tools', Icons.build_rounded, _selectedCategory == 'Tools'),
                      const SizedBox(width: 12),
                      _buildCategoryItem('Medical', Icons.medical_services_rounded, _selectedCategory == 'Medical'),
                      const SizedBox(width: 12),
                      _buildCategoryItem('Other', Icons.more_horiz_rounded, _selectedCategory == 'Other'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text('Why do you need it? (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a short message...\n\n"e.g. My phone is at 2%. Shops are closed."',
                    hintStyle: TextStyle(color: Colors.grey[400], height: 1.5),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _darkGreen, width: 1.5)),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(padding: EdgeInsets.only(top: 8, right: 8), child: Text('0/200', style: TextStyle(color: Colors.grey, fontSize: 12))),
                ),

                const SizedBox(height: 24),
                const Text('How soon do you need it?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildGradientButton('Now', Icons.bolt_rounded, _selectedUrgency == 'Now', () => setState(() => _selectedUrgency = 'Now'))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildOutlineButton('Within 1 hour', Icons.access_time_rounded, _selectedUrgency == 'Within 1 hour', () => setState(() => _selectedUrgency = 'Within 1 hour'))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildOutlineButton('Later today', Icons.calendar_today_rounded, _selectedUrgency == 'Later today', () => setState(() => _selectedUrgency = 'Later today'))),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('How far can you go?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildFilterChip('250 m', _selectedDistance == '250 m', () => setState(() => _selectedDistance = '250 m'))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip('500 m', _selectedDistance == '500 m', () => setState(() => _selectedDistance = '500 m'))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip('1 km', _selectedDistance == '1 km', () => setState(() => _selectedDistance = '1 km'))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip('2 km', _selectedDistance == '2 km', () => setState(() => _selectedDistance = '2 km'))),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('For how long do you need it?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildFilterChip('30 min', _selectedDuration == '30 min', () => setState(() => _selectedDuration = '30 min'))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip('2 hours', _selectedDuration == '2 hours', () => setState(() => _selectedDuration = '2 hours'))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip('Tonight', _selectedDuration == 'Tonight', () => setState(() => _selectedDuration = 'Tonight'))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip('Custom', _selectedDuration == 'Custom', () => setState(() => _selectedDuration = 'Custom'))),
                  ],
                ),
                
                const SizedBox(height: 40),
                _buildToggleRow(
                  'Meet in a safe public place', 
                  'Recommended for your safety', 
                  true, 
                  _meetSafePlace, 
                  (v) => setState(() => _meetSafePlace = v)
                ),
                const Divider(height: 32, color: Colors.black12),
                _buildToggleRow(
                  'Show my request to verified users only', 
                  'Increases trust and safety', 
                  false, 
                  _verifiedOnly, 
                  (v) => setState(() => _verifiedOnly = v)
                ),
                const SizedBox(height: 100), // padding for bottom bar
              ],
            ),
          ),
        ),
        _buildBottomBar(
          buttonLabel: 'Next  →', 
          buttonColor: _darkGreen, 
          onTap: _nextStep,
        ),
      ],
    );
  }

  // =====================================
  // PAGE 2: REVIEW
  // =====================================

  Widget _buildReviewPage() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  title: 'Review Your Request',
                  subtitle: 'Please check the details before sending to nearby neighbours.',
                ),
                const SizedBox(height: 32),

                // Card 1: Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with floating Edit
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset('assets/images/usb_charger.jpg', width: 90, height: 90, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 90, height: 90, color: Colors.grey[200]),
                            ),
                          ),
                          Positioned(
                            bottom: 6, right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_rounded, color: Colors.white, size: 10),
                                  SizedBox(width: 4),
                                  Text('Edit', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(child: Text('USB-C Charger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: _redGradientStart, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildReviewGridRow('Category', _selectedCategory),
                            const SizedBox(height: 6),
                            _buildReviewGridRow('Needed', _selectedUrgency),
                            const SizedBox(height: 6),
                            _buildReviewGridRow('Borrow for', _selectedDuration),
                            const SizedBox(height: 6),
                            _buildReviewGridRow('Radius', _selectedDistance),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                // Card 2: Message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.format_quote_rounded, color: Colors.blue[300], size: 28),
                          const SizedBox(width: 8),
                          const Text('Message (optional)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15)),
                          const Spacer(),
                          Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark.withValues(alpha: 0.8), fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('"My phone is at 2%. Shops are closed. Need for 2 hours."', style: TextStyle(color: Colors.grey[700], fontSize: 15, height: 1.4)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Card 3: Pickup
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: _darkGreen, size: 24),
                          const SizedBox(width: 8),
                          const Text('Pickup Preference', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15)),
                          const Spacer(),
                          Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark.withValues(alpha: 0.8), fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Safe public place (e.g. society gate, café)', style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Map View Mockup
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Image.asset('assets/images/map_placeholder.jpg', width: double.infinity, fit: BoxFit.cover),
                              // Radar circle
                              Center(
                                child: Container(
                                  width: 120, height: 120,
                                  decoration: BoxDecoration(
                                    color: _darkGreen.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _darkGreen.withValues(alpha: 0.3), width: 1),
                                  ),
                                ),
                              ),
                              // Map Pins
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue,
                                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))],
                                      ),
                                      child: const Icon(Icons.circle, color: Colors.white, size: 8),
                                    )
                                  ],
                                ),
                              ),
                              // Urgent marker
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 50, right: 20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [_redGradientStart, _redGradientEnd]),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))],
                                    ),
                                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                              // Tooltip
                              Positioned(
                                top: 16, right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                  child: Text('Sending to neighbours\nwithin $_selectedDistance', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                ),
                              ),
                              // Crosshair
                              Positioned(
                                bottom: 16, right: 16,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                  child: const Icon(Icons.my_location_rounded, size: 20, color: AppColors.primaryDark),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _darkGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_alt_rounded, color: _darkGreen),
                      const SizedBox(width: 16),
                      Expanded(child: Text("Your request will be sent to nearby neighbours who might be able to help. You'll be notified as soon as someone responds.", 
                        style: TextStyle(color: _darkGreen.withValues(alpha: 0.8), fontSize: 13, height: 1.4))),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildBottomBar(
          buttonLabel: 'Send to Nearby Neighbours', 
          buttonIcon: Icons.bolt_rounded,
          buttonGradient: LinearGradient(colors: [_redGradientStart, _redGradientEnd]), 
          onTap: _nextStep,
          subtitle: 'Help is just around the corner 💚'
        ),
      ],
    );
  }
  
  Widget _buildReviewGridRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w600))),
      ],
    );
  }

  // =====================================
  // UI HELPERS
  // =====================================

  Widget _buildHeader({required String title, required String subtitle, IconData? titleIcon, Color? iconColor}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, color: iconColor, size: 40),
                  const SizedBox(width: 8),
                ],
                Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: -1)),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4)),
          ],
        ),
        Positioned(
          top: -30,
          right: -10,
          child: Transform.rotate(
            angle: -0.1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Stronger\nNeighbours\nBrighter\nTomorrows ♥', textAlign: TextAlign.right, style: TextStyle(
                  fontFamily: 'Caveat', // Or just cursive fallback
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  color: _darkGreen.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                )),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isSelected ? _darkGreen : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? _darkGreen : Colors.grey[300]!, width: 1.5),
              boxShadow: isSelected ? [BoxShadow(color: _darkGreen.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? Colors.white : (title == 'Medical' ? Colors.red : _darkGreen), size: 28),
                const SizedBox(height: 8),
                Text(title, textAlign: TextAlign.center, style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primaryDark, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [_redGradientStart, _redGradientEnd]) : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
          boxShadow: isSelected ? [BoxShadow(color: _redGradientStart.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0,4))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 18),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: isSelected ? Colors.white : AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton(String text, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? _darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? _darkGreen : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.primaryDark, size: 18),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: isSelected ? Colors.white : AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _darkGreen : Colors.grey[300]!),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryDark, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          )),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool showShield, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (showShield)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _darkGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.shield_rounded, color: _darkGreen, size: 20),
            )
          else 
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.verified_user_rounded, color: Colors.grey, size: 20),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: _darkGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required String buttonLabel, IconData? buttonIcon, Color? buttonColor, Gradient? buttonGradient, required VoidCallback onTap, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: buttonColor,
                gradient: buttonGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: buttonGradient != null ? [BoxShadow(color: _redGradientStart.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0,4))] : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (buttonIcon != null) ...[
                    Icon(buttonIcon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(buttonLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic)),
          ]
        ],
      ),
    );
  }
}
