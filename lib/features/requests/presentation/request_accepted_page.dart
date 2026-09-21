import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class RequestAcceptedPage extends StatelessWidget {
  const RequestAcceptedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
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
                      Container(
                        width: 100, height: 100,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
                      ),
                      Positioned(top: 0, right: -10, child: Icon(Icons.star_rounded, color: Colors.amber[400], size: 24)),
                      Positioned(bottom: 10, left: -20, child: Icon(Icons.star_rounded, color: Colors.amber[300], size: 16)),
                      Positioned(bottom: 30, right: -30, child: Icon(Icons.circle, color: Colors.blue[300], size: 12)),
                      Positioned(top: 20, left: -10, child: Icon(Icons.square_rounded, color: Colors.red[300], size: 12)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Request Accepted!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 8),
                  Text('Rahul has accepted your request.\nYou can now coordinate pickup details.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4)),
                  
                  const SizedBox(height: 40),
                  
                  // Item Snippet
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/images/drill.jpg', width: 48, height: 48, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(width: 48, height: 48, color: Colors.grey[200]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cordless Drill', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              const SizedBox(height: 2),
                              Text('Bosch GSR 120-LI', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Tue, 16 Sep, 6 PM - 10 PM', style: TextStyle(color: Colors.grey[800], fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: () => context.go('/conversation/rahul_mehta'),
                    child: const Text('Message Rahul', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    onPressed: () {},
                    child: const Text('View Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
