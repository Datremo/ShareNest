import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/item_request.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';
import '../../../core/data/repositories/request_repository.dart';
import '../../../core/data/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerRequestDetailPage extends StatefulWidget {
  final ItemRequest request;
  final Listing listing;
  final Profile requester;

  const OwnerRequestDetailPage({
    super.key,
    required this.request,
    required this.listing,
    required this.requester,
  });

  @override
  State<OwnerRequestDetailPage> createState() => _OwnerRequestDetailPageState();
}

class _OwnerRequestDetailPageState extends State<OwnerRequestDetailPage> {
  final RequestRepository _requestRepo = RequestRepository();
  late String _currentStatus;
  late ItemRequest _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _currentStatus = widget.request.status;
    _refreshRequest();
  }

  Future<void> _refreshRequest() async {
    final latest = await _requestRepo.getRequestById(widget.request.id);
    if (latest != null && mounted) {
      setState(() {
        _currentRequest = latest;
        _currentStatus = latest.status;
      });
    }
  }

  int _getStepIndex() {
    if (widget.listing.mode != 'LEND') {
      // GIVE / EXCHANGE flow
      switch (_currentStatus) {
        case 'PENDING': return 0;
        case 'ACCEPTED': return 1;
        case 'COMPLETED': return 2;
        default: return 0;
      }
    }
    
    // LEND flow
    switch (_currentStatus) {
      case 'PENDING': return 0;
      case 'ACCEPTED': return 1;
      case 'ACTIVE': return 2;
      case 'RETURN_REQUESTED': return 3;
      case 'COMPLETED': return 4;
      default: return 0;
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
    final bool isLend = widget.listing.mode == 'LEND';
    
    final steps = isLend 
      ? [
          {'title': 'Request Received', 'subtitle': 'Pending owner approval'},
          {'title': 'Pickup Confirmed', 'subtitle': 'Waiting for code verification'},
          {'title': 'Item Handed Off', 'subtitle': 'Item is with requester'},
          {'title': 'Return Requested', 'subtitle': 'Waiting for return code verification'},
          {'title': 'Completed', 'subtitle': 'Item returned successfully'},
        ]
      : [
          {'title': 'Request Received', 'subtitle': 'Pending owner approval'},
          {'title': 'Pickup Confirmed', 'subtitle': 'Waiting for code verification'},
          {'title': 'Completed', 'subtitle': 'Item handed over successfully'},
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
          if (_currentRequest.pickupTime != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Pickup scheduled for:\n${DateFormat('MMM d, yyyy • h:mm a').format(_currentRequest.pickupTime!)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
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
    final profile = widget.requester;
    return InkWell(
      onTap: () {
        context.push('/user_profile?userId=${profile.id}');
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
                  const Text('Requester', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentStatus == 'PENDING') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus('REJECTED'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Decline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus('ACCEPTED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Deal Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    if (_currentStatus == 'ACCEPTED') {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: () => _showPinBottomSheet(isReturn: false),
          child: const Text('Verify Handoff Code', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }
    
    if (_currentStatus == 'ACTIVE' || _currentStatus == 'RETURN_REQUESTED') {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: () => _showPinBottomSheet(isReturn: true),
          child: const Text('Verify Return Code', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _updateStatus(String status) async {
    try {
      await _requestRepo.updateRequestStatus(widget.request.id, status);
      setState(() { _currentStatus = status; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showPinBottomSheet({required bool isReturn}) {
    final TextEditingController pinController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(
                isReturn ? 'Verify Return Code' : 'Verify Handoff Code',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 4-digit code provided by the borrower.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AnimatedPinInput(
                onCompleted: (code) async {
                  Navigator.pop(context);
                  await _verifyCode(code, isReturn);
                },
              ),
              const SizedBox(height: 32),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyCode(String code, bool isReturn) async {
    try {
      bool success = false;
      bool isGiveMode = widget.listing.mode == 'GIVE';
      
      if (isReturn) {
        success = await _requestRepo.verifyReturnCode(widget.request.id, code);
      } else {
        String newStatus = isGiveMode ? 'COMPLETED' : 'ACTIVE';
        success = await _requestRepo.verifyHandoffCode(widget.request.id, code, newStatus);
      }
      
      if (success) {
        setState(() { _currentStatus = (isReturn || isGiveMode) ? 'COMPLETED' : 'ACTIVE'; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code verified successfully!')));
        
        // Send notifications
        final notifRepo = NotificationRepository();
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        
        if (isGiveMode) {
          // Notify owner
          if (currentUserId != null) {
            await notifRepo.createNotification(
              userId: currentUserId,
              title: 'Item Given Successfully',
              body: 'You successfully handed over ${widget.listing.title} to ${widget.requester.displayName}.',
              type: 'request_update',
              relatedId: widget.request.id,
            );
          }
          // Notify requester
          await notifRepo.createNotification(
            userId: widget.request.requesterId,
            title: 'Item Received Successfully',
            body: 'You successfully received ${widget.listing.title}. Enjoy!',
            type: 'request_update',
            relatedId: widget.request.id,
          );
        } else if (isReturn) {
          // Notify owner
          if (currentUserId != null) {
            await notifRepo.createNotification(
              userId: currentUserId,
              title: 'Item Returned',
              body: '${widget.requester.displayName} returned ${widget.listing.title}.',
              type: 'request_update',
              relatedId: widget.request.id,
            );
          }
          // Notify requester
          await notifRepo.createNotification(
            userId: widget.request.requesterId,
            title: 'Return Complete',
            body: 'You successfully returned ${widget.listing.title}.',
            type: 'request_update',
            relatedId: widget.request.id,
          );
        }

      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}


class AnimatedPinInput extends StatefulWidget {
  final Function(String) onCompleted;
  
  const AnimatedPinInput({super.key, required this.onCompleted});

  @override
  State<AnimatedPinInput> createState() => _AnimatedPinInputState();
}

class _AnimatedPinInputState extends State<AnimatedPinInput> {
  final FocusNode _focusNode = FocusNode();
  String _code = "";

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () => _focusNode.requestFocus());
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden text field for keyboard capture
          Opacity(
            opacity: 0,
            child: TextField(
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
              onChanged: (val) {
                setState(() { _code = val; });
                if (val.length == 4) {
                  widget.onCompleted(val);
                }
              },
            ),
          ),
          // Visual digit boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              bool isFocused = _code.length == index;
              bool isFilled = index < _code.length;
              String digit = isFilled ? _code[index] : "";
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: isFocused ? 64 : 56,
                height: isFocused ? 72 : 64,
                decoration: BoxDecoration(
                  color: isFilled ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFocused ? AppColors.primary : (isFilled ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent),
                    width: isFocused ? 2 : 1,
                  ),
                  boxShadow: isFocused ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2)
                  ] : [
                    const BoxShadow(color: Colors.transparent, blurRadius: 0, spreadRadius: 0)
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  digit,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
