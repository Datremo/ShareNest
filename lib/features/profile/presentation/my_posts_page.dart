import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final ListingRepository _listingRepo = ListingRepository();
  List<Listing> _allListings = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    setState(() => _isLoading = true);
    try {
      final listings = await _listingRepo.getUserListings();
      if (mounted) {
        setState(() {
          _allListings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: $e')),
        );
      }
    }
  }

  List<Listing> get _filteredListings {
    var filtered = _allListings;
    if (_selectedDateRange != null) {
      filtered = filtered.where((l) {
        if (l.createdAt == null) return false;
        return l.createdAt!.isAfter(_selectedDateRange!.start) && l.createdAt!.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    if (_selectedFilter == 'All') return filtered;
    return filtered.where((l) => l.mode.toUpperCase() == _selectedFilter.toUpperCase()).toList();
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter by Date', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                if (_selectedDateRange != null)
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedDateRange = null);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDateFilterOption('Yesterday', DateTimeRange(start: DateTime.now().subtract(const Duration(days: 1)), end: DateTime.now())),
            _buildDateFilterOption('This Week', DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now())),
            _buildDateFilterOption('This Month', DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now())),
            ListTile(
              title: const Text('Custom Range...', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
              trailing: const Icon(Icons.date_range_rounded, color: AppColors.primary),
              onTap: () async {
                Navigator.pop(context);
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.primaryDark),
                    ),
                    child: child!,
                  ),
                );
                if (range != null) {
                  setState(() => _selectedDateRange = range);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterOption(String title, DateTimeRange range) {
    bool isSelected = _selectedDateRange?.start.year == range.start.year && 
                      _selectedDateRange?.start.month == range.start.month && 
                      _selectedDateRange?.start.day == range.start.day;
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: AppColors.primaryDark)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
      onTap: () {
        setState(() => _selectedDateRange = range);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Posts', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _selectedDateRange != null ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
              color: _selectedDateRange != null ? AppColors.primary : AppColors.primaryDark,
            ),
            onPressed: _showFilterOptions,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppColors.primaryLight.withValues(alpha: 0.3),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildFilterChips(),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _filteredListings.isEmpty
                          ? Center(
                              child: Text(
                                'No posts found.',
                                style: TextStyle(color: AppColors.primaryDark.withValues(alpha: 0.5), fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredListings.length,
                              itemBuilder: (context, index) {
                                final listing = _filteredListings[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildListingCard(listing),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          // You could show a bottom sheet here to select which type to create
          context.push('/create_lend_post');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Lend', 'Give', 'Exchange'];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primaryDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    Color badgeColor;
    switch (listing.mode.toUpperCase()) {
      case 'LEND':
        badgeColor = AppColors.success;
        break;
      case 'GIVE':
        badgeColor = AppColors.error;
        break;
      case 'EXCHANGE':
        badgeColor = AppColors.warning;
        break;
      default:
        badgeColor = AppColors.primary;
    }

    final hasImage = listing.photoUrls.isNotEmpty;
    final imageUrl = hasImage ? listing.photoUrls.first : null;

    return GestureDetector(
      onTap: () async {
        await context.push('/item', extra: listing);
        _fetchListings(); // Refresh if edited/deleted
      },
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primaryLight.withValues(alpha: 0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImage
                    ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                    : const Icon(Icons.image, color: AppColors.primary, size: 40),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          listing.mode.toUpperCase(),
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: listing.status == 'ACTIVE' ? AppColors.success.withValues(alpha: 0.1) : AppColors.grey200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.status,
                          style: TextStyle(
                            color: listing.status == 'ACTIVE' ? AppColors.success : Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${DateFormat('MMM d, yyyy').format(listing.createdAt ?? DateTime.now())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.locationName ?? 'No location',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
