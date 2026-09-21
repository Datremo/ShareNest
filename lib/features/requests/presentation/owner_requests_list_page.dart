import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OwnerRequestsListPage extends StatefulWidget {
  const OwnerRequestsListPage({super.key});

  @override
  State<OwnerRequestsListPage> createState() => _OwnerRequestsListPageState();
}

class _OwnerRequestsListPageState extends State<OwnerRequestsListPage> {
  bool _isPendingTab = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('Requests (3)', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPendingTab = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isPendingTab ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text('Pending (2)', style: TextStyle(
                        color: _isPendingTab ? AppColors.primary : Colors.grey[500],
                        fontWeight: _isPendingTab ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                      )),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPendingTab = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isPendingTab ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text('Past (5)', style: TextStyle(
                        color: !_isPendingTab ? AppColors.primary : Colors.grey[500],
                        fontWeight: !_isPendingTab ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_isPendingTab) ...[
                  _buildRequestCard(
                    context: context,
                    name: 'Priya Sharma',
                    rating: '4.8 (8)',
                    duration: '2 days',
                    dates: '17 Sep – 19 Sep',
                    image: 'assets/images/avatar_woman.jpg',
                  ),
                  _buildRequestCard(
                    context: context,
                    name: 'Amit Kulkarni',
                    rating: '5.0 (18)',
                    duration: '1 week',
                    dates: '20 Sep – 27 Sep',
                    image: 'assets/images/avatar_man.jpg',
                  ),
                ] else ...[
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No past requests', style: TextStyle(color: Colors.grey)),
                  )),
                ],
                
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Requests are first come, first served.\nYou can choose the requester you\nfeel most comfortable with.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard({
    required BuildContext context,
    required String name,
    required String rating,
    required String duration,
    required String dates,
    required String image,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: AssetImage(image),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(60, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => context.push('/owner_request_detail'),
                      child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.black12, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(duration, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13)),
                    Text(dates, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
