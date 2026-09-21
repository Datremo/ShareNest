import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class MyBorrowingPage extends StatelessWidget {
  const MyBorrowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('Active Borrowing', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset('assets/images/drill.jpg', fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                              ),
                              Positioned(
                                top: 16, right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text('3h 12m remaining', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Cordless Drill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryDark)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Borrowed', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Bosch GSR 120-LI', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                            
                            const SizedBox(height: 20),
                            
                            Row(
                              children: [
                                const CircleAvatar(radius: 14, backgroundImage: AssetImage('assets/images/rahul.jpg'), backgroundColor: Colors.grey),
                                const SizedBox(width: 8),
                                Text('Borrowed from Rahul Mehta', style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Timeline
                const Text('Return details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 18)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Time elapsed', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('48m / 4h', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.2, // 48m of 4h is ~20%
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                      
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.black12)),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle),
                            child: Icon(Icons.assignment_return_rounded, color: Colors.orange[700], size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Return by', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Tue, 16 Sep 2025\n10:00 PM', style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      
                    ),
                    onPressed: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.more_time_rounded, color: AppColors.primaryDark),
                        SizedBox(width: 8),
                        Text('Request Time Extension', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      
                    ),
                    onPressed: () => context.go('/conversation/rahul_mehta'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(CupertinoIcons.chat_bubble_text, color: AppColors.primaryDark),
                        SizedBox(width: 8),
                        Text('Message Owner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
          
          // Sticky Button
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () {},
                  child: const Text('Mark as Returned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
