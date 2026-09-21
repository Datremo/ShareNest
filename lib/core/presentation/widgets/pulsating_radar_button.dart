import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PulsatingRadarButton extends StatefulWidget {
  final VoidCallback onTap;

  const PulsatingRadarButton({super.key, required this.onTap});

  @override
  State<PulsatingRadarButton> createState() => _PulsatingRadarButtonState();
}

class _PulsatingRadarButtonState extends State<PulsatingRadarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radar pulse 1
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_controller.value * 0.8),
                  child: Opacity(
                    opacity: 1.0 - _controller.value,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.urgent.withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Inner dot
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.urgent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.urgent,
                    blurRadius: 6,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
            // Label
            const Positioned(
              bottom: 0,
              child: Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.urgent,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
