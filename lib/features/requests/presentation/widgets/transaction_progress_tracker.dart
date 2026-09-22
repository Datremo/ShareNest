import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TransactionProgressTracker extends StatelessWidget {
  final String status;
  final bool hasHandoffCode;
  final bool isGiveMode;
  
  const TransactionProgressTracker({
    super.key, 
    required this.status,
    this.hasHandoffCode = false,
    this.isGiveMode = false,
  });

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    if (status == 'PENDING') currentStep = 0;
    else if (status == 'ACCEPTED' && !hasHandoffCode) currentStep = 1;
    else if (status == 'ACCEPTED' && hasHandoffCode) currentStep = 2; // Was 3, shifted to 2 for Confirmation/Handoff combo
    else if (status == 'ACTIVE') currentStep = isGiveMode ? 3 : 3;
    else if (status == 'RETURN_REQUESTED') currentStep = 4;
    else if (status == 'COMPLETED') currentStep = isGiveMode ? 3 : 5;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStep(0, 'Sent', Icons.send_rounded, currentStep),
                _buildLine(0, currentStep),
                _buildStep(1, 'Accepted', Icons.thumb_up_rounded, currentStep),
                _buildLine(1, currentStep),
                _buildStep(2, 'Handoff', Icons.qr_code_rounded, currentStep),
                if (!isGiveMode) ...[
                  _buildLine(2, currentStep),
                  _buildStep(3, 'Active', Icons.play_circle_filled_rounded, currentStep),
                  _buildLine(3, currentStep),
                  _buildStep(4, 'Return Req', Icons.assignment_return_rounded, currentStep),
                  _buildLine(4, currentStep),
                  _buildStep(5, 'Returned', Icons.check_circle_rounded, currentStep),
                ] else ...[
                  _buildLine(2, currentStep),
                  _buildStep(3, 'Completed', Icons.check_circle_rounded, currentStep),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int stepIndex, String label, IconData icon, int currentStep) {
    bool isActive = stepIndex <= currentStep;
    bool isCurrent = stepIndex == currentStep;
    
    return Container(
      width: 70,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(isCurrent ? 12 : 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow: isCurrent ? [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)
              ] : [],
            ),
            child: Icon(
              icon,
              size: isCurrent ? 24 : 20,
              color: isActive ? Colors.white : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              color: isActive ? AppColors.primaryDark : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLine(int stepIndex, int currentStep) {
    bool isActive = stepIndex < currentStep;
    return Container(
      width: 30,
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
