import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ItemReceivedPage extends StatelessWidget {
  const ItemReceivedPage({super.key});

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
                  const SizedBox(height: 60),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(color: Colors.pink[50], shape: BoxShape.circle),
                        child: const Icon(CupertinoIcons.gift_fill, color: Colors.pink, size: 50),
                      ),
                      Positioned(top: -10, right: 10, child: Icon(Icons.star_rounded, color: Colors.amber[300], size: 20)),
                      Positioned(bottom: -10, left: 10, child: Icon(Icons.star_rounded, color: Colors.amber[400], size: 24)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Item Received!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 8),
                  Text('You successfully picked up the\nOffice Chair from Priya Sharma.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4)),
                  
                  const SizedBox(height: 32),
                  const Text('Thank you for keeping things in use\nand helping the community!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary, height: 1.4)),
                  
                  const SizedBox(height: 40),
                  
                  // Item Snippet with Completed badge
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
                          child: Image.asset('assets/images/office_chair.jpg', width: 48, height: 48, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(width: 48, height: 48, color: Colors.grey[200]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Office Chair', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              const SizedBox(height: 2),
                              const Text('Free to keep', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 12),
                                  const SizedBox(width: 4),
                                  Text('Completed on Tue, 16 Sep', style: TextStyle(color: Colors.grey[800], fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green[700], size: 12),
                              const SizedBox(width: 4),
                              Text('Received', style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
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
                    onPressed: () => context.go('/home'),
                    child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    onPressed: () => context.go('/activity'),
                    child: const Text('View Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
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
