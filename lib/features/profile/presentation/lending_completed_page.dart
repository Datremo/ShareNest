import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class LendingCompletedPage extends StatelessWidget {
  const LendingCompletedPage({super.key});

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
                      width: 140,
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
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 48),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Text('Lending Completed!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                Text('Your Cordless Drill has been\nreturned.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4)),
                
                const SizedBox(height: 40),
                
                Row(
                  children: [
                    const CircleAvatar(radius: 24, backgroundImage: AssetImage('assets/images/avatar_man.jpg'), backgroundColor: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rahul Mehta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('4.9 (12)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote, color: Colors.grey, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"Great experience! Very\nfriendly and responsible."',
                          style: TextStyle(color: Colors.grey[800], fontSize: 15, fontStyle: FontStyle.italic, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100),
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
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => context.push('/impact_summary'),
                  child: const Text('View Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
