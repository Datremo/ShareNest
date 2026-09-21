import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/models/profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository _profileRepo = ProfileRepository();
  bool _isLoading = true;
  Profile? _profile;
  Map<String, int> _stats = {'items': 0, 'requests': 0, 'borrows': 0, 'lends': 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final futures = await Future.wait([
        _profileRepo.getProfile(userId),
        _profileRepo.getProfileStats(userId),
      ]);
      setState(() {
        _profile = futures[0] as Profile?;
        _stats = futures[1] as Map<String, int>;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Apple-like subtle gray-blue
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                // Abstract Background Orbs
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      boxShadow: [BoxShadow(blurRadius: 100, color: AppColors.primary.withValues(alpha: 0.2))],
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  right: -100,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.exchange.withValues(alpha: 0.1),
                      boxShadow: [BoxShadow(blurRadius: 120, color: AppColors.exchange.withValues(alpha: 0.2))],
                    ),
                  ),
                ),
                
                CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            _buildStatsSummary(),
                            const SizedBox(height: 32),
                            _buildQuickActions(),
                            const SizedBox(height: 32),
                            _buildSectionHeader('About Me'),
                            const SizedBox(height: 12),
                            _buildBioCard(),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Details'),
                            const SizedBox(height: 12),
                            _buildDetailsGrid(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: FlexibleSpaceBar(
            background: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.6),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: _profile?.photoUrl != null
                        ? NetworkImage(_profile!.photoUrl!)
                        : null,
                    child: _profile?.photoUrl == null
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _profile?.displayName ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (_profile?.isVerified == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 18),
                    ]
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      actions: [
        PhysicsButton(
          onTap: () => context.push('/edit_profile').then((_) => _loadData()),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, color: AppColors.primaryDark, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummary() {
    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Items', _stats['items'].toString()),
            _buildDivider(),
            _buildStatItem('Requests', _stats['requests'].toString()),
            _buildDivider(),
            _buildStatItem('Lends', _stats['lends'].toString()),
            _buildDivider(),
            _buildStatItem('Borrows', _stats['borrows'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.primaryDark.withValues(alpha: 0.1),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: PhysicsButton(
            onTap: () => context.push('/tracking_dashboard'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF4A90E2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PhysicsButton(
            onTap: () => context.push('/settings'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_rounded, color: AppColors.primaryDark, size: 20),
                  SizedBox(width: 8),
                  Text('Settings', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildBioCard() {
    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _profile?.bio != null && _profile!.bio!.isNotEmpty
              ? _profile!.bio!
              : 'No bio provided. Add one to let neighbors know you!',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: _profile?.bio != null ? AppColors.primaryDark : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: LiquidGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(height: 12),
                      const Text('Location', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        _profile?.locationName ?? 'Not set',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LiquidGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                      const SizedBox(height: 12),
                      const Text('Trust Score', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        _profile?.trustScore != null ? '${_profile!.trustScore}' : '100',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LiquidGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.give.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: AppColors.give),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Interests & Wishlist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      SizedBox(height: 4),
                      Text('Coming Soon in v2.0', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- iOS 26 Physics & Glass Utilities ---

class PhysicsButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PhysicsButton({super.key, required this.child, required this.onTap});

  @override
  State<PhysicsButton> createState() => _PhysicsButtonState();
}

class _PhysicsButtonState extends State<PhysicsButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    // Spring physics-like feeling
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double sigma;
  final double opacity;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.sigma = 20.0,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        ),
      ),
    );
  }
}
