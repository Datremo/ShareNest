import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/request_repository.dart';
import '../../../core/data/models/item_request.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';

class TrackingDashboardPage extends StatefulWidget {
  const TrackingDashboardPage({super.key});

  @override
  State<TrackingDashboardPage> createState() => _TrackingDashboardPageState();
}

class _TrackingDashboardPageState extends State<TrackingDashboardPage> with SingleTickerProviderStateMixin {
  final _requestRepo = RequestRepository();
  bool _isLoading = true;

  List<Map<String, dynamic>> _myRequests = [];
  List<Map<String, dynamic>> _incomingRequests = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _requestRepo.getMyRequestsWithListings(),
        _requestRepo.getIncomingRequestsWithListings(),
      ]);
      setState(() {
        _myRequests = futures[0];
        _incomingRequests = futures[1];
      });
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF7F9FC), // Ultra-clean subtle blue-white
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.5),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tracking Interface',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                // Glowing Background Orbs for 2030s feel
                Positioned(
                  top: 100, right: -50,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      boxShadow: [BoxShadow(blurRadius: 100, color: AppColors.primary.withValues(alpha: 0.2))],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100, left: -50,
                  child: Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withValues(alpha: 0.05),
                      boxShadow: [BoxShadow(blurRadius: 100, color: Colors.green.withValues(alpha: 0.1))],
                    ),
                  ),
                ),
                // Main Content
                Column(
                  children: [
                    const SizedBox(height: 100), // Appbar spacing
                    _buildAnimatedKPIs(),
                    const SizedBox(height: 24),
                    _buildPillTabs(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildActiveLends(), // Sharing
                          _buildActiveBorrows(), // Borrowing
                          _buildPendingRequests(), // Pending
                          _buildHistory(), // Completed
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildAnimatedKPIs() {
    final activeStates = ['ACCEPTED', 'ACTIVE', 'RETURN_REQUESTED'];
    int activeLendsCount = _incomingRequests.where((r) => activeStates.contains(r['status'])).length;
    int activeBorrowsCount = _myRequests.where((r) => activeStates.contains(r['status'])).length;
    int totalImpact = activeLendsCount + activeBorrowsCount + _myRequests.where((r)=> r['status'] == 'COMPLETED').length + _incomingRequests.where((r)=> r['status'] == 'COMPLETED').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FuturisticKPICard(
                  label: 'Sharing',
                  value: activeLendsCount,
                  icon: Icons.upload_rounded,
                  color: AppColors.primary,
                  delayMs: 100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FuturisticKPICard(
                  label: 'Borrowing',
                  value: activeBorrowsCount,
                  icon: Icons.download_rounded,
                  color: AppColors.borrow,
                  delayMs: 200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FuturisticKPICard(
            label: 'Total Community Impact',
            value: totalImpact,
            icon: Icons.public,
            color: Colors.teal,
            delayMs: 300,
            isHorizontal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPillTabs() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        tabs: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Tab(text: 'Sharing')),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Tab(text: 'Borrowing')),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Tab(text: 'Pending')),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Tab(text: 'History')),
        ],
      ),
    );
  }

  Widget _buildActiveBorrows() {
    final activeStates = ['ACCEPTED', 'ACTIVE', 'RETURN_REQUESTED'];
    final active = _myRequests.where((r) => activeStates.contains(r['status'])).toList();
    if (active.isEmpty) return _buildEmptyState('No Active Borrows', 'Your borrowing pipeline is clear.', Icons.shopping_bag_outlined);
    return _buildList(active, isOwner: false);
  }

  Widget _buildActiveLends() {
    final activeStates = ['ACCEPTED', 'ACTIVE', 'RETURN_REQUESTED'];
    final active = _incomingRequests.where((r) => activeStates.contains(r['status'])).toList();
    if (active.isEmpty) return _buildEmptyState('No Active Shares', 'Your sharing pipeline is clear.', Icons.handshake_outlined);
    return _buildList(active, isOwner: true);
  }

  Widget _buildPendingRequests() {
    final pendingMy = _myRequests.where((r) => r['status'] == 'PENDING').map((e) => {...e, 'isOwner': false});
    final pendingIncoming = _incomingRequests.where((r) => r['status'] == 'PENDING').map((e) => {...e, 'isOwner': true});
    final pending = [...pendingIncoming, ...pendingMy];
    pending.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    if (pending.isEmpty) return _buildEmptyState('No Pending Requests', 'All caught up!', Icons.check_circle_outline);
    return _buildMixedList(pending);
  }

  Widget _buildHistory() {
    final historyStates = ['COMPLETED', 'REJECTED', 'CANCELLED'];
    final historyMy = _myRequests.where((r) => historyStates.contains(r['status'])).map((e) => {...e, 'isOwner': false});
    final historyIncoming = _incomingRequests.where((r) => historyStates.contains(r['status'])).map((e) => {...e, 'isOwner': true});
    final history = [...historyIncoming, ...historyMy];
    history.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    if (history.isEmpty) return _buildEmptyState('No History', 'Data logs are empty.', Icons.history);
    return _buildMixedList(history);
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.6),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {required bool isOwner}) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildFuturisticTrackCard(items[index], isOwner: isOwner),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMixedList(List<Map<String, dynamic>> items) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildFuturisticTrackCard(items[index], isOwner: items[index]['isOwner']),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticTrackCard(Map<String, dynamic> requestMap, {required bool isOwner}) {
    final req = ItemRequest.fromJson(requestMap);
    final listingData = requestMap['listing'] as Map<String, dynamic>? ?? {};
    final listing = listingData.isNotEmpty ? Listing.fromJson(listingData) : null;
    
    Color statusColor;
    switch (req.status) {
      case 'PENDING': statusColor = Colors.orange; break;
      case 'ACCEPTED': statusColor = Colors.blue; break;
      case 'ACTIVE': statusColor = Colors.green; break;
      case 'RETURN_REQUESTED': statusColor = Colors.purple; break;
      case 'COMPLETED': statusColor = Colors.grey; break;
      case 'REJECTED': statusColor = Colors.red; break;
      case 'CANCELLED': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () async {
        if (isOwner) {
          final requesterMap = requestMap['profiles'] as Map<String, dynamic>? ?? {};
          final requester = requesterMap.isNotEmpty ? Profile.fromJson(requesterMap) : null;
          await context.push('/owner_request_detail', extra: {
            'request': req, 
            'listing': listing,
            if (requester != null) 'requester': requester,
          });
        } else {
          await context.push('/requester_request_detail', extra: {
            'request': req,
            'listing': listing,
          });
        }
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                    ),
                    child: Icon(isOwner ? Icons.upload_rounded : Icons.download_rounded, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing?.title ?? 'Unknown Item',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(isOwner ? Icons.outbox : Icons.inbox, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              isOwner ? 'Sharing' : 'Borrowing',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          req.status.replaceAll('_', ' '),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        req.createdAt != null ? DateFormat('MMM d').format(req.createdAt!) : '',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FuturisticKPICard extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final int delayMs;
  final bool isHorizontal;

  const _FuturisticKPICard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delayMs,
    this.isHorizontal = false,
  });

  @override
  State<_FuturisticKPICard> createState() => _FuturisticKPICardState();
}

class _FuturisticKPICardState extends State<_FuturisticKPICard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<int> _countAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _countAnim = IntTween(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }
  
  @override
  void didUpdateWidget(_FuturisticKPICard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _countAnim = IntTween(begin: _countAnim.value, end: widget.value).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _ctrl.value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: widget.color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: widget.isHorizontal
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.color,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 10)],
                              ),
                              child: Icon(widget.icon, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_countAnim.value}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primaryDark, height: 1)),
                                  const SizedBox(height: 4),
                                  Text(widget.label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: widget.color,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 10)],
                              ),
                              child: Icon(widget.icon, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 24),
                            Text('${_countAnim.value}', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.primaryDark, height: 1)),
                            const SizedBox(height: 6),
                            Text(widget.label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.3)),
                          ],
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
