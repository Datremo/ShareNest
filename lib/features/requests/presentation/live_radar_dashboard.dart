import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/models/urgent_request.dart';
import 'package:timeago/timeago.dart' as timeago;

class UrgentRequestWithProfile {
  final UrgentRequest request;
  final Map<String, dynamic> profile;

  UrgentRequestWithProfile(this.request, this.profile);
}

enum UrgencyLevel { now, soon, flexible }

class LiveRadarDashboardPage extends StatefulWidget {
  const LiveRadarDashboardPage({super.key});

  @override
  State<LiveRadarDashboardPage> createState() => _LiveRadarDashboardPageState();
}

class _LiveRadarDashboardPageState extends State<LiveRadarDashboardPage> {
  bool _isLoading = true;
  List<UrgentRequestWithProfile> _urgentRequests = [];
  RealtimeChannel? _requestsChannel;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtime();
  }

  void _setupRealtime() {
    _requestsChannel = Supabase.instance.client
      .channel('public:urgent_requests')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'urgent_requests',
        callback: (payload) {
          _loadData();
        }
      )
      .subscribe();
  }

  Future<void> _loadData() async {
    try {
      final data = await Supabase.instance.client
          .from('urgent_requests')
          .select('*, profiles(*)')
          .eq('status', 'ACTIVE')
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _urgentRequests = (data as List).map((e) => UrgentRequestWithProfile(
            UrgentRequest.fromJson(e),
            e['profiles'] as Map<String, dynamic>? ?? {},
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _requestsChannel?.unsubscribe();
    super.dispose();
  }

  UrgencyLevel _getUrgencyLevel(String? neededBy) {
    if (neededBy == null) return UrgencyLevel.flexible;
    final lower = neededBy.toLowerCase();
    if (lower.contains('asap') || lower.contains('now') || lower.contains('immediately')) {
      return UrgencyLevel.now;
    } else if (lower.contains('today') || lower.contains('few hours') || lower.contains('soon') || lower.contains('hour')) {
      return UrgencyLevel.soon;
    }
    return UrgencyLevel.flexible;
  }

  Color _getUrgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.now: return const Color(0xFFFF4B4B);
      case UrgencyLevel.soon: return const Color(0xFFFF9500);
      case UrgencyLevel.flexible: return const Color(0xFF34C759);
    }
  }

  String _getUrgencyLabel(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.now: return 'Need it now';
      case UrgencyLevel.soon: return 'Need it soon';
      case UrgencyLevel.flexible: return 'Flexible';
    }
  }

  IconData _getUrgencyIcon(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.now: return Icons.bolt_rounded;
      case UrgencyLevel.soon: return Icons.access_time_filled;
      case UrgencyLevel.flexible: return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _urgentRequests.where((wrapper) {
      final req = wrapper.request;
      if (_selectedFilter == 'All') return true;
      final level = _getUrgencyLevel(req.neededBy);
      if (_selectedFilter == 'Need it now' && level == UrgencyLevel.now) return true;
      if (_selectedFilter == 'Soon' && level == UrgencyLevel.soon) return true;
      if (_selectedFilter == 'Flexible' && level == UrgencyLevel.flexible) return true;
      return false;
    }).toList();

    int countNow = _urgentRequests.where((r) => _getUrgencyLevel(r.request.neededBy) == UrgencyLevel.now).length;
    int countSoon = _urgentRequests.where((r) => _getUrgencyLevel(r.request.neededBy) == UrgencyLevel.soon).length;
    int countFlex = _urgentRequests.where((r) => _getUrgencyLevel(r.request.neededBy) == UrgencyLevel.flexible).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
              child: const Icon(CupertinoIcons.back, color: Colors.black87, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
              child: Stack(
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 24),
                  Positioned(
                    right: 2, top: 2,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/sunset_balcony.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.95)],
              stops: const [0.0, 0.4],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Banner image - commented out since we have a global background now, but we can keep a gradient header if we want.
                    // Actually, the previous explore_banner is nice. Let's keep the explore_banner at the top but with a transparent blend.
                    Container(
                      height: 320,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/explore_banner.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.9)],
                      ),
                    ),
                  ),
                ),
                // Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Text('Live Requests', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF064B34))),
                          const SizedBox(width: 8),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 8)])),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text('Real people. Real needs.\nHelp your neighbours right now.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4A6B5D))),
                    ),
                    const SizedBox(height: 24),
                    
                    // Map/List Toggle
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(children: [const Icon(Icons.map_rounded, size: 16, color: Colors.grey), const SizedBox(width: 8), Text('Map View', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey))]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: const Color(0xFF064B34), borderRadius: BorderRadius.circular(26)),
                              child: Row(children: [const Icon(Icons.format_list_bulleted_rounded, size: 16, color: Colors.white), const SizedBox(width: 8), Text('List View', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white))]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    // Radar Summary Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B2117),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: const Color(0xFF0B2117).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Row(
                          children: [
                            // Graphic
                            SizedBox(
                              width: 80, height: 80,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 1))),
                                  Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1))),
                                  const Icon(Icons.home_rounded, color: Colors.greenAccent, size: 24),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('${_urgentRequests.length}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                      const SizedBox(width: 8),
                                      Text('Live Requests Nearby', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                  Text('People in your neighbourhood\nneed help right now', style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
                                  const SizedBox(height: 12),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildMiniBadge(countNow, 'Need it now', const Color(0xFFFF4B4B)),
                                        const SizedBox(width: 8),
                                        _buildMiniBadge(countSoon, 'Soon', const Color(0xFFFF9500)),
                                        const SizedBox(width: 8),
                                        _buildMiniBadge(countFlex, 'Flexible', const Color(0xFF34C759)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                )
              ],
            ),
          ),
          
          // Filters Sticky Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 60.0,
              maxHeight: 60.0,
              child: Container(
                color: Colors.transparent, // transparent to see background
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      _buildFilterChip('Need it now', Icons.bolt_rounded, color: const Color(0xFFFF4B4B)),
                      _buildFilterChip('Soon', Icons.access_time_filled, color: const Color(0xFFFF9500)),
                      _buildFilterChip('Flexible', Icons.eco_rounded, color: const Color(0xFF34C759)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[300]!)),
                        child: Row(children: [const Icon(Icons.location_on_rounded, size: 14, color: Colors.black87), const SizedBox(width: 4), Text('Nearest', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)), const Icon(Icons.keyboard_arrow_down, size: 16)]),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // List content
          _isLoading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFF064B34)))))
              : filteredRequests.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final wrapper = filteredRequests[index];
                          return _buildRequestCard(wrapper.request, wrapper.profile);
                        },
                        childCount: filteredRequests.length,
                      ),
                    ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(label.contains('now') ? Icons.bolt_rounded : (label.contains('Soon') ? Icons.access_time_filled : Icons.eco_rounded), size: 10, color: color),
          const SizedBox(width: 4),
          Text('$count $label', style: GoogleFonts.inter(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData? icon, {Color? color}) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF064B34) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF064B34) : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: isSelected ? Colors.white : color), const SizedBox(width: 6)],
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(UrgentRequest req, Map<String, dynamic> profile) {
    final level = _getUrgencyLevel(req.neededBy);
    final color = _getUrgencyColor(level);
    final label = _getUrgencyLabel(level);
    final icon = _getUrgencyIcon(level);
    
    final avatar = profile['avatar_url'] as String?;
    final name = profile['full_name'] as String? ?? 'Neighbor';
    final location = profile['location_name'] as String? ?? 'Nearby';

    return GestureDetector(
      onTap: () => context.push('/urgent_request_detail/${req.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (level == UrgencyLevel.now) BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2),
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: level == UrgencyLevel.now ? color.withValues(alpha: 0.3) : Colors.transparent, width: level == UrgencyLevel.now ? 1 : 0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              Container(
                width: 90, height: 110,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image: req.imageUrl != null ? DecorationImage(image: NetworkImage(req.imageUrl!), fit: BoxFit.cover) : null,
                ),
                child: req.imageUrl == null
                    ? const Icon(Icons.image, color: Colors.grey)
                    : Stack(
                        children: [
                          Positioned(
                            bottom: 6, left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.photo_library_rounded, size: 10, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('1 photo', style: GoogleFonts.inter(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 12, color: color),
                              const SizedBox(width: 4),
                              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                            ],
                          ),
                        ),
                        // Time ago
                        if (req.createdAt != null)
                          Row(
                            children: [
                              Icon(Icons.history_rounded, size: 12, color: color.withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text(timeago.format(req.createdAt!), style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                            ],
                          )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(req.title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(req.description ?? 'Need for ${req.duration ?? 'a while'}.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          backgroundColor: Colors.grey[300],
                          child: avatar == null ? Text(name[0], style: const TextStyle(fontSize: 10, color: Colors.grey)) : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text('$location · ~${req.radiusKm?.toStringAsFixed(1) ?? '2.0'} km', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_rounded, size: 12, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('View Request', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(width: 2),
                              const Icon(Icons.chevron_right, size: 12, color: Colors.red),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, color: Colors.grey[300], size: 80),
          const SizedBox(height: 24),
          Text('All quiet nearby', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 8),
          Text('No requests found for this filter.', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
