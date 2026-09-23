import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/models/listing.dart';
import 'exchange_filters_bottom_sheet.dart';

class ExchangeHubPage extends StatefulWidget {
  const ExchangeHubPage({super.key});

  @override
  State<ExchangeHubPage> createState() => _ExchangeHubPageState();
}

class _ExchangeHubPageState extends State<ExchangeHubPage> {
  Map<String, dynamic>? _activeFilters;
  final _listingRepo = ListingRepository();
  String _selectedFilter = 'All';
  bool _isListView = true;
  late Future<List<Listing>> _exchangeFuture;

  @override
  void initState() {
    super.initState();
    _exchangeFuture = _listingRepo.getListingsByMode('EXCHANGE');
  }

  Future<void> _showFilters() async {
    final filters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExchangeFiltersBottomSheet(),
    );
    if (filters != null) {
      setState(() {
        _activeFilters = filters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('Exchange Items', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Abstract Background Orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.exchange.withValues(alpha: 0.15),
                boxShadow: [BoxShadow(blurRadius: 150, color: AppColors.exchange.withValues(alpha: 0.2))],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(blurRadius: 120, color: AppColors.primary.withValues(alpha: 0.2))],
              ),
            ),
          ),
          RefreshIndicator(

        onRefresh: () async {
          setState(() {
            _exchangeFuture = _listingRepo.getListingsByMode('EXCHANGE');
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          children: [
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Want'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Offering'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Nearby'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('Electronics'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Home & Kitchen'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Books'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Clothing'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('More'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildViewToggles(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<List<Listing>>(
                future: _exchangeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.exchange)),
                    );
                  }
                  final listings = snapshot.data ?? [];
                  if (listings.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.swap_horiz, size: 48, color: AppColors.grey400),
                            SizedBox(height: 12),
                            Text('No exchange items available yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('Be the first to list an exchange!', style: TextStyle(color: AppColors.exchange, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${listings.length} exchange posts near you', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                          const Row(
                            children: [
                              Text('Sort', style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.w600)),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primaryDark),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...listings.map((item) => GestureDetector(
                        onTap: () => context.push('/item', extra: item),
                        child: _buildExchangeCard(listing: item),
                      )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Icon(CupertinoIcons.search, color: AppColors.primary, size: 20),
          ),
          Expanded(
            child: Text('Search items to exchange...', style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryDark),
            onPressed: _showFilters,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.exchange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.exchange : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : AppColors.primaryDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        )),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(label, style: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.w500,
        fontSize: 13,
      )),
    );
  }

  Widget _buildViewToggles() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isListView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isListView ? AppColors.exchange : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: !_isListView ? [BoxShadow(color: AppColors.exchange.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, color: !_isListView ? Colors.white : Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text('Map View', style: TextStyle(color: !_isListView ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isListView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isListView ? AppColors.exchange : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _isListView ? [BoxShadow(color: AppColors.exchange.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_list_bulleted_rounded, color: _isListView ? Colors.white : Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text('List View', style: TextStyle(color: _isListView ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeCard({required Listing listing}) {
    // Attempt to extract what they are looking for from preferences JSON, fallback to generic
    String lookingFor = 'Open to offers';
    if (listing.preferences != null && listing.preferences!.containsKey('looking_for')) {
      lookingFor = listing.preferences!['looking_for'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            child: listing.photoUrls.isNotEmpty
                ? Image.network(listing.photoUrls.first, width: 100, height: 110, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 110, color: Colors.grey[200], child: const Icon(Icons.image_outlined, color: AppColors.grey400)),
                  )
                : Container(width: 100, height: 110, color: Colors.grey[200], child: const Icon(Icons.swap_horiz, color: AppColors.exchange, size: 32)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const Icon(CupertinoIcons.heart, color: AppColors.primaryDark, size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.swap_horiz, color: AppColors.exchange, size: 12),
                      const SizedBox(width: 4),
                      Expanded(child: Text('Looking for: $lookingFor', style: const TextStyle(color: AppColors.exchange, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 12),
                      const SizedBox(width: 4),
                      Expanded(child: Text(listing.locationName ?? 'Nearby', style: TextStyle(color: Colors.grey[600], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
