import 'package:flutter/material.dart';

class AnimatedCheckmark extends StatefulWidget {
  final Color color;
  final double size;
  final double strokeWidth;

  const AnimatedCheckmark({
    super.key,
    this.color = Colors.green,
    this.size = 80.0,
    this.strokeWidth = 6.0,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _CheckmarkPainter(
              progress: _controller.value, // use linear progress for drawing path
              springValue: _animation.value, // use elastic for scale/bounce
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final double springValue;
  final Color color;
  final double strokeWidth;

  _CheckmarkPainter({
    required this.progress,
    required this.springValue,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Draw circle
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    
    // Circle draws linearly over the first 50% of the animation
    final circleProgress = (progress * 2).clamp(0.0, 1.0);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start at top
      3.14159 * 2 * circleProgress,
      false,
      paint,
    );

    // Draw checkmark
    if (progress > 0.4) {
      final checkProgress = ((progress - 0.4) * 1.66).clamp(0.0, 1.0);
      
      // Use spring value for a popping scale effect on the checkmark
      final scale = springValue.clamp(0.0, 1.2);
      
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(scale);
      canvas.translate(-size.width / 2, -size.height / 2);
      final startPoint = Offset(size.width * 0.28, size.height * 0.52);
      final midPoint = Offset(size.width * 0.45, size.height * 0.68);
      final endPoint = Offset(size.width * 0.72, size.height * 0.35);

      path.moveTo(startPoint.dx, startPoint.dy);

      if (checkProgress < 0.5) {
        // Drawing first leg
        final legProgress = checkProgress * 2;
        path.lineTo(
          startPoint.dx + (midPoint.dx - startPoint.dx) * legProgress,
          startPoint.dy + (midPoint.dy - startPoint.dy) * legProgress,
        );
      } else {
        // First leg is drawn
        path.lineTo(midPoint.dx, midPoint.dy);
        
        // Drawing second leg
        final legProgress = (checkProgress - 0.5) * 2;
        path.lineTo(
          midPoint.dx + (endPoint.dx - midPoint.dx) * legProgress,
          midPoint.dy + (endPoint.dy - midPoint.dy) * legProgress,
        );
      }
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.springValue != springValue ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
