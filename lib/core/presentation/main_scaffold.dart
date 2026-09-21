import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../theme/app_colors.dart';
import 'radial_share_menu.dart';
import '../data/repositories/notification_repository.dart';
import 'dart:async';
class MainScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin {

  bool _isShareMenuOpen = false;
  late AnimationController _shareMenuController;
  final _notificationRepo = NotificationRepository();
  StreamSubscription? _notificationSubscription;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _shareMenuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _initNotifications();
  }

  void _initNotifications() async {
    final notifs = await _notificationRepo.getNotifications();
    if (mounted) {
      setState(() {
        _unreadCount = notifs.where((n) => !n.isRead).length;
      });
    }

    _notificationSubscription = _notificationRepo.getNotificationStream().listen((events) {
      if (events.isNotEmpty) {
        final unread = events.where((n) => n['is_read'] == false).toList();
        if (unread.length > _unreadCount && mounted) {
            final newNotif = unread.first;
            _showNotificationToast(newNotif);
        }
        if (mounted) {
          setState(() {
            _unreadCount = unread.length;
          });
        }
      }
    });
  }

  void _showNotificationToast(Map<String, dynamic> notif) {
    if (!mounted) return;
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -100.0, end: 0.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () {
                widget.navigationShell.goBranch(2);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active, color: AppColors.primary),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif['title'] ?? 'New Notification',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          SizedBox(height: 4),
                          Text(
                            notif['message'] ?? '',
                            style: TextStyle(color: Colors.grey[700], fontSize: 11),
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
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _shareMenuController.dispose();
    super.dispose();
  }

  void _toggleShareMenu() {
    setState(() {
      _isShareMenuOpen = !_isShareMenuOpen;
      if (_isShareMenuOpen) {
        _shareMenuController.forward();
      } else {
        _shareMenuController.reverse();
      }
    });
  }

  void _onTapNav(int index) {
    if (_isShareMenuOpen) {
      _toggleShareMenu();
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          widget.navigationShell,
          if (_isShareMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleShareMenu,
                child: Container(color: Colors.transparent),
              ),
            ),
          RadialShareMenu(
            isOpen: _isShareMenuOpen,
            controller: _shareMenuController,
            onClose: _toggleShareMenu,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildLiquidNavBar(),
          ),
          Positioned(
            bottom: 36,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: _buildCenterFAB(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidNavBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double tabWidth = constraints.maxWidth / 5;
                final int currentIndex = widget.navigationShell.currentIndex;
                final int positionIndex = currentIndex < 2 ? currentIndex : currentIndex + 1;

                return Stack(
                  children: [
                    // Elastic Water Drop Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut, // Liquid water drop squish
                      top: 8,
                      bottom: 8,
                      left: positionIndex * tabWidth + (tabWidth * 0.15),
                      width: tabWidth * 0.7,
                      child: Container(
                        decoration: BoxDecoration(
                          // Fusion of frosted white and ShareNest Green
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.8),
                              AppColors.primary.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Icons overlay
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.home_filled, Icons.home_outlined, 'Home', tabWidth),
                        _buildNavItem(1, CupertinoIcons.search, CupertinoIcons.search, 'Explore', tabWidth),
                        SizedBox(width: tabWidth), // Space for FAB
                        _buildNavItem(2, Icons.notifications, Icons.notifications_none, 'Activity', tabWidth, badgeCount: _unreadCount),
                        _buildNavItem(3, Icons.person, Icons.person_outline, 'Profile', tabWidth),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, double width, {int badgeCount = 0}) {
    final isActive = widget.navigationShell.currentIndex == index;
    return SizedBox(
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTapNav(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
                  size: 26,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.urgent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFAB() {
    return GestureDetector(
      onTap: _toggleShareMenu,
      child: AnimatedBuilder(
        animation: _shareMenuController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _shareMenuController.value * (3.14159 / 4),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                // Same fusion aesthetic for FAB
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: Colors.white.withValues(alpha: 0.65), size: 32),
            ),
          );
        },
      ),
    );
  }
}
