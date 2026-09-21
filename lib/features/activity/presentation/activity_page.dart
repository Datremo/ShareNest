import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:demo/core/data/models/app_notification.dart';
import 'package:demo/core/data/models/item_request.dart';
import 'package:demo/core/data/models/listing.dart';
import 'package:demo/core/data/models/profile.dart';
import 'package:demo/core/data/repositories/notification_repository.dart';
import 'package:demo/core/data/repositories/request_repository.dart';
import 'package:intl/intl.dart';
import 'package:demo/core/presentation/widgets/liquid_glass_widgets.dart';
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with TickerProviderStateMixin {
  final _requestRepo = RequestRepository();
  final _notificationRepo = NotificationRepository();
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSub;

  bool _isLoading = true;
  List<AppNotification> _notifications = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _loadData();
    
    _notificationSub = _notificationRepo.getNotificationStream().listen(
      (events) {
        if (mounted) {
          setState(() {
            if (events.isNotEmpty) {
              _notifications = events.map((e) => AppNotification.fromJson(e)).toList();
            }
          });
        }
      },
      onError: (e) {
        // Suppress websocket hot-restart errors from surfacing to the UI
        debugPrint("Supabase Stream Error: $e");
      },
    );
  }

  void _handleTabSelection(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      _markNotificationsAsRead();
    }
  }

  void _markNotificationsAsRead() {
    bool hasUnread = _notifications.any((n) => !n.isRead);
    if (hasUnread) {
      _notificationRepo.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) {
          if (!n.isRead) {
            return AppNotification(
              id: n.id,
              profileId: n.profileId,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
              data: n.data,
            );
          }
          return n;
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _requestRepo.getIncomingRequestsWithListings(),
        _requestRepo.getMyRequestsWithListings(),
        _notificationRepo.getNotifications(),
      ]);
      if (mounted) {
        setState(() {
          _incomingRequests = results[0] as List<Map<String, dynamic>>;
          _outgoingRequests = results[1] as List<Map<String, dynamic>>;
          
          if (_notifications.isEmpty) {
            _notifications = results[2] as List<AppNotification>;
          }
          _isLoading = false;
        });
        
        if (_currentIndex == 0) {
          _markNotificationsAsRead();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 140.0,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: FlexibleSpaceBar(
                              titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
                              title: const Text(
                                'Activity Hub',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              background: Container(color: Colors.transparent),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SegmentedControlDelegate(
                        currentIndex: _currentIndex,
                        onChanged: _handleTabSelection,
                      ),
                    ),
                    if (_currentIndex == 0) _buildNotificationsList(),
                    if (_currentIndex == 1) _buildRequestsList(true), // Incoming
                    if (_currentIndex == 2) _buildRequestsList(false), // Outgoing
                  ],
                ),
    );
  }

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState('No notifications yet', Icons.notifications_none),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final notif = _notifications[index];
            return StaggeredListItem(
              index: index,
              child: PhysicsCard(
                onTap: () {},
                child: _buildNotificationItem(notif),
              ),
            );
          },
          childCount: _notifications.length,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notif) {
    IconData icon;
    Color iconColor;
    switch (notif.type) {
      case 'request_received':
        icon = Icons.move_to_inbox_rounded;
        iconColor = const Color(0xFF007AFF);
        break;
      case 'request_approved':
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF34C759);
        break;
      case 'request_rejected':
        icon = Icons.cancel_rounded;
        iconColor = const Color(0xFFFF3B30);
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = const Color(0xFFA259FF);
    }

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconColor.withValues(alpha: 0.2), iconColor.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(notif.createdAt),
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notif.message,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6), 
                    fontSize: 14, 
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(bool isIncoming) {
    final requests = isIncoming ? _incomingRequests : _outgoingRequests;
    
    final sortedRequests = List<Map<String, dynamic>>.from(requests);
    sortedRequests.sort((a, b) {
      final aDate = DateTime.parse(a['created_at']);
      final bDate = DateTime.parse(b['created_at']);
      return bDate.compareTo(aDate);
    });

    if (sortedRequests.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(isIncoming ? 'No incoming requests' : 'No outgoing requests', Icons.swap_horiz),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final data = sortedRequests[index];
            final profileData = isIncoming ? data['profiles'] : data['listing']['profiles'];
            
            return StaggeredListItem(
              index: index,
              child: PhysicsCard(
                onTap: () {
                  final request = ItemRequest.fromJson(data);
                  final listing = Listing.fromJson(data['listing']);
                  final profile = Profile.fromJson(profileData);
                  if (isIncoming) {
                    context.push('/owner_request_detail', extra: {
                      'request': request,
                      'listing': listing,
                      'requester': profile,
                    });
                  } else {
                    context.push('/requester_request_detail', extra: {
                      'request': request,
                      'listing': listing,
                    });
                  }
                },
                child: _buildRequestItem(
                  request: ItemRequest.fromJson(data),
                  listing: Listing.fromJson(data['listing']),
                  profile: Profile.fromJson(profileData),
                  isIncoming: isIncoming,
                ),
              ),
            );
          },
          childCount: sortedRequests.length,
        ),
      ),
    );
  }

  Widget _buildRequestItem({
    required ItemRequest request,
    required Listing listing,
    required Profile profile,
    required bool isIncoming,
  }) {
    Color statusColor = _getStatusColor(request.status);
    
    return GlassCard(
      child: Row(
        children: [
          Hero(
            tag: 'listing_image_${listing.id}_${request.id}',
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.3),
                image: listing.imageUrls.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(listing.imageUrls.first),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: listing.imageUrls.isEmpty
                  ? const Icon(Icons.inventory_2_rounded, color: Colors.black38, size: 30)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Text(
                        request.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isIncoming ? "From: ${profile.displayName}" : "To: ${profile.displayName}",
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 12, color: Colors.black.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(
                      request.startDate != null && request.endDate != null
                          ? "${DateFormat('MMM d').format(request.startDate!)} - ${DateFormat('MMM d').format(request.endDate!)}"
                          : "Flexible Dates",
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFFF9500);
      case 'approved': return const Color(0xFF34C759);
      case 'rejected': return const Color(0xFFFF3B30);
      case 'completed': return const Color(0xFF007AFF);
      case 'handed_off': return const Color(0xFFA259FF);
      case 'returned': return const Color(0xFF32ADE6);
      default: return const Color(0xFF8E8E93);
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 100.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Icon(icon, size: 56, color: Colors.black.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}

// 2030s iOS 26 Segmented Control Delegate
class _SegmentedControlDelegate extends SliverPersistentHeaderDelegate {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  _SegmentedControlDelegate({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 80.0,
          color: Colors.white.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(child: _buildSegment('Alerts', 0)),
                Expanded(child: _buildSegment('Incoming', 1)),
                Expanded(child: _buildSegment('Outgoing', 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(String text, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onChanged(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCirc,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black.withValues(alpha: 0.5),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 80.0;
  @override
  double get minExtent => 80.0;
  @override
  bool shouldRebuild(covariant _SegmentedControlDelegate oldDelegate) {
    return oldDelegate.currentIndex != currentIndex;
  }
}
