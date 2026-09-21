import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ListingRepository _listingRepository = ListingRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final profile = await _profileRepository.getProfile(userId);
      if (mounted) {
        setState(() => _profile = profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await _loadProfile();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120), // Space for bottom nav
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildGreeting(),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildActionGrid(context),
              const SizedBox(height: 32),
              _buildRecommendations(),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo and Location
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.energy_savings_leaf,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ShareNest',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _profile?.locationName ?? 'Sainagar, Old Panvel',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
          // Chat & Profile
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.chat_bubble_text,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => context.push('/messages'),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.urgent,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.grey200,
                  backgroundImage: _profile?.photoUrl != null && _profile!.photoUrl!.isNotEmpty
                      ? NetworkImage(_profile!.photoUrl!)
                      : const AssetImage('assets/images/avatar_man.jpg') as ImageProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2,
                letterSpacing: -1,
                fontFamily: GoogleFonts.inter().fontFamily,
              ),
              children: [
                const TextSpan(text: 'What are you\nlooking '),
                TextSpan(
                  text: 'for',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: GoogleFonts.caveat().fontFamily,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' today?'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Borrow. Receive. Exchange. Build a kinder neighbourhood.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search for tools, books, appliances...',
            hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
            prefixIcon: Icon(CupertinoIcons.search, color: AppColors.primary),
            suffixIcon: Icon(Icons.tune, color: AppColors.textSecondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionItem(
            context: context,
            title: 'Need it\nnow',
            icon: Icons.bolt,
            color: AppColors.urgent,
            route: '/urgent_request',
          ),
          _buildActionItem(
            context: context,
            title: 'Borrow\nsomething',
            icon: Icons.sync,
            color: AppColors.borrow,
            route: '/borrow_hub',
          ),
          _buildActionItem(
            context: context,
            title: 'Get\nsomething\nfor free',
            icon: Icons.card_giftcard,
            color: AppColors.give,
            route: '/free_items',
          ),
          _buildActionItem(
            context: context,
            title: 'Exchange\nitems',
            icon: Icons.swap_horiz,
            color: AppColors.exchange,
            route: '/exchange_hub',
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Expanded(
      child: PhysicsCard(
        onTap: () => context.push(route),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Icon(icon, color: color, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'You might need this',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: FutureBuilder<List<Listing>>(
            future: _listingRepository.getActiveListings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              final listings = snapshot.data ?? [];
              if (listings.isEmpty) {
                return const Center(
                  child: Text(
                    'No active listings found.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final item = listings[index];

                  // Map database mode to UI colors
                  Color tagColor = AppColors.borrow;
                  if (item.mode == 'GIVE') tagColor = AppColors.give;
                  if (item.mode == 'EXCHANGE') tagColor = AppColors.exchange;

                  // In real app, route to the correct detail page with item ID
                  return PhysicsCard(
                    onTap: () async {
                      await context.push('/item', extra: item);
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: Stack(
                        children: [
                          // Background Image
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: item.photoUrls.isNotEmpty
                                  ? Image.network(item.photoUrls.first, fit: BoxFit.cover)
                                  : BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        size: 40,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.mode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
