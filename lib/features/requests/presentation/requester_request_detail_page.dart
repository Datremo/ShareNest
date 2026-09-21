import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/item_request.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';
import '../../../core/data/repositories/request_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';

class RequesterRequestDetailPage extends StatefulWidget {
  final ItemRequest request;
  final Listing listing;

  const RequesterRequestDetailPage({
    super.key,
    required this.request,
    required this.listing,
  });

  @override
  State<RequesterRequestDetailPage> createState() => _RequesterRequestDetailPageState();
}

class _RequesterRequestDetailPageState extends State<RequesterRequestDetailPage> {
  final RequestRepository _requestRepo = RequestRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  Profile? _ownerProfile;
  bool _isLoadingOwner = true;
  late String _currentStatus;
  String? _handoffCode;
  String? _returnCode;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.request.status;
    _handoffCode = widget.request.handoffCode;
    _returnCode = widget.request.returnCode;
    _fetchOwnerProfile();
  }

  Future<void> _fetchOwnerProfile() async {
    try {
      final profile = await _profileRepo.getProfile(widget.listing.ownerId);
      setState(() {
        _ownerProfile = profile;
        _isLoadingOwner = false;
      });
    } catch (e) {
      setState(() { _isLoadingOwner = false; });
    }
  }

  int _getStepIndex(bool isGiveMode) {
    if (isGiveMode) {
      switch (_currentStatus) {
        case 'PENDING': return 0;
        case 'ACCEPTED': return 1;
        case 'COMPLETED': return 2;
        default: return 0;
      }
    } else {
      switch (_currentStatus) {
        case 'PENDING': return 0;
        case 'ACCEPTED': return 1;
        case 'ACTIVE': return 2;
        case 'RETURN_REQUESTED': return 3;
        case 'COMPLETED': return 4;
        default: return 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _currentStatus == 'DECLINED' || _currentStatus == 'REJECTED';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.2), Colors.transparent],
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
                    AppColors.give.withValues(alpha: 0.2),
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
                  flexibleSpace: const FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: 24, bottom: 16),
                    title: Text(
                      'Transaction Receipt',
                      style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
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
                        if (_isLoadingOwner) 
                           const Center(child: CircularProgressIndicator()) 
                        else if (_ownerProfile != null) 
                           _buildContactCard(),
                        const SizedBox(height: 32),
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
  }

  Widget _buildReceiptCard() {
    String orderId = 'N/A';
    try { orderId = widget.request.id.substring(0, 8).toUpperCase(); } catch (e) {}

    String dateStr = 'N/A';
    try {
      if (widget.request.startDate != null) {
        dateStr = DateFormat('MMM d, yyyy - h:mm a').format(widget.request.startDate!);
      }
    } catch (e) {}

    String duration = widget.request.duration ?? 'N/A';
    String message = widget.request.message ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                if (widget.request.endDate != null) ...[
                  _buildReceiptRow('End Date', widget.request.endDate!.toLocal().toString().split(' ')[0]),
                  const SizedBox(height: 16),
                ],
                if (widget.request.pickupTime != null) ...[
                  _buildReceiptRow('Pickup Time', DateFormat('MMM d, yyyy • h:mm a').format(widget.request.pickupTime!)),
                  const SizedBox(height: 16),
                ],
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
  }

  Widget _buildReceiptRow(String label, String value) {
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
  }

  Widget _buildVerticalTracker() {
    bool isGiveMode = widget.listing.mode == 'GIVE';
    final List<Map<String, String>> steps = isGiveMode ? [
      {'title': 'Request Sent', 'subtitle': 'Waiting for owner response'},
      {'title': 'Accepted', 'subtitle': 'Show handoff code to owner'},
      {'title': 'Completed', 'subtitle': 'Item received successfully'},
    ] : [
      {'title': 'Request Sent', 'subtitle': 'Waiting for owner response'},
      {'title': 'Accepted', 'subtitle': 'Show handoff code to owner'},
      {'title': 'Item Handed Off', 'subtitle': 'Enjoy your item!'},
      {'title': 'Return Requested', 'subtitle': 'Take the item back'},
      {'title': 'Completed', 'subtitle': 'Item returned successfully'},
    ];

    int currentStep = _getStepIndex(isGiveMode);

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
          ...List.generate(steps.length, (index) {
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
          }),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    final profile = _ownerProfile!;
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
                const Text('Owner', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(profile.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
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
  }

  Widget _buildActionButtons() {
    if (_currentStatus == 'PENDING') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Text('Waiting for owner approval...', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ),
      );
    }

    if (_currentStatus == 'ACCEPTED') {
      if (_handoffCode != null) {
        return Column(
          children: [
            const Text('Your Handoff Code', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            const SizedBox(height: 16),
            AnimatedGeneratedCode(code: _handoffCode!),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _generateCode(isReturn: false),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Regenerate Code'),
            ),
          ],
        );
      }
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: () => _generateCode(isReturn: false),
          child: const Text('Generate Handoff Code', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }
    
    if (_currentStatus == 'ACTIVE') {
      if (widget.listing.mode == 'GIVE') return const SizedBox.shrink();
      
      if (_returnCode != null) {
        return Column(
          children: [
            const Text('Your Return Code', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            const SizedBox(height: 16),
            AnimatedGeneratedCode(code: _returnCode!),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _generateCode(isReturn: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Regenerate Code'),
            ),
          ],
        );
      }
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: () => _generateCode(isReturn: true),
          child: const Text('Generate Return Code', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _generateCode({required bool isReturn}) async {
    try {
      // Generate a random 4 digit PIN
      final String pin = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
      
      if (isReturn) {
        await _requestRepo.generateReturnCode(widget.request.id, pin);
        if (mounted) setState(() => _returnCode = pin);
      } else {
        await _requestRepo.generateHandoffCode(widget.request.id, pin);
        if (mounted) setState(() => _handoffCode = pin);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}


class AnimatedGeneratedCode extends StatefulWidget {
  final String code;
  const AnimatedGeneratedCode({super.key, required this.code});

  @override
  State<AnimatedGeneratedCode> createState() => _AnimatedGeneratedCodeState();
}

class _AnimatedGeneratedCodeState extends State<AnimatedGeneratedCode> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Interval(index * 0.15, 1.0, curve: Curves.easeOutBack))
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: _controller, curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut))
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 56,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.code[index],
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}
