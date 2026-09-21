import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/item_request.dart';
import '../../../core/data/repositories/request_repository.dart';

class ReviewRequestPage extends StatefulWidget {
  final Listing listing;
  final String message;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? pickupTime;

  const ReviewRequestPage({
    super.key,
    required this.listing,
    required this.message,
    this.startDate,
    this.endDate,
    this.pickupTime,
  });

  @override
  State<ReviewRequestPage> createState() => _ReviewRequestPageState();
}

class _ReviewRequestPageState extends State<ReviewRequestPage> with SingleTickerProviderStateMixin {
  final RequestRepository _requestRepo = RequestRepository();
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _flyAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _flyAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);
    _animationController.forward();

    try {
      final request = ItemRequest(
        id: '',
        listingId: widget.listing.id,
        requesterId: '', 
        status: 'PENDING',
        message: widget.message,
        startDate: widget.startDate,
        endDate: widget.endDate,
        pickupTime: widget.pickupTime,
        duration: widget.startDate != null && widget.endDate != null
            ? '${widget.endDate!.difference(widget.startDate!).inDays} days'
            : null,
      );

      await _requestRepo.createRequest(request);
      
      // Wait for animation to finish visually
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        context.pushReplacement('/request-sent');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSubmitting = false);
        _animationController.reverse();
      }
    }
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(color: AppColors.primaryDark, fontSize: 16, fontWeight: FontWeight.w800, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.listing.mode == 'LEND' ? 'Borrow' : widget.listing.mode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Review Order', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'listing_img_${widget.listing.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: widget.listing.photoUrls.isNotEmpty
                              ? Image.network(widget.listing.photoUrls.first, width: 80, height: 80, fit: BoxFit.cover)
                              : Container(width: 80, height: 80, color: Colors.grey[100], child: const Icon(Icons.image, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(mode.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                            const SizedBox(height: 8),
                            Text(widget.listing.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text('Order Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      if (widget.startDate != null && widget.endDate != null)
                        _buildSummaryRow(Icons.calendar_month_rounded, 'BORROW PERIOD', '${DateFormat('MMM d').format(widget.startDate!)} - ${DateFormat('MMM d').format(widget.endDate!)}'),
                      
                      if (widget.pickupTime != null)
                        _buildSummaryRow(Icons.access_time_filled_rounded, 'EXPECTED PICKUP', DateFormat('MMM d, yyyy • h:mm a').format(widget.pickupTime!)),
                      
                      if (widget.message.isNotEmpty)
                        _buildSummaryRow(Icons.chat_bubble_rounded, 'MESSAGE TO OWNER', '"${widget.message}"'),
                    ],
                  ),
                ),
                const SizedBox(height: 120), // spacing for bottom button
              ],
            ),
          ),
          
          // Bottom button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8F9FA).withOpacity(0),
                    const Color(0xFFF8F9FA),
                    const Color(0xFFF8F9FA),
                  ],
                  stops: const [0.0, 0.2, 1.0],
                ),
              ),
              child: GestureDetector(
                onTap: _isSubmitting ? null : _submitRequest,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isSubmitting ? AppColors.primaryDark : AppColors.primary,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: _isSubmitting ? [] : [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: _isSubmitting ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Confirm & Send Request', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                      if (_isSubmitting)
                        AnimatedBuilder(
                          animation: _flyAnimation,
                          builder: (context, child) {
                            // Fly up and right
                            final dx = _flyAnimation.value * 300;
                            final dy = -_flyAnimation.value * 200;
                            // Fade out as it flies
                            final opacity = (1 - _flyAnimation.value).clamp(0.0, 1.0);
                            
                            return Transform.translate(
                              offset: Offset(dx, dy),
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.rotate(
                                  angle: -_flyAnimation.value * 0.5, // tilt upwards
                                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 28),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
