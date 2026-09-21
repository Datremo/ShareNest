import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class PickupDetailsPage extends StatelessWidget {
  const PickupDetailsPage({super.key});

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
        title: const Text('Pickup Details', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
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
                // Map Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Image.asset('assets/images/map_placeholder.jpg', width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(color: Colors.blue[50]),
                              ),
                              // Location Pin
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Icon(Icons.location_on, color: Colors.red[500], size: 40),
                                ),
                              ),
                              // User Pin
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 60, right: 60),
                                  child: Container(
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                                    child: const CircleAvatar(radius: 12, backgroundImage: AssetImage('assets/images/priya.jpg'), backgroundColor: Colors.blue),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sainagar Society Gate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
                                  const SizedBox(height: 2),
                                  Text('Sainagar, Old Panvel', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(20)),
                              child: const Text('Open in Maps', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Details
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.access_time_rounded, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pickup time', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Today, 5:00 PM', style: TextStyle(color: AppColors.primaryDark, fontSize: 14)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                      child: const Text('Add to Calendar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 32, color: Colors.black12)),
                
                Row(
                  children: [
                    const CircleAvatar(radius: 24, backgroundImage: AssetImage('assets/images/priya.jpg'), backgroundColor: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('Priya Sharma', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle, border: Border.all(color: Colors.grey[300]!)),
                      child: const Icon(Icons.call_rounded, color: AppColors.primaryDark, size: 20),
                    )
                  ],
                ),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 32, color: Colors.black12)),
                
                // Notes
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 20),
                    const SizedBox(width: 8),
                    const Text('Important notes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulletPoint('Meet at the main gate.'),
                      _buildBulletPoint('I\'ll be there around 5 PM.'),
                      _buildBulletPoint('Chair is in good condition. Please carry a vehicle if needed.'),
                    ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                      onPressed: () => context.push('/item_received'), // Or borrow equivalent
                      child: const Text('Mark as Picked Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Let the giver know once you have collected the item.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4, height: 4,
            decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }
}
