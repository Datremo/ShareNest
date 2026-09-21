import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ExchangeCompletedPage extends StatelessWidget {
  const ExchangeCompletedPage({super.key});

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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 140,
                      child: Stack(
                        children: [
                          Positioned(top: 20, left: 10, child: Icon(Icons.star, color: Colors.blue[300], size: 16)),
                          Positioned(top: 10, right: 30, child: Icon(Icons.star, color: Colors.yellow[600], size: 20)),
                          Positioned(bottom: 20, left: 30, child: Icon(Icons.star, color: Colors.green[400], size: 14)),
                          Positioned(bottom: 30, right: 10, child: Icon(Icons.star, color: Colors.red[400], size: 18)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.rotate(
                          angle: -0.2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/images/nintendo.jpg', width: 64, height: 64, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 64, height: 64, color: Colors.grey[200]),
                            ),
                          ),
                        ),
                        Container(
                          width: 48, height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.exchange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 28),
                        ),
                        Transform.rotate(
                          angle: 0.1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/images/ps5_controller.jpg', width: 64, height: 64, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 64, height: 64, color: Colors.grey[200]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Text('Exchange Completed!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                Text('You have successfully exchanged\nwith Rahul Sharma.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4)),
                
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/images/nintendo.jpg', width: 80, height: 80, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey[200]),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Nintendo Switch', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('To Rahul Sharma', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/images/ps5_controller.jpg', width: 80, height: 80, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey[200]),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('PS5 Controller', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('From You', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                _buildActionRow(Icons.star_outline, 'Leave a Review', 'Rate your experience'),
                const Divider(indent: 52, height: 1, color: Colors.black12),
                _buildActionRow(Icons.receipt_long_outlined, 'View Exchange Details', 'See full transaction info'),
                const Divider(indent: 52, height: 1, color: Colors.black12),
                _buildActionRow(Icons.bookmark_outline, 'Save User', 'Keep in your trusted neighbours'),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
          
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
                    backgroundColor: AppColors.exchange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => context.go('/activity'), // Activity history
                  child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.exchange, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
