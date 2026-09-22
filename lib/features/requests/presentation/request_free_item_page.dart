import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/animated_checkmark.dart';
import '../../../core/presentation/widgets/glassmorphism.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/listing.dart';
import 'review_request_page.dart';

class RequestFreeItemPage extends StatefulWidget {
  final Listing listing;
  const RequestFreeItemPage({super.key, required this.listing});

  @override
  State<RequestFreeItemPage> createState() => _RequestFreeItemPageState();
}

class _RequestFreeItemPageState extends State<RequestFreeItemPage> {
  final TextEditingController _messageController = TextEditingController();
  
  late DateTime _selectedPickupDate;
  late TimeOfDay _selectedPickupTime;
  
  List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _parseAvailability();
    
    // Set default pickup time
    _selectedPickupDate = _availableDates.isNotEmpty ? _availableDates.first : DateTime.now();
    final now = TimeOfDay.now();
    _selectedPickupTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
  }

  void _parseAvailability() {
    if (widget.listing.availability == null || widget.listing.availability!.isEmpty) return;
    for (final dateStr in widget.listing.availability!) {
      if (dateStr == 'Available Immediately') {
        _availableDates.add(DateTime.now());
      } else {
        final d = DateTime.tryParse(dateStr);
        if (d != null) _availableDates.add(d);
      }
    }
    _availableDates.sort((a, b) => a.compareTo(b));
  }

  DateTime get _pickupDateTime {
    return DateTime(_selectedPickupDate.year, _selectedPickupDate.month, _selectedPickupDate.day, _selectedPickupTime.hour, _selectedPickupTime.minute);
  }

  Future<void> _pickDateTime() async {
    final firstDate = _availableDates.isNotEmpty ? _availableDates.first : DateTime.now();
    final lastDate = firstDate.add(const Duration(days: 365)); // For GIVE, it's open ended
    final minDate = firstDate.isBefore(DateTime.now()) ? DateTime.now() : firstDate;
    
    var safeLastDate = lastDate;
    if (safeLastDate.isBefore(minDate)) safeLastDate = minDate;
    
    // Ensure initialDate is within bounds
    var safeInitialDate = _selectedPickupDate;
    if (safeInitialDate.isBefore(minDate)) safeInitialDate = minDate;
    if (safeInitialDate.isAfter(safeLastDate)) safeInitialDate = safeLastDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: minDate,
      lastDate: safeLastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.primaryDark),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedPickupTime,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.primaryDark),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedPickupDate = pickedDate;
          _selectedPickupTime = pickedTime;
        });
      }
    }
  }

  void _goToReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewRequestPage(
          listing: widget.listing,
          message: _messageController.text,
          pickupTime: _pickupDateTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.primaryDark), onPressed: () => context.pop()),
        title: const Text('Claim Item', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              widget.listing.photoUrls.isNotEmpty
                  ? widget.listing.photoUrls.first
                  : '',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withAlpha(204),
                    AppColors.primaryLight.withAlpha(153),
                    AppColors.primaryLight.withAlpha(204),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero
                Center(
                  child: Hero(
                    tag: 'listing_img_${widget.listing.id}',
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                        image: widget.listing.photoUrls.isNotEmpty 
                          ? DecorationImage(image: NetworkImage(widget.listing.photoUrls.first), fit: BoxFit.cover)
                          : null,
                      ),
                      child: widget.listing.photoUrls.isEmpty ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: Text(widget.listing.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryDark))),
                const SizedBox(height: 8),
                Center(child: Text('Requested Item', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]))),
                const SizedBox(height: 40),
                
                // Form Section 1: Dates
                const Text('When will you pick it up?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 16),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: _buildDateSelector(
                    title: 'Expected Pickup',
                    icon: Icons.calendar_today_rounded,
                    dateTime: _pickupDateTime,
                    onTap: () => _pickDateTime(),
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text('Add a message (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add a message (optional)...',
                      filled: true,
                      fillColor: Colors.white.withAlpha(178),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withAlpha(229), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withAlpha(229), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                
                const SizedBox(height: 120), // Bottom padding
              ],
            ),
          ),
        ), // Close SafeArea
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: GlassButton(
                label: 'Review Request',
                onPressed: _goToReview,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDateSelector({required String title, required IconData icon, required DateTime dateTime, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMM d, yyyy • h:mm a').format(dateTime), style: const TextStyle(color: AppColors.primaryDark, fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Icon(Icons.edit_calendar_rounded, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
