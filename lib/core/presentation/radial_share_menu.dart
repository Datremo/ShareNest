import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';

class RadialShareMenu extends StatelessWidget {
  final bool isOpen;
  final AnimationController controller;
  final VoidCallback onClose;

  const RadialShareMenu({
    super.key,
    required this.isOpen,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.value == 0.0 && !isOpen) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final blurValue = controller.value * 8.0;
        final opacityValue = controller.value;

        return Stack(
          children: [
            // Blur Background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
                child: Container(
                  color: AppColors.background.withValues(alpha: opacityValue * 0.4),
                ),
              ),
            ),

            _buildActionItem(
              context,
              angle: -math.pi / 2 - (math.pi / 3.5), // Top Left (Lend)
              distance: 135,
              icon: Icons.eco, // Leaf/Lend icon approximation
              label: 'Lend',
              color: AppColors.borrow, // Green
              route: '/create_post?type=lend',
            ),
            _buildActionItem(
              context,
              angle: -math.pi / 2, // Top (Need It Now)
              distance: 145,
              icon: Icons.bolt_rounded,
              label: 'Need It Now',
              color: const Color(0xFFE53935), // Red
              route: '/create_urgent_request',
            ),
            _buildActionItem(
              context,
              angle: -math.pi / 2 + (math.pi / 3.5), // Top Right (Give)
              distance: 135,
              icon: Icons.card_giftcard,
              label: 'Give',
              color: AppColors.give, // Pink/Orange
              route: '/create_post?type=give',
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required double angle,
    required double distance,
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    final centerX = MediaQuery.of(context).size.width / 2;
    // Base Y is the FAB's center Y. Bottom is 36, FAB is 56, so center is bottom + 28 = 64 from bottom.
    final bottomOffset = 64.0;

    // Spring physics animation value
    final CurvedAnimation curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    );

    // Calculate position
    final startX = centerX;
    final startY = MediaQuery.of(context).size.height - bottomOffset;

    final endX = centerX + (math.cos(angle) * distance);
    final endY = startY + (math.sin(angle) * distance);

    final currentX = startX + ((endX - startX) * curve.value);
    final currentY = startY + ((endY - startY) * curve.value);

    return Positioned(
      left: currentX - 32, // Offset by half of item width
      top: currentY - 32,
      child: Transform.scale(
        scale: curve.value,
        child: Opacity(
          opacity: controller.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(icon, color: color, size: 30),
                  onPressed: () {
                    onClose();
                    GoRouter.of(context).push(route);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
