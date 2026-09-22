import 'package:flutter/material.dart';
import 'package:demo/core/theme/app_colors.dart';

class AnimatedFlyingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final bool isPrimary;

  const AnimatedFlyingButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon = Icons.send_rounded,
    this.isPrimary = true,
  });

  @override
  State<AnimatedFlyingButton> createState() => _AnimatedFlyingButtonState();
}

class _AnimatedFlyingButtonState extends State<AnimatedFlyingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flyUpAnimation;
  late Animation<double> _flyRightAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _flyUpAnimation = Tween<double>(begin: 0, end: -150).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInBack),
    );

    _flyRightAnimation = Tween<double>(begin: 0, end: 150).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInBack),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInBack),
    );
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onPressed();
        // Reset after a short delay in case the page stays alive
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _controller.reset();
            setState(() {
              _isAnimating = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_flyRightAnimation.value, _flyUpAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: GestureDetector(
                onTap: _handlePress,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.isPrimary
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: widget.isPrimary
                          ? Colors.transparent
                          : AppColors.primary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (widget.isPrimary)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: _isAnimating
                          ? Icon(
                              widget.icon,
                              key: const ValueKey('icon'),
                              color: widget.isPrimary
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 28,
                            )
                          : Row(
                              key: const ValueKey('text'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: widget.isPrimary
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  widget.icon,
                                  size: 20,
                                  color: widget.isPrimary
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
