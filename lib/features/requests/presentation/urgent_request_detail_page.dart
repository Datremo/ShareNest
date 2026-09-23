import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/urgent_request.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';

class UrgentRequestDetailPage extends StatefulWidget {
  final String requestId;

  const UrgentRequestDetailPage({super.key, required this.requestId});

  @override
  State<UrgentRequestDetailPage> createState() => _UrgentRequestDetailPageState();
}

class _UrgentRequestDetailPageState extends State<UrgentRequestDetailPage> {
  bool _isLoading = true;
  UrgentRequest? _request;
  Map<String, dynamic>? _requesterProfile;
  bool _isOffering = false;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final data = await Supabase.instance.client
          .from('urgent_requests')
          .select('*, profiles(*)')
          .eq('id', widget.requestId)
          .single();
      
      if (mounted) {
        setState(() {
          _request = UrgentRequest.fromJson(data);
          _requesterProfile = data['profiles'] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _offerHelp(String type, String duration) async {
    setState(() => _isOffering = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (_request?.requesterId == user.id) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot help yourself!')));
        return;
      }

      // Use the secure RPC to perform the entire transaction (bypassing RLS safely)
      final reqId = await Supabase.instance.client.rpc(
        'fulfill_urgent_request',
        params: {
          'p_urgent_request_id': widget.requestId,
          'p_helper_id': user.id,
          'p_mode': type.toUpperCase(),
          'p_duration': duration,
        },
      );

      if (mounted) {
        context.pop(); // close bottom sheet
        context.pop(); // close detail page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match Confirmed! Go to Activity -> Alerts to start the handoff.')),
        );
      }

    } catch (e) {
      debugPrint('Error offering help: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Oops!'),
            content: Text('Failed to confirm help: $e'),
            actions: [
              TextButton(onPressed: () => ctx.pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOffering = false);
    }
  }

  void _showOfferBottomSheet() {
    String selectedDuration = '2 hours';
    String selectedType = 'lend'; // 'lend' or 'give'
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final options = ['30 min', '1 hour', '2 hours', '1 day'];

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('I Can Help!', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'lend'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedType == 'lend' ? const Color(0xFFE53935) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: selectedType == 'lend' ? const Color(0xFFE53935) : Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Text('I\'ll Lend It', style: TextStyle(color: selectedType == 'lend' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'give'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedType == 'give' ? const Color(0xFFE53935) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: selectedType == 'give' ? const Color(0xFFE53935) : Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Text('I\'ll Give It', style: TextStyle(color: selectedType == 'give' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    if (selectedType == 'lend') ...[
                      Text('How long can you lend this for?', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: options.map((opt) => GestureDetector(
                          onTap: () => setModalState(() => selectedDuration = opt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              color: selectedDuration == opt ? const Color(0xFFE53935) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(opt, style: TextStyle(color: selectedDuration == opt ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        )).toList(),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite, color: Color(0xFFE53935)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('You are awesome! This item will be permanently transferred to them. You won\'t need to do a return handoff.', style: GoogleFonts.inter(color: const Color(0xFFE53935), fontSize: 13, fontWeight: FontWeight.w500, height: 1.3)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isOffering ? null : () => _offerHelp(selectedType, selectedType == 'lend' ? selectedDuration : 'forever'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isOffering
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirm Help', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))));
    }
    if (_request == null) {
      return const Scaffold(body: Center(child: Text('Request not found')));
    }

    final req = _request!;
    final name = _requesterProfile?['display_name'] ?? 'Neighbour';
    final avatar = _requesterProfile?['avatar_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.back, color: Colors.black, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Map / Radar simulation
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/images/neighborhood_banner.png', fit: BoxFit.cover),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: Color(0xFFE53935), size: 16),
                            const SizedBox(width: 4),
                            Text('Need It Now', style: GoogleFonts.inter(color: const Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text('~400m away', style: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(req.title, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2)),
                  if (req.description != null && req.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(req.description!, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700], height: 1.5)),
                  ],
                  
                  const SizedBox(height: 32),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.access_time_filled, 'Needed by', req.neededBy ?? 'Right now'),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.timer, 'Duration', req.duration ?? '30 min'),
                        const Divider(height: 24),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              backgroundColor: Colors.grey[200],
                              child: avatar == null ? Text(name[0], style: const TextStyle(color: Colors.grey)) : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Verified Neighbour', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (req.status == 'ACTIVE' && req.requesterId != Supabase.instance.client.auth.currentUser?.id)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: ElevatedButton(
                onPressed: _showOfferBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.handshake_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('I Can Help', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
