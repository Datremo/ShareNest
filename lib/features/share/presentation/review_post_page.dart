import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../requests/presentation/widgets/animated_send_icon.dart';

class ReviewPostPage extends StatefulWidget {
  final Listing listing;
  final List<XFile> images;

  const ReviewPostPage({
    super.key,
    required this.listing,
    required this.images,
  });

  @override
  State<ReviewPostPage> createState() => _ReviewPostPageState();
}

class _ReviewPostPageState extends State<ReviewPostPage> with SingleTickerProviderStateMixin {
  final ListingRepository _listingRepo = ListingRepository();
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

  Future<void> _submitPost() async {
    setState(() => _isSubmitting = true);
    _animationController.forward();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('You must be logged in to post.');

      List<String> photoUrls = [];
      if (widget.images.isNotEmpty) {
        for (final image in widget.images) {
          final bytes = await image.readAsBytes();
          final ext = image.name.split('.').last;
          final url = await _listingRepo.uploadListingImage(bytes, ext);
          photoUrls.add(url);
        }
      }

      final listingToSave = widget.listing.copyWith(
        ownerId: user.id,
        photoUrls: photoUrls,
      );

      await _listingRepo.createListing(listingToSave);
      
      // Wait for animation to finish visually
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        context.pushReplacement('/post_published');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSubmitting = false);
        _animationController.reverse();
      }
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isHighlight ? AppColors.primary : AppColors.primaryDark,
                fontSize: 15,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.listing.mode;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // Light gray background for contrast with glass cards
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('Review Post', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 50, left: -100,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Summary Card
                _buildGlassCard(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: widget.images.isNotEmpty
                            ? (kIsWeb 
                                ? Image.network(widget.images.first.path, width: 80, height: 80, fit: BoxFit.cover)
                                : Image.file(File(widget.images.first.path), width: 80, height: 80, fit: BoxFit.cover))
                            : Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
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
                            const SizedBox(height: 4),
                            Text(widget.listing.locationName ?? 'Location not specified', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text('Post Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: -0.5)),
                const SizedBox(height: 16),
                
                // Details Table Card
                _buildGlassCard(
                  child: Column(
                    children: [
                      _buildDataRow('Transaction Type', mode.toUpperCase()),
                      const Divider(height: 24, thickness: 1, color: Colors.black12),
                      _buildDataRow('Category', widget.listing.categoryId),
                      const Divider(height: 24, thickness: 1, color: Colors.black12),
                      _buildDataRow('Condition', widget.listing.condition ?? 'Not specified'),
                      
                      if (widget.listing.availability != null && widget.listing.availability!.isNotEmpty) ...[
                        const Divider(height: 24, thickness: 1, color: Colors.black12),
                        _buildDataRow('Available From', DateFormat('MMM d, yyyy').format(DateTime.parse(widget.listing.availability![0]))),
                        if (widget.listing.availability!.length > 1) ...[
                          const Divider(height: 24, thickness: 1, color: Colors.black12),
                          _buildDataRow('Available Until', DateFormat('MMM d, yyyy').format(DateTime.parse(widget.listing.availability![1]))),
                        ],
                      ],

                      if (widget.listing.preferences?['returnPeriod'] != null) ...[
                        const Divider(height: 24, thickness: 1, color: Colors.black12),
                        _buildDataRow('Return Period', widget.listing.preferences!['returnPeriod'], isHighlight: true),
                      ],
                    ],
                  ),
                ),
                
                if (widget.listing.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.listing.description!,
                            style: const TextStyle(fontSize: 15, color: AppColors.primaryDark, height: 1.5, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Bottom button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF2F4F7).withOpacity(0),
                    const Color(0xFFF2F4F7),
                    const Color(0xFFF2F4F7),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: GestureDetector(
                onTap: _isSubmitting ? null : _submitPost,
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
                            Text('Confirm & Publish', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                      if (_isSubmitting)
                        AnimatedBuilder(
                          animation: _flyAnimation,
                          builder: (context, child) {
                            final dx = _flyAnimation.value * 300;
                            final dy = -_flyAnimation.value * 200;
                            final opacity = (1 - _flyAnimation.value).clamp(0.0, 1.0);
                            
                            return Transform.translate(
                              offset: Offset(dx, dy),
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.rotate(
                                  angle: -_flyAnimation.value * 0.5,
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
