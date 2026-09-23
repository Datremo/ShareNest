import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/item_request.dart';
import '../../../core/data/models/profile.dart';
import '../../../core/data/repositories/request_repository.dart';

class OwnerRequestsListPage extends StatefulWidget {
  final Listing listing;
  
  const OwnerRequestsListPage({super.key, required this.listing});

  @override
  State<OwnerRequestsListPage> createState() => _OwnerRequestsListPageState();
}

class _OwnerRequestsListPageState extends State<OwnerRequestsListPage> {
  final RequestRepository _requestRepo = RequestRepository();
  bool _isPendingTab = true;
  
  Future<List<Map<String, dynamic>>> _fetchRequests() async {
    return await _requestRepo.getRequestsForListing(widget.listing.id);
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> requestData) {
    final request = ItemRequest.fromJson(requestData);
    final profile = Profile.fromJson(requestData['profiles']);
    
    // Status colors
    Color statusColor;
    String statusText = request.status.toUpperCase();
    if (statusText == 'PENDING') statusColor = Colors.orange;
    else if (statusText == 'ACCEPTED' || statusText == 'ACTIVE') statusColor = Colors.green;
    else if (statusText == 'DECLINED' || statusText == 'CANCELLED') statusColor = Colors.red;
    else statusColor = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          context.push('/owner_request_detail', extra: {
            'request': requestData,
            'requester': requestData['profiles'],
            'listing': widget.listing.toJson(),
          }).then((_) => setState(() {}));
        },
        child: _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: profile.photoUrl != null
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: profile.photoUrl == null
                        ? Text(profile.displayName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${profile.trustScore}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (request.startDate != null && request.endDate != null) ...[
                Row(
                  children: [
                    const Icon(CupertinoIcons.calendar, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('MMM d').format(request.startDate!)} - ${DateFormat('MMM d').format(request.endDate!)}',
                      style: const TextStyle(fontSize: 14, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (request.message != null && request.message!.isNotEmpty)
                Text(
                  '"${request.message}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('Item Requests', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPendingTab = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isPendingTab ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            alignment: Alignment.center,
                            child: Text('Pending', style: TextStyle(
                              color: _isPendingTab ? Colors.white : Colors.grey[500],
                              fontWeight: _isPendingTab ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            )),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPendingTab = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isPendingTab ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            alignment: Alignment.center,
                            child: Text('Past', style: TextStyle(
                              color: !_isPendingTab ? Colors.white : Colors.grey[500],
                              fontWeight: !_isPendingTab ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            )),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final allRequests = snapshot.data ?? [];
                    
                    final filteredRequests = allRequests.where((req) {
                      final status = (req['status'] as String).toUpperCase();
                      if (_isPendingTab) {
                        return status == 'PENDING';
                      } else {
                        return status != 'PENDING';
                      }
                    }).toList();

                    if (filteredRequests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _isPendingTab ? 'No pending requests.' : 'No past requests.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        return _buildRequestCard(filteredRequests[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
