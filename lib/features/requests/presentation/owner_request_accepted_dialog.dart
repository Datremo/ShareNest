import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OwnerRequestAcceptedDialog extends StatelessWidget {
  const OwnerRequestAcceptedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti and check icon simulation
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      Positioned(top: 10, left: 10, child: Icon(Icons.star, color: Colors.yellow[600], size: 12)),
                      Positioned(top: 20, right: 10, child: Icon(Icons.star, color: Colors.green[400], size: 16)),
                      Positioned(bottom: 10, left: 20, child: Icon(Icons.star, color: Colors.red[400], size: 14)),
                      Positioned(bottom: 20, right: 20, child: Icon(Icons.star, color: Colors.blue[400], size: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Request Accepted!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            const SizedBox(height: 12),
            const Text(
              'Rahul has been notified.\nYou can now coordinate the pickup.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () {
                  context.pop(); // Close dialog
                  context.push('/conversation'); // Go to chat
                },
                child: const Text('View Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () {
                  context.pop(); // Close dialog
                  context.pop(); // Go back to request list/listing
                },
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
