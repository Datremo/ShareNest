import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../notifications/notification_router.dart';

class InAppNotification {
  static void show(BuildContext context, RemoteMessage message) {
    if (message.notification == null) return;
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _SlideDownNotification(
        message: message,
        onDismiss: () => overlayEntry.remove(),
        onTap: () {
          overlayEntry.remove();
          NotificationRouter.handleNotificationTap(context, message);
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _SlideDownNotification extends StatefulWidget {
  final RemoteMessage message;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _SlideDownNotification({
    required this.message,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_SlideDownNotification> createState() => _SlideDownNotificationState();
}

class _SlideDownNotificationState extends State<_SlideDownNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Slide in
    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    final eventType = widget.message.data['event_type'];
    if (eventType == 'URGENT_REQUEST_BROADCAST') return Icons.campaign_rounded;
    if (eventType == 'MESSAGE_RECEIVED') return Icons.forum_rounded;
    if (eventType?.contains('ACCEPTED') ?? false) return Icons.check_circle_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _getAccentColor() {
    final eventType = widget.message.data['event_type'];
    if (eventType == 'URGENT_REQUEST_BROADCAST') return Colors.redAccent;
    if (eventType == 'MESSAGE_RECEIVED') return Colors.blueAccent;
    if (eventType?.contains('ACCEPTED') ?? false) return Colors.greenAccent;
    return Colors.purpleAccent;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.message.notification?.title ?? 'Notification';
    final body = widget.message.notification?.body ?? '';
    final accentColor = _getAccentColor();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _offsetAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _controller.reverse().then((_) => widget.onDismiss());
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIcon(), color: accentColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
