import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';
import '../../../core/data/models/urgent_request.dart';

class CreateUrgentRequestPage extends StatefulWidget {
  const CreateUrgentRequestPage({super.key});

  @override
  State<CreateUrgentRequestPage> createState() => _CreateUrgentRequestPageState();
}

class _CreateUrgentRequestPageState extends State<CreateUrgentRequestPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Form State
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  String? _neededBy;
  String? _duration;
  double _radiusKm = 2.0;
  
  TimeOfDay? _specificTime;
  final _customDurationController = TextEditingController();

  // Animation for final submit
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _customDurationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);
    _pulseController.repeat(reverse: true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Add to DB
      await Supabase.instance.client.from('urgent_requests').insert({
        'requester_id': user.id,
        'title': _titleController.text,
        'description': _descController.text,
        'needed_by': _neededBy == 'By a specific time' && _specificTime != null 
          ? 'By ${_specificTime!.format(context)}' 
          : (_neededBy ?? 'Right now'),
        'duration': _duration == 'Custom' ? _customDurationController.text : (_duration ?? '30 min'),
        'radius_km': _radiusKm,
        'lat': 18.98, // Dummy location for now
        'lng': 73.11, // Dummy location for now
        'status': 'ACTIVE',
        // Example: Expire in 24 hours for safety, or based on 'neededBy'
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      });

      // Wait a bit for the cool pulse animation to be seen
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        context.pop(); // Go back to Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Neighbourhood SOS Sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _pulseController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: _prevStep,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFE53935), size: 24),
            const SizedBox(width: 8),
            Text(
              'Need It Now',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFE53935)),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${_currentStep + 1} / $_totalSteps',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[500]),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (idx) => setState(() => _currentStep = idx),
            children: [
              _buildStep1What(),
              _buildStep2When(),
              _buildStep3Duration(),
              _buildStep4Radius(),
              _buildStep5Review(),
            ],
          ),
          
          if (_currentStep < 4)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Text('Next', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep1What() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you need?', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'e.g. USB-C charger',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 24),
          Text('Add a photo so neighbours know exactly what you mean.', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, color: Colors.grey[400], size: 32),
                const SizedBox(height: 4),
                Text('Add photo', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Describe what you need (Optional)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2When() {
    final options = ['Right now', 'Within 1 hour', 'Today', 'By a specific time'];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When do you need it?', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Helps neighbours know if they can get it to you in time.', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 32),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () async {
                setState(() => _neededBy = opt);
                if (opt == 'By a specific time') {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null && mounted) {
                    setState(() {
                      _specificTime = time;
                    });
                  } else {
                    // reset if they cancel
                    setState(() => _neededBy = null);
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: _neededBy == opt ? const Color(0xFFFFE5E5) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _neededBy == opt ? const Color(0xFFE53935) : Colors.transparent, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      opt == 'By a specific time' && _neededBy == opt && _specificTime != null 
                        ? 'By ${_specificTime!.format(context)}' 
                        : opt, 
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: _neededBy == opt ? FontWeight.bold : FontWeight.w500, color: _neededBy == opt ? const Color(0xFFE53935) : AppColors.textPrimary)
                    ),
                    if (_neededBy == opt) const Icon(Icons.check_circle, color: Color(0xFFE53935)),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStep3Duration() {
    final options = ['30 min', '2 hrs', 'Today', '1 day', 'Custom'];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How long do you need it?', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((opt) => GestureDetector(
              onTap: () => setState(() => _duration = opt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: _duration == opt ? const Color(0xFFE53935) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    if (_duration == opt) BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ]
                ),
                child: Text(opt, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _duration == opt ? Colors.white : AppColors.textPrimary)),
              ),
            )).toList(),
          ),
          
          if (_duration == 'Custom') ...[
            const SizedBox(height: 24),
            TextField(
              controller: _customDurationController,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'e.g. 3 hours, 2 days',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4Radius() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search nearby', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('How far are you willing to go to pick it up?', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 48),
          
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radar circles
                Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFE5E5), width: 2))),
                Container(width: 170, height: 170, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFF9E9E).withValues(alpha: 0.5), width: 2))),
                Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE53935).withValues(alpha: 0.1))),
                const Icon(Icons.person_pin_circle, color: Color(0xFFE53935), size: 48),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFE53935),
              inactiveTrackColor: const Color(0xFFFFE5E5),
              thumbColor: const Color(0xFFE53935),
              overlayColor: const Color(0xFFE53935).withValues(alpha: 0.2),
              valueIndicatorColor: const Color(0xFFE53935),
            ),
            child: Slider(
              value: _radiusKm,
              min: 0.5,
              max: 5.0,
              divisions: 4,
              label: '${_radiusKm} km',
              onChanged: (val) => setState(() => _radiusKm = val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('500m', style: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.bold)),
              Text('5km', style: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStep5Review() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Final review', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFE53935), size: 28),
                    const SizedBox(width: 8),
                    Text('Need It Now', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFE53935))),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_titleController.text.isEmpty ? 'Untitled Item' : _titleController.text, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildReviewRow(Icons.access_time_filled, 'Need by', _neededBy == 'By a specific time' && _specificTime != null 
                    ? 'By ${_specificTime!.format(context)}' 
                    : (_neededBy ?? 'Right now')),
                const SizedBox(height: 16),
                _buildReviewRow(Icons.timer, 'Borrow for', _duration == 'Custom' ? _customDurationController.text : (_duration ?? '30 min')),
                const SizedBox(height: 16),
                _buildReviewRow(Icons.location_on, 'Looking within', '${_radiusKm} km'),
                if (_descController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildReviewRow(Icons.notes, 'Note', '"${_descController.text}"'),
                ]
              ],
            ),
          ),
          
          const Spacer(),
          
          if (_isSubmitting)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE53935).withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Container(
                        width: 50, height: 50,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE53935)),
                        child: const Icon(Icons.wifi_tethering, color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.podcasts, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Send Request', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
            Text(value, style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
