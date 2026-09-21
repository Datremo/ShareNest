import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/request_repository.dart';
import '../../../core/data/models/item_request.dart';
import '../../../core/data/models/listing.dart';
import 'package:intl/intl.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> with SingleTickerProviderStateMixin {
  final RequestRepository _requestRepository = RequestRepository();
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Requests',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestRepository.getMyRequestsWithListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allData = snapshot.data ?? [];
          
          // Filter based on selected filter
          final filteredData = allData.where((data) {
            if (_selectedFilter == 'All') return true;
            final listingData = data['listing'];
            if (listingData == null) return false;
            final mode = listingData['mode'] as String?;
            if (_selectedFilter == 'Borrow' && mode == 'LEND') return true;
            if (_selectedFilter == 'Exchange' && mode == 'EXCHANGE') return true;
            if (_selectedFilter == 'Urgent' && data['status'] == 'PENDING') return true;
            return false;
          }).toList();

          final activeRequests = filteredData.where((r) => r['status'] != 'COMPLETED' && r['status'] != 'REJECTED').toList();
          final completedRequests = filteredData.where((r) => r['status'] == 'COMPLETED' || r['status'] == 'REJECTED').toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFilterChips(),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView(
                    key: ValueKey(_selectedFilter),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (activeRequests.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Active Requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        ...activeRequests.map((data) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildModernRequestCard(data),
                        )),
                        const SizedBox(height: 24),
                      ],
                      if (completedRequests.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        ...completedRequests.map((data) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildModernRequestCard(data),
                        )),
                      ],
                      if (filteredData.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'No requests found',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Urgent', 'Borrow', 'Exchange'];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModernRequestCard(Map<String, dynamic> data) {
    final request = ItemRequest.fromJson(data);
    final listingData = data['listing'] as Map<String, dynamic>?;
    final listing = listingData != null ? Listing.fromJson(listingData) : null;
    
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');
    
    String dateRange = 'Unknown dates';
    if (request.startDate != null && request.endDate != null) {
      if (request.startDate!.day == request.endDate!.day && request.startDate!.month == request.endDate!.month) {
        dateRange = '${dateFormat.format(request.startDate!)}, ${timeFormat.format(request.startDate!)} - ${timeFormat.format(request.endDate!)}';
      } else {
        dateRange = '${dateFormat.format(request.startDate!)} - ${dateFormat.format(request.endDate!)}';
      }
    } else if (request.duration != null) {
      dateRange = request.duration!;
    }

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    switch (request.status) {
      case 'ACCEPTED':
        statusColor = Colors.green[700]!;
        statusBgColor = Colors.green[50]!;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        statusColor = Colors.red[700]!;
        statusBgColor = Colors.red[50]!;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'PENDING':
      default:
        statusColor = Colors.orange[800]!;
        statusBgColor = Colors.orange[50]!;
        statusIcon = Icons.access_time_filled_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (listing != null) {
              context.push('/requester_request_detail', extra: {
                'request': request,
                'listing': listing,
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing information is unavailable for this request.')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'req_${request.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (listing?.photoUrls.isNotEmpty ?? false)
                            ? Image.network(
                                listing!.photoUrls.first,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_outlined, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing?.title ?? 'Unknown Item',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            listing?.brand ?? 'Unknown Brand',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  dateRange,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
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
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.grey200),
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            request.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (request.createdAt != null)
                      Text(
                        'Requested on ${DateFormat('MMM d').format(request.createdAt!)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                
                if (request.message?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"${request.message}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
