import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_colors.dart';

class MeshBackground extends StatefulWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base color
        Container(color: AppColors.background),

        // Animated Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _MeshPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),

        // Content on top
        widget.child,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double animationValue;

  _MeshPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Blob 1: Top Right (Primary Green)
    paint.color = AppColors.primary.withValues(alpha: 0.15);
    final center1 = Offset(
      size.width * 0.8 + math.sin(animationValue * math.pi * 2) * 50,
      size.height * 0.2 + math.cos(animationValue * math.pi * 2) * 50,
    );
    canvas.drawCircle(center1, size.width * 0.5, paint);

    // Blob 2: Bottom Left (Blue/Secondary)
    paint.color = AppColors.exchange.withValues(alpha: 0.1);
    final center2 = Offset(
      size.width * 0.2 + math.cos(animationValue * math.pi * 2) * 60,
      size.height * 0.8 + math.sin(animationValue * math.pi * 2) * 60,
    );
    canvas.drawCircle(center2, size.width * 0.6, paint);

    // Blob 3: Center Left (Warning/Warmth)
    paint.color = AppColors.warning.withValues(alpha: 0.08);
    final center3 = Offset(
      size.width * 0.1 + math.sin(animationValue * math.pi * 2 + math.pi) * 40,
      size.height * 0.4 + math.cos(animationValue * math.pi * 2 + math.pi) * 40,
    );
    canvas.drawCircle(center3, size.width * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
