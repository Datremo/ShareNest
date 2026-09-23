import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  final String? category;

  const SearchResultsPage({super.key, required this.query, this.category});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final _listingRepo = ListingRepository();
  List<Listing> _allListings = [];
  List<Listing> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // In a real app we'd query the backend directly, but for now we filter locally
      final items = await _listingRepo.getActiveListings();
      if (mounted) {
        setState(() {
          _allListings = items;
          _filterResults();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterResults() {
    final q = widget.query.toLowerCase();
    _results = _allListings.where((item) {
      final matchesSearch = q.isEmpty || item.title.toLowerCase().contains(q) || (item.description?.toLowerCase().contains(q) ?? false);
      final matchesCat = widget.category == null || item.categoryId == widget.category;
      return matchesSearch && matchesCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search Results', style: TextStyle(color: AppColors.primaryDark, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(
              '${widget.query}${widget.category != null ? ' in ${widget.category}' : ''} • ${_results.length} items',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _results.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No results found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Text('Try a different search term or category.', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          )
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _results[index];
        return _buildResultCard(item);
      },
    );
  }

  Widget _buildResultCard(Listing item) {
    return GestureDetector(
      onTap: () => context.push('/item', extra: item),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 140,
                height: 140,
                child: item.photoUrls.isNotEmpty
                    ? Image.network(item.photoUrls.first, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 40),
                      ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryDark, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.categoryId,
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.locationName ?? 'Nearby',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getModeColor(item.mode).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.mode,
                        style: TextStyle(color: _getModeColor(item.mode), fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getModeColor(String mode) {
    switch (mode.toUpperCase()) {
      case 'GIVE': return AppColors.give;
      case 'LEND': return AppColors.borrow;
      case 'EXCHANGE': return AppColors.exchange;
      default: return AppColors.primary;
    }
  }
}
