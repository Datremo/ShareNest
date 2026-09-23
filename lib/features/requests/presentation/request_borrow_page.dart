import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/animated_checkmark.dart';
import '../../../core/presentation/widgets/glassmorphism.dart';
import '../../../core/presentation/widgets/glassmorphism.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/listing.dart';
import 'review_request_page.dart';

class RequestBorrowPage extends StatefulWidget {
  final Listing listing;
  const RequestBorrowPage({super.key, required this.listing});

  @override
  State<RequestBorrowPage> createState() => _RequestBorrowPageState();
}

class _RequestBorrowPageState extends State<RequestBorrowPage> {
  final TextEditingController _messageController = TextEditingController();
  
  late DateTime _selectedPickupDate;
  late TimeOfDay _selectedPickupTime;
  
  late DateTime _selectedReturnDate;
  late TimeOfDay _selectedReturnTime;
  
  List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _parseAvailability();
    
    // Set default pickup time
    _selectedPickupDate = _availableDates.isNotEmpty ? _availableDates.first : DateTime.now();
    final now = TimeOfDay.now();
    _selectedPickupTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);

    // Set default return time (2 hours later)
    _selectedReturnDate = _selectedPickupDate;
    _selectedReturnTime = TimeOfDay(hour: (_selectedPickupTime.hour + 2) % 24, minute: _selectedPickupTime.minute);
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
  
  DateTime get _returnDateTime {
    return DateTime(_selectedReturnDate.year, _selectedReturnDate.month, _selectedReturnDate.day, _selectedReturnTime.hour, _selectedReturnTime.minute);
  }

  Future<void> _pickDateTime({required bool isPickup}) async {
    final firstDate = _availableDates.isNotEmpty ? _availableDates.first : DateTime.now();
    final lastDate = _availableDates.isNotEmpty ? _availableDates.last : DateTime.now().add(const Duration(days: 365));
    
    final initialDate = isPickup ? _selectedPickupDate : _selectedReturnDate;
    
    // The earliest date they can pick is either today or the availability start date (whichever is later)
    final minDate = firstDate.isBefore(DateTime.now()) ? DateTime.now() : firstDate;
    
    // For return, they cannot pick a date before the pickup date
    final pickerFirstDate = isPickup ? minDate : _selectedPickupDate;
    
    // Ensure initialDate and lastDate are within bounds
    var safeLastDate = lastDate;
    if (safeLastDate.isBefore(pickerFirstDate)) safeLastDate = pickerFirstDate;
    
    var safeInitialDate = initialDate;
    if (safeInitialDate.isBefore(pickerFirstDate)) safeInitialDate = pickerFirstDate;
    if (safeInitialDate.isAfter(safeLastDate)) safeInitialDate = safeLastDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: pickerFirstDate,
      lastDate: safeLastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.primaryDark),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final initialTime = isPickup ? _selectedPickupTime : _selectedReturnTime;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.primaryDark),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          if (isPickup) {
            _selectedPickupDate = pickedDate;
            _selectedPickupTime = pickedTime;
            // auto adjust return if it's before pickup
            if (_returnDateTime.isBefore(_pickupDateTime)) {
              _selectedReturnDate = pickedDate;
              _selectedReturnTime = TimeOfDay(hour: (pickedTime.hour + 2) % 24, minute: pickedTime.minute);
            }
          } else {
            _selectedReturnDate = pickedDate;
            _selectedReturnTime = pickedTime;
          }
        });
      }
    }
  }

  void _goToReview() {
    if (_returnDateTime.isBefore(_pickupDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return time cannot be before pickup time')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewRequestPage(
          listing: widget.listing,
          message: _messageController.text,
          pickupTime: _pickupDateTime,
          startDate: _pickupDateTime,
          endDate: _returnDateTime,
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
        title: const Text('Borrow Request', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900)),
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
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
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
                const Text('When do you need it?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 16),
                
                GlassCard(
                  blur: 20,
                  opacity: 0.2,
                  child: Column(
                    children: [
                      _buildDateSelector(
                        title: 'Expected Pickup',
                        icon: Icons.calendar_today_rounded,
                        dateTime: _pickupDateTime,
                        onTap: () => _pickDateTime(isPickup: true),
                      ),
                      Divider(height: 1, color: Colors.white.withAlpha(128), indent: 20, endIndent: 20),
                      _buildDateSelector(
                        title: 'Expected Return',
                        icon: Icons.assignment_return_rounded,
                        dateTime: _returnDateTime,
                        onTap: () => _pickDateTime(isPickup: false),
                        isEnd: true,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text('Add a message (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
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

  Widget _buildDateSelector({required String title, required IconData icon, required DateTime dateTime, required VoidCallback onTap, bool isEnd = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(top: Radius.circular(isEnd ? 0 : 24), bottom: Radius.circular(isEnd ? 24 : 0)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
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
