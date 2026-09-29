import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/models/urgent_request.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/location/location_autocomplete_field.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/maps/sharenest_map.dart';
import 'dart:async';

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
  bool _isListView = false;
  String _selectedFilter = 'All';

  // New state variables
  int _searchRadiusMeters = 500;
  Set<UrgencyLevel> _activeFilters = {};
  UrgentRequestWithProfile? _selectedRequest;
  int _liveCount = 0;
  bool _showNewRequestToast = false;
  Timer? _toastTimer;
  geo.Position? _mapCenter;
  final TextEditingController _searchController = TextEditingController();

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
          if (payload.eventType == PostgresChangeEvent.insert) {
            _triggerToast();
          }
          _loadData();
        }
      )
      .subscribe();
  }

  void _triggerToast() {
    if (mounted) {
      setState(() => _showNewRequestToast = true);
      _toastTimer?.cancel();
      _toastTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showNewRequestToast = false);
      });
    }
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
    _searchController.dispose();
    _requestsChannel?.unsubscribe();
    _toastTimer?.cancel();
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

  String _getUrgencyLabel(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.now: return 'Need it now';
      case UrgencyLevel.soon: return 'Need it soon';
      case UrgencyLevel.flexible: return 'Flexible';
    }
  }

  Color _getUrgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.now: return const Color(0xFFFF4B4B);
      case UrgencyLevel.soon: return const Color(0xFFFF9500);
      case UrgencyLevel.flexible: return const Color(0xFF34C759);
    }
  }

  List<UrgentRequestWithProfile> get _filteredRequests {
    return _urgentRequests.where((wrapper) {
      if (_activeFilters.isEmpty) return true; // Show all if none selected
      final level = _getUrgencyLevel(wrapper.request.neededBy);
      return _activeFilters.contains(level);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRequests;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background content (Map or List)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _isListView ? _buildListView() : _buildMapView(filtered),
          ),

          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildHeader(),
          ),

          // Map/List Toggle & Radius (Map Mode Only)
          if (!_isListView)
            Positioned(
              top: 100, left: 16, right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTogglePill(),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildRadiusSelector(),
                ],
              ),
            ),


          // Toast
          if (_showNewRequestToast)
            Positioned(
              top: 160, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text('+1 new request nearby', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Sheet
          if (!_isListView && _selectedRequest != null)
            Positioned(
              bottom: 24, left: 16, right: 16,
              child: _buildSelectedCard(_selectedRequest!),
            ),

          // Bottom Legend Filters (only show if no request is selected in map mode)
          if (!_isListView && _selectedRequest == null)
            Positioned(
              bottom: 32, left: 16, right: 16,
              child: _buildInteractiveFilters(),
            ),

          // Empty state overlay
          if (filtered.isEmpty && !_isLoading && !_isListView)
            Positioned(
              bottom: 120, left: 24, right: 24,
              child: _buildEmptyState(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(CupertinoIcons.back, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Live Requests', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF34C759), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text('Live Â· $_liveCount requests nearby', 
                        key: ValueKey(_liveCount),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
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

  Widget _buildTogglePill() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(icon: CupertinoIcons.map_fill, label: 'Map View', isSelected: !_isListView, onTap: () => setState(() => _isListView = false)),
          _buildToggleOption(icon: CupertinoIcons.list_bullet, label: 'List View', isSelected: _isListView, onTap: () => setState(() => _isListView = true)),
        ],
      ),
    );
  }

  Widget _buildToggleOption({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4332) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSelector() {
    final radii = [500, 1000, 2000, 5000, 10000000];
    final labels = ['500m', '1km', '2km', '5km', 'All'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(radii.length, (index) {
          final isSelected = _searchRadiusMeters == radii[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _searchRadiusMeters = radii[index];
                _selectedRequest = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1B4332) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(labels[index], style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              )),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInteractiveFilters() {
    int countNow = _urgentRequests.where((r) => _getUrgencyLevel(r.request.neededBy) == UrgencyLevel.now).length;
    int countSoon = _urgentRequests.where((r) => _getUrgencyLevel(r.request.neededBy) == UrgencyLevel.soon).length;
    int countFlex = _urgentRequests.where((r) => _getUrgencyLevel(r.request.neededBy) == UrgencyLevel.flexible).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFilterBadge(countNow, UrgencyLevel.now, 'Need it now'),
          _buildFilterBadge(countSoon, UrgencyLevel.soon, 'Need soon'),
          _buildFilterBadge(countFlex, UrgencyLevel.flexible, 'Flexible'),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(int count, UrgencyLevel level, String title) {
    final color = _getUrgencyColor(level);
    final isActive = _activeFilters.isEmpty || _activeFilters.contains(level);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_activeFilters.contains(level)) {
            _activeFilters.remove(level);
          } else {
            _activeFilters.add(level);
          }
          _selectedRequest = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(count.toString(), style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Text(title, style: GoogleFonts.inter(
              color: isActive ? Colors.white : Colors.white54, 
              fontSize: 11, 
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(List<UrgentRequestWithProfile> filtered) {
    final mapItems = filtered.where((r) => r.request.lat != null && r.request.lng != null).map((r) => {
      'id': r.request.id,
      'title': r.request.title,
      'urgency': _getUrgencyLevel(r.request.neededBy).name,
      'lat': r.request.lat,
      'lng': r.request.lng,
      'wrapper': r,
    }).toList();

    return ShareNestMap(
      mode: MapMode.liveRequests,
      initialCenter: _mapCenter,
      items: mapItems,
      searchRadiusMeters: _searchRadiusMeters.toDouble(),
      selectedItemId: _selectedRequest?.request.id,
      onItemsInViewChanged: (count) {
        if (mounted && _liveCount != count) {
          setState(() => _liveCount = count);
        }
      },
      onMapTapped: () {
        if (_selectedRequest != null) {
          setState(() => _selectedRequest = null);
        }
      },
      onMarkerTapped: (data) {
        final req = data['wrapper'] as UrgentRequestWithProfile;
        if (_selectedRequest?.request.id == req.request.id) {
          setState(() => _selectedRequest = null);
        } else {
          setState(() => _selectedRequest = req);
        }
      },
    );
  }


  Widget _buildSelectedCard(UrgentRequestWithProfile wrapper) {
    final urgency = _getUrgencyLevel(wrapper.request.neededBy);
    final color = _getUrgencyColor(urgency);
    final label = _getUrgencyLabel(urgency);
    
    DateTime? postedTime;
    if (wrapper.request.createdAt != null) {
      postedTime = wrapper.request.createdAt!;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 5)],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => setState(() => _selectedRequest = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(wrapper.request.title, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniInfo(Icons.location_on, _getDistanceText(wrapper.request), Colors.black54),
                const SizedBox(width: 16),
                _buildMiniInfo(Icons.access_time, wrapper.request.neededBy ?? 'Anytime', Colors.black54),
              ],
            ),
            if (postedTime != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.history, size: 12, color: Colors.black45),
                  const SizedBox(width: 6),
                  Text('Posted ${timeago.format(postedTime)}', style: GoogleFonts.inter(color: Colors.black45, fontSize: 12)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/urgent_request_detail/${wrapper.request.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332), // Dark green color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('View Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Approximate location shown until help is accepted', style: GoogleFonts.inter(color: Colors.black45, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

Widget _buildListView() {
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

    return Container(
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
                    // Banner image
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
                      child: _buildTogglePill(),
                    ),
                    const SizedBox(height: 16),
                    // Search Bar inside List View
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSearchBar(),
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
    final name = profile['display_name'] as String? ?? 'Neighbor';
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
                              Text(_getDistanceText(req), style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
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

  
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _openLocationSearch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8),
            Text('Search location...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _openLocationSearch() async {
    final TextEditingController searchController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              LocationAutocompleteField(
                controller: searchController,
                onSelected: (suggestion) {
                  setState(() {
                    _mapCenter = geo.Position(
                      latitude: suggestion.lat,
                      longitude: suggestion.lon,
                      timestamp: DateTime.now(),
                      accuracy: 0.0, altitude: 0.0, altitudeAccuracy: 0.0, heading: 0.0, headingAccuracy: 0.0, speed: 0.0, speedAccuracy: 0.0
                    );
                  });
                  Navigator.pop(context);
                },
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
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
          Text('All quiet nearby', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 8),
          Text('No requests found for this filter.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  IconData _getUrgencyIcon(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.now: return Icons.bolt;
      case UrgencyLevel.soon: return Icons.access_time;
      case UrgencyLevel.flexible: return Icons.eco;
    }
  }

  String _getDistanceText(UrgentRequest req) {
    if (_mapCenter != null && req.lat != null && req.lng != null) {
      double distanceInMeters = geo.Geolocator.distanceBetween(
        _mapCenter!.latitude,
        _mapCenter!.longitude,
        req.lat!,
        req.lng!,
      );
      if (distanceInMeters < 1000) {
        return '~${distanceInMeters.round()} m away';
      } else {
        return '~${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
      }
    }
    return 'Nearby';
  }
} // End of class

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

