import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/animated_checkmark.dart';
import '../../../core/presentation/widgets/glassmorphism.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:async';

import '../../../core/data/models/listing.dart';

class RequestExchangePage extends StatefulWidget {
  final Listing listing;
  const RequestExchangePage({super.key, required this.listing});

  @override
  State<RequestExchangePage> createState() => _RequestExchangePageState();
}

class _RequestExchangePageState extends State<RequestExchangePage> {
  final PageController _pageController = PageController();
  bool _isLoading = false;

  void _submitRequest() {
    setState(() => _isLoading = true);
    Timer(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () {
            if (_pageController.page?.round() == 1) {
              context.pop();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildRequestForm(context),
          _buildSuccessPage(context),
        ],
      ),
    );
  }

  Widget _buildRequestForm(BuildContext context) {
    return Stack(
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
              const Text('Request Exchange', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 24),
              
              const Text('Your request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/images/nintendo.jpg', width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(width: 48, height: 48, color: Colors.grey[200]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nintendo Switch', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          Text('From Rahul Sharma', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('What are you offering?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.exchange.withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: AppColors.exchange.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/images/ps5_controller.jpg', width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(width: 48, height: 48, color: Colors.grey[200]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PS5 Controller', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          Text('Good condition', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('Add a message (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi! I have a PS5 controller in good condition.\nLet me know if you\'re interested in exchanging.', style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4)),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('78/200', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('Preferred pickup location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.exchange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Sainagar Society Gate', style: TextStyle(color: AppColors.primaryDark, fontSize: 15))),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              
              const SizedBox(height: 24),
              const Text('When are you available?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTimeChip('Today', false)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTimeChip('This week', true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTimeChip('Custom', false)),
                ],
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ), // Close SafeArea
      
      // Sticky Button
      Positioned(
          left: 0, right: 0, bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: GlassButton(
                label: 'Send Request',
                onPressed: _isLoading ? null : _submitRequest,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTimeChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.exchange : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? AppColors.exchange : Colors.grey[300]!),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(
        color: isSelected ? Colors.white : AppColors.primaryDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 14,
      )),
    );
  }

  Widget _buildSuccessPage(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.send_rounded, color: AppColors.exchange, size: 80),
                    Positioned(top: 0, left: 0, child: Icon(Icons.star_rounded, color: Colors.amber[300], size: 20)),
                    Positioned(top: 20, right: 0, child: Icon(Icons.star_rounded, color: Colors.green[300], size: 24)),
                    Positioned(bottom: 0, right: 20, child: Icon(Icons.star_rounded, color: Colors.blue[300], size: 16)),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Request Sent!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 8),
                Text('Your exchange request has been\nsent to Rahul Sharma.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4)),
                
                const SizedBox(height: 32),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/images/nintendo.jpg', width: 48, height: 48, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(width: 48, height: 48, color: Colors.grey[200]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nintendo Switch', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            Text('For PS5 Controller', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('320 m • Sainagar', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, color: Colors.orange[700], size: 12),
                            const SizedBox(width: 4),
                            Text('Pending', style: TextStyle(color: Colors.orange[700], fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                _buildBulletPoint('Owner will be notified'),
                _buildBulletPoint('You\'ll get a response soon'),
                _buildBulletPoint('You can check updates in Activity'),
                _buildBulletPoint('Start a chat if needed'),
              ],
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.exchange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => context.go('/activity'),
                  child: const Text('View in Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => context.go('/'),
                  child: const Text('Keep Browsing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
            child: Icon(Icons.check, color: Colors.green[600], size: 14),
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        ],
      ),
    );
  }
}
