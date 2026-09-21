import os

def rewrite_file(filepath, is_owner):
    other_party = 'Requester' if is_owner else 'Owner'
    other_party_var = 'widget.requester' if is_owner else '_ownerProfile!'
    
    content = f'''import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/item_request.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';
import '../../../core/data/repositories/request_repository.dart';
import '../../../core/presentation/widgets/liquid_glass_container.dart';

class {'Owner' if is_owner else 'Requester'}RequestDetailPage extends StatefulWidget {{
  final ItemRequest request;
  final Listing listing;
  {'final Profile requester;' if is_owner else ''}

  const {'Owner' if is_owner else 'Requester'}RequestDetailPage({{
    super.key,
    required this.request,
    required this.listing,
    {'required this.requester,' if is_owner else ''}
  }});

  @override
  State<{'Owner' if is_owner else 'Requester'}RequestDetailPage> createState() => _{'Owner' if is_owner else 'Requester'}RequestDetailPageState();
}}

class _{'Owner' if is_owner else 'Requester'}RequestDetailPageState extends State<{'Owner' if is_owner else 'Requester'}RequestDetailPage> {{
  final RequestRepository _requestRepo = RequestRepository();
  {'Profile? _ownerProfile;' if not is_owner else ''}
  {'bool _isLoadingOwner = true;' if not is_owner else ''}
  late String _currentStatus;

  @override
  void initState() {{
    super.initState();
    _currentStatus = widget.request.status;
    {' _fetchOwnerProfile();' if not is_owner else ''}
  }}
  {'  Future<void> _fetchOwnerProfile() async {{
    try {{
      final profile = await _requestRepo.getProfile(widget.listing.ownerId);
      setState(() {{
        _ownerProfile = profile;
        _isLoadingOwner = false;
      }});
    }} catch (e) {{
      setState(() {{
        _isLoadingOwner = false;
      }});
    }}
  }}' if not is_owner else ''}

  int _getStepIndex() {{
    switch (_currentStatus) {{
      case 'PENDING': return 0;
      case 'ACCEPTED': return 1;
      case 'ACTIVE': return 2;
      case 'RETURN_REQUESTED': return 3;
      case 'COMPLETED': return 4;
      default: return 0;
    }}
  }}

  @override
  Widget build(BuildContext context) {{
    final size = MediaQuery.of(context).size;
    final isRejected = _currentStatus == 'DECLINED' || _currentStatus == 'REJECTED';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Dynamic Background Gradient
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                        ],
                      ),
                      child: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                    title: const Text(
                      'Transaction Receipt',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReceiptCard(),
                        const SizedBox(height: 32),
                        if (!isRejected) _buildVerticalTracker(),
                        const SizedBox(height: 32),
                        {'if (_isLoadingOwner) const Center(child: CircularProgressIndicator()) else if (_ownerProfile != null) _buildContactCard() else const SizedBox.shrink(),' if not is_owner else '_buildContactCard(),'}
                        const SizedBox(height: 32),
                        if (_currentStatus == 'ACCEPTED' || _currentStatus == 'ACTIVE' || _currentStatus == 'RETURN_REQUESTED')
                           _buildActionButtons(),
                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }}

  Widget _buildReceiptCard() {{
    String orderId = 'N/A';
    try {{ orderId = widget.request.id.substring(0, 8).toUpperCase(); }} catch (e) {{}}

    String dateStr = 'N/A';
    try {{
      if (widget.request.startDate != null) {{
        dateStr = DateFormat('MMM d, yyyy - h:mm a').format(widget.request.startDate!);
      }}
    }} catch (e) {{}}

    String duration = widget.request.duration ?? 'N/A';
    String message = widget.request.message ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORDER ID', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('#$orderId', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentStatus.replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.listing.photoUrls.isNotEmpty
                          ? Image.network(widget.listing.photoUrls.first, width: 80, height: 80, fit: BoxFit.cover)
                          : Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.listing.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(CupertinoIcons.time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(duration, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
                _buildReceiptRow('Start Date', dateStr),
                const SizedBox(height: 16),
                _buildReceiptRow('Mode', widget.listing.mode == 'LEND' ? 'BORROW' : widget.listing.mode),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildReceiptRow('Note', '"$message"'),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }}

  Widget _buildReceiptRow(String label, String value) {{
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppColors.primaryDark, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }}

  Widget _buildVerticalTracker() {{
    final steps = [
      {{'title': 'Request Sent', 'subtitle': 'Waiting for approval'}},
      {{'title': 'Accepted', 'subtitle': 'Arrange pickup'}},
      {{'title': 'Item Handed Off', 'subtitle': 'Currently active'}},
      {{'title': 'Return Requested', 'subtitle': 'Ready to return'}},
      {{'title': 'Completed', 'subtitle': 'Item returned successfully'}},
    ];

    int currentStep = _getStepIndex();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tracking Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
          const SizedBox(height: 24),
          ...List.generate(steps.length, (index) {{
            bool isCompleted = index < currentStep;
            bool isActive = index == currentStep;
            bool isLast = index == steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive ? AppColors.primary : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 4) : null,
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : (isActive ? const Center(child: CircleAvatar(radius: 4, backgroundColor: Colors.white)) : null),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isCompleted ? AppColors.primary : Colors.grey[200],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[index]['title']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                              color: isCompleted || isActive ? AppColors.primaryDark : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            steps[index]['subtitle']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isActive ? AppColors.primary : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }}),
        ],
      ),
    );
  }}

  Widget _buildContactCard() {{
    final profile = {other_party_var};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
            child: profile.photoUrl == null ? const Icon(CupertinoIcons.person_fill, color: AppColors.primary) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('{other_party}', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(profile.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/chat', extra: profile),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
            icon: const Icon(CupertinoIcons.chat_bubble_text_fill, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }}

  Widget _buildActionButtons() {{
    if (_currentStatus == 'ACCEPTED') {{
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: _showHandoffDialog,
          child: const Text('Process Handoff', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }}
    
    if (_currentStatus == 'ACTIVE' && {'true' if not is_owner else 'false'}) {{
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: _requestReturn,
          child: const Text('Request Return', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }}

    if (_currentStatus == 'RETURN_REQUESTED' && {'true' if is_owner else 'false'}) {{
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: _processReturn,
          child: const Text('Confirm Return', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }}

    return const SizedBox.shrink();
  }}

  void _showHandoffDialog() {{
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Handoff Code', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        content: Text(
          {'widget.request.handoffCode != null ? "Your code is: ${widget.request.handoffCode}" : "No code generated."' if not is_owner else '"Enter the code provided by the requester."'},
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          {'TextButton(onPressed: () {{ Navigator.pop(context); _confirmHandoff(); }}, child: const Text("Confirm"))' if is_owner else ''}
        ],
      ),
    );
  }}
  
  Future<void> _requestReturn() async {{
    try {{
      await _requestRepo.updateRequestStatus(widget.request.id, 'RETURN_REQUESTED');
      setState(() {{ _currentStatus = 'RETURN_REQUESTED'; }});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return requested!')));
    }} catch (e) {{
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }}
  }}

  Future<void> _processReturn() async {{
    try {{
      await _requestRepo.updateRequestStatus(widget.request.id, 'COMPLETED');
      setState(() {{ _currentStatus = 'COMPLETED'; }});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return completed!')));
    }} catch (e) {{
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }}
  }}

  {'Future<void> _confirmHandoff() async {{
    try {{
      await _requestRepo.updateRequestStatus(widget.request.id, "ACTIVE");
      setState(() {{ _currentStatus = "ACTIVE"; }});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Handoff confirmed!")));
    }} catch (e) {{
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }}
  }}' if is_owner else ''}
}}
'''
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

rewrite_file('lib/features/requests/presentation/owner_request_detail_page.dart', True)
rewrite_file('lib/features/requests/presentation/requester_request_detail_page.dart', False)
print('Done!')
