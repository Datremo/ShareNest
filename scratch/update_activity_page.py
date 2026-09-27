import re

filepath = r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\activity\presentation\activity_page.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _loadData to fetch urgent offers
load_data_replacement = """  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _requestRepo.getIncomingRequestsWithListings(),
        _requestRepo.getMyRequestsWithListings(),
        _notificationRepo.getNotifications(),
        _requestRepo.getIncomingUrgentOffers(),
        _requestRepo.getMyUrgentOffers(),
      ]);
      if (mounted) {
        setState(() {
          final rawIncoming = results[0] as List<Map<String, dynamic>>;
          final rawOutgoing = results[1] as List<Map<String, dynamic>>;
          final rawIncomingUrgent = results[3] as List<Map<String, dynamic>>;
          final rawOutgoingUrgent = results[4] as List<Map<String, dynamic>>;
          
          bool filterCompleted(Map<String, dynamic> req) {
            return true;
          }
          
          final mappedIncomingUrgent = rawIncomingUrgent.map((e) => {...e, '_is_urgent_offer': true}).toList();
          final mappedOutgoingUrgent = rawOutgoingUrgent.map((e) => {...e, '_is_urgent_offer': true}).toList();
          
          _incomingRequests = [...rawIncoming.where(filterCompleted), ...mappedIncomingUrgent];
          _outgoingRequests = [...rawOutgoing.where(filterCompleted), ...mappedOutgoingUrgent];
          
          if (_notifications.isEmpty) {
            _notifications = results[2] as List<AppNotification>;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }"""

content = re.sub(r'  Future<void> _loadData\(\) async \{.*?(?=  @override\n  Widget build)', load_data_replacement + '\n\n', content, flags=re.DOTALL)


# 2. Update the SliverList item builder
item_builder_pattern = r'delegate: SliverChildBuilderDelegate\(\s*\(context, index\) \{\s*final data = sortedRequests\[index\];.*?(?=\s*childCount: sortedRequests\.length,\s*\),)'
item_builder_replacement = """delegate: SliverChildBuilderDelegate(
          (context, index) {
            final data = sortedRequests[index];
            final isUrgent = data['_is_urgent_offer'] == true;
            
            if (isUrgent) {
               final profileData = isIncoming ? data['profiles'] : data['urgent_request']['profiles'];
               return StaggeredListItem(
                 index: index,
                 child: PhysicsCard(
                   onTap: () async {
                     // Route to urgent request detail or sos signals
                     await context.push('/my_sos_signals');
                     if (mounted) _loadData();
                   },
                   child: _buildUrgentOfferItem(data, profileData, isIncoming),
                 ),
               );
            }
            
            final profileData = isIncoming ? data['profiles'] : data['listing']['profiles'];
            
            return StaggeredListItem(
              index: index,
              child: PhysicsCard(
                onTap: () async {
                  final request = ItemRequest.fromJson(data);
                  final listing = Listing.fromJson(data['listing']);
                  final profile = Profile.fromJson(profileData);
                  if (isIncoming) {
                    await context.push('/owner_request_detail', extra: {
                      'request': request,
                      'listing': listing,
                      'requester': profile,
                    });
                  } else {
                    await context.push('/requester_request_detail', extra: {
                      'request': request,
                      'listing': listing,
                    });
                  }
                  if (mounted) _loadData();
                },
                child: _buildRequestItem(
                  request: ItemRequest.fromJson(data),
                  listing: Listing.fromJson(data['listing']),
                  profile: Profile.fromJson(profileData),
                  isIncoming: isIncoming,
                ),
              ),
            );
          },"""

content = re.sub(item_builder_pattern, item_builder_replacement, content, flags=re.DOTALL)


# 3. Add _buildUrgentOfferItem
urgent_offer_item = """
  Widget _buildUrgentOfferItem(Map<String, dynamic> data, Map<String, dynamic> profileData, bool isIncoming) {
    Color statusColor = _getStatusColor(data['status']);
    final urgentReq = data['urgent_request'];
    final profileName = profileData['display_name'] ?? 'Neighbour';
    
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.red.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.red, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        urgentReq['title'] ?? 'Urgent Request',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Text(
                        (data['status'] as String).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isIncoming ? "Offer from: $profileName" : "Offer to: $profileName",
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 12, color: Colors.red.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      "Urgent Offer",
                      style: TextStyle(
                        color: Colors.red.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
"""

# Insert _buildUrgentOfferItem before _getStatusColor
content = content.replace('  Color _getStatusColor(String status) {', urgent_offer_item + '\n  Color _getStatusColor(String status) {')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated activity_page.dart safely!")
