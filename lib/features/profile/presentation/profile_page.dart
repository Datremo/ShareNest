import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/models/profile.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/repositories/request_repository.dart';
import '../../../core/theme/app_colors.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final _profileRepo = ProfileRepository();
  final _listingRepo = ListingRepository();
  final _requestRepo = RequestRepository();

  bool _isLoading = true;
  Profile? _profile;
  Map<String, int> _stats = {};
  List<Listing> _activeListings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = widget.userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final profile = await _profileRepo.getProfile(userId);
      final stats = await _profileRepo.getProfileStats(userId);
      final allMyListings = await _listingRepo.getUserListings();

      if (mounted) {
        setState(() {
          _profile = profile;
          _stats = stats;
          // Filter to active ones for "Active Now" section
          _activeListings = allMyListings.where((l) => l.status.toLowerCase() == 'available' || l.status.toLowerCase() == 'active' || l.status.toLowerCase() == 'reserved').toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildHeaderAndProfileInfo(),
            
            _buildCommunityImpact(),
            const SizedBox(height: 20),
            _buildDashboardButtons(context),
            const SizedBox(height: 20),
            if (_activeListings.isNotEmpty) _buildActiveNow(),
            const SizedBox(height: 20),
            _buildSavedItems(),
            const SizedBox(height: 24),
            _buildLogoutButton(context),
            const SizedBox(height: 100), // padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndProfileInfo() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Top Banner
        Container(
          height: 260,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/profile_banner.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Gradient overlay for readability at the top
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: 0.3), Colors.transparent],
            ),
          ),
        ),
        // Settings Button top right
        Positioned(
          top: 45,
          right: 20,
          child: GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: const Icon(Icons.settings, color: AppColors.primaryDark, size: 22),
            ),
          ),
        ),
        
        // Main Content Container
        Padding(
          padding: const EdgeInsets.only(top: 170),
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(_profile?.photoUrl ?? 'https://ui-avatars.com/api/?name=${_profile?.displayName ?? 'Neighbor'}&background=random'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Name and Edit Button Row
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _profile?.displayName ?? 'Neighbor',
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ],
                  ),
                  Positioned(
                    right: 20,
                    child: GestureDetector(
                      onTap: () => context.push('/edit_profile'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit, size: 14, color: Color(0xFF1E293B)),
                            const SizedBox(width: 6),
                            Text('Edit Profile', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Location & Member since
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text('Mumbai, Maharashtra', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 11, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text('Member since Jan 2026', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              // Bio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _profile?.bio ?? 'Creator of ShareNest. Happy to help neighbours and build a kinder, more connected community. 🌱',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569), height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),
              // "Small actions" Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    gradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF34C759).withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5EF),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: const Color(0xFF34C759).withValues(alpha: 0.2), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.energy_savings_leaf, color: Color(0xFF34C759), size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"Small actions.',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F4C3A), fontStyle: FontStyle.italic),
                            ),
                            Text(
                              'Bigger neighbourhoods."',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F4C3A), fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  
  Widget _buildCommunityImpact() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.energy_savings_leaf, color: Color(0xFF34C759), size: 24),
                  const SizedBox(width: 8),
                  Text('Community Impact', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                ],
              ),
              Text('Together, we make a kinder neighbourhood.', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildImpactCard(Icons.energy_savings_leaf, const Color(0xFFEAF5EF), const Color(0xFF34C759), '${_stats['items'] ?? 18}', 'Items\nShared'),
              _buildImpactCard(Icons.people, const Color(0xFFF3E8FA), const Color(0xFFAF52DE), '${_stats['lends'] ?? 11}', 'Neighbours\nHelped'),
              _buildImpactCard(Icons.autorenew, const Color(0xFFEAF5EF), const Color(0xFF34C759), '${_stats['borrows'] ?? 14}', 'Items\nReused'),
              _buildImpactCard(Icons.public, const Color(0xFFE6F0FA), const Color(0xFF007AFF), '1', 'A Greener\nCommunity'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(IconData icon, Color bgColor, Color iconColor, String value, String label) {
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF64748B), height: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // My Dashboard Button
          GestureDetector(
            onTap: () => context.push('/tracking_dashboard'),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF0EA5E9)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [BoxShadow(color: const Color(0xFF2DD4BF).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('My Dashboard', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('View your complete activity, stats and insights', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  // Fake chart graphic area
                  Container(
                    width: 70,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward, color: Color(0xFF0EA5E9), size: 16),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // My SOS Signals Button
          GestureDetector(
            onTap: () => context.push('/my_sos_signals'),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFFF8A80)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('My SOS Signals', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Manage your active and past urgent requests', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // My Posts Button
          GestureDetector(
            onTap: () => context.push('/my_posts'),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A65), Color(0xFFFFCCBC)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [BoxShadow(color: const Color(0xFFFF8A65).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.article_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('My Posts', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('View and manage all your posts', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  // Real image stack from active listings
                  if (_activeListings.isNotEmpty)
                    SizedBox(
                      width: 70,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          if (_activeListings.isNotEmpty && _activeListings[0].imageUrls.isNotEmpty)
                            _buildPhoto(_activeListings[0].imageUrls.first, 0, 20),
                          if (_activeListings.length > 1 && _activeListings[1].imageUrls.isNotEmpty)
                            _buildPhoto(_activeListings[1].imageUrls.first, 1, 10),
                          if (_activeListings.length > 2 && _activeListings[2].imageUrls.isNotEmpty)
                            _buildPhoto(_activeListings[2].imageUrls.first, 2, 0),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward, color: Color(0xFFFF8A65), size: 16),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String url, int index, double rightOffset) {
    return Positioned(
      right: rightOffset,
      child: Transform.rotate(
        angle: index == 0 ? -0.1 : (index == 2 ? 0.1 : 0),
        child: Container(
          width: 36,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(2, 2))],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveNow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
              GestureDetector(
                onTap: () => context.push('/my_posts'),
                child: Row(
                  children: const [
                    Text('See All', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 11)),
                    Icon(Icons.chevron_right, size: 14, color: AppColors.primaryDark),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _activeListings.length,
            itemBuilder: (context, index) {
              final item = _activeListings[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        children: [
                          item.photoUrls.isNotEmpty
                              ? Image.network(item.photoUrls.first, height: 90, width: double.infinity, fit: BoxFit.cover)
                              : Container(height: 90, color: Colors.grey[200]),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                              child: Text(item.mode == 'GIVE' ? 'Giving' : item.mode == 'LEND' ? 'Lending' : 'Exchange', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              const Icon(Icons.more_vert, size: 12, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Available', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 8, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('3 interested', style: TextStyle(color: Colors.grey[800], fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.bookmark, color: Colors.orange, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saved Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                      Text("Items you're interested in", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
              Row(
                children: const [
                  Text('See All', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 11)),
                  Icon(Icons.chevron_right, size: 14, color: AppColors.primaryDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // We don't have saved items data loaded yet, so show a realistic empty state
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text("No saved items yet.", style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _signOut,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
            boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Logout', style: GoogleFonts.outfit(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.chevron_right, color: Colors.red, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
