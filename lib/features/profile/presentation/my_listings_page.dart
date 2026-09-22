import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/models/listing.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final ListingRepository _listingRepository = ListingRepository();
  int _activeTabIndex = 0; // 0: Active, 1: Paused, 2: Closed
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;

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
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Listings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _selectedDateRange != null ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
              color: _selectedDateRange != null ? AppColors.primary : Colors.black,
            ),
            onPressed: _showFilterOptions,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder<List<Listing>>(
        future: _listingRepository.getUserListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var allListings = snapshot.data ?? [];
          
          if (_selectedDateRange != null) {
            allListings = allListings.where((l) {
              if (l.createdAt == null) return false;
              return l.createdAt!.isAfter(_selectedDateRange!.start) && l.createdAt!.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
            }).toList();
          }
          
          final activeListings = allListings.where((l) => l.status == 'ACTIVE').toList();
          final pausedListings = allListings.where((l) => l.status == 'PAUSED').toList();
          final closedListings = allListings.where((l) => l.status == 'CLOSED' || l.status == 'COMPLETED').toList();

          List<Listing> currentTabListings = [];
          if (_activeTabIndex == 0) currentTabListings = activeListings;
          else if (_activeTabIndex == 1) currentTabListings = pausedListings;
          else if (_activeTabIndex == 2) currentTabListings = closedListings;

          if (_selectedFilter != 'All') {
            currentTabListings = currentTabListings.where((l) => l.mode.toUpperCase() == _selectedFilter.toUpperCase()).toList();
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildTabs(activeListings.length, pausedListings.length, closedListings.length),
                _buildFilterChips(),
                const SizedBox(height: 16),
                
                if (currentTabListings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No listings found.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...currentTabListings.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildListingCard(item),
                  )),

                const SizedBox(height: 24),
                _buildCreateListingButton(),
                const SizedBox(height: 24),
                _buildTipBanner(),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildTabs(int activeCount, int pausedCount, int closedCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = 0),
              child: _tabItem('Active ($activeCount)', _activeTabIndex == 0)
            )),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = 1),
              child: _tabItem('Paused ($pausedCount)', _activeTabIndex == 1)
            )),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = 2),
              child: _tabItem('Closed ($closedCount)', _activeTabIndex == 2)
            )),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryDark : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = ['All', 'Lend', 'Give', 'Exchange'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: chips.length,
          itemBuilder: (context, index) {
            final label = chips[index];
            final isSelected = _selectedFilter == label;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = label),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryDark : AppColors.grey200,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListingCard(Listing item) {
    bool isPaused = item.status == 'PAUSED';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.grey200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.photoUrls.isNotEmpty 
                        ? Image.network(item.photoUrls.first, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.grey200))
                        : const SizedBox(),
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
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 12,
                                  color: isPaused
                                      ? AppColors.textSecondary
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPaused
                                        ? AppColors.textSecondary
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.more_vert,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.brand ?? 'Unknown Brand',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              isPaused
                                  ? Icons.pause_circle_outline
                                  : Icons.location_on_outlined,
                              size: 12,
                              color: isPaused
                                  ? Colors.red
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.locationName ?? 'Unknown location',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isPaused
                                      ? Colors.red
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.visibility_outlined,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '0 views',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
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
            const Divider(height: 1, color: AppColors.grey100),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Edit logic
                        },
                        child: Row(
                          children: const [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppColors.textPrimary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: AppColors.textSecondary,
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

  Widget _buildCreateListingButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () => context.push('/share'),
          icon: const Icon(Icons.add, color: AppColors.primaryDark),
          label: const Text(
            'Create New Listing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primaryDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tip:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keep your listings updated with clear photos and descriptions to get more requests!',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
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