import re

def fix_file(filepath, is_owner_page):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Let's replace _buildRequestDetailsGlassCard entirely.
    new_request_details = '''
  Widget _buildRequestDetailsGlassCard() {
    String dateStr = '';
    try {
      final dateFormat = DateFormat('MMM d, yyyy');
      final timeFormat = DateFormat('h:mm a');
      if (widget.request.startDate != null && widget.request.endDate != null) {
        if (widget.request.startDate!.day == widget.request.endDate!.day && widget.request.startDate!.month == widget.request.endDate!.month) {
          dateStr = '${dateFormat.format(widget.request.startDate!)}, ${timeFormat.format(widget.request.startDate!)} - ${timeFormat.format(widget.request.endDate!)}';
        } else {
          dateStr = '${dateFormat.format(widget.request.startDate!)} - ${dateFormat.format(widget.request.endDate!)}';
        }
      }
    } catch (e) {
      dateStr = 'Unknown';
    }

    String orderId = '';
    try {
      orderId = widget.request.id.substring(0, 8).toUpperCase();
    } catch (e) {
      orderId = 'N/A';
    }

    String photoUrl = '';
    try {
      if (widget.listing.photoUrls.isNotEmpty) {
        photoUrl = widget.listing.photoUrls.first;
      }
    } catch (e) {
      // ignore
    }

    String title = '';
    try {
      title = widget.listing.title;
    } catch (e) {
      title = 'Unknown Item';
    }

    String mode = '';
    try {
      mode = widget.listing.mode;
    } catch (e) {
      mode = '';
    }

    String condition = '';
    try {
      condition = widget.listing.condition ?? 'N/A';
    } catch (e) {
      condition = 'N/A';
    }
    
    String message = '';
    try {
      message = widget.request.message ?? '';
    } catch (e) {
      message = '';
    }
    
    String duration = '';
    try {
      duration = widget.request.duration ?? '';
    } catch (e) {
      duration = '';
    }

    return LiquidGlassContainer(
      sigma: 15,
      opacity: 0.7,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ORDER RECEIPT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary, letterSpacing: 1.2)),
              Text('#$orderId', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photoUrl.isNotEmpty
                    ? Image.network(photoUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.broken_image)))
                    : Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.image, color: Colors.grey)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mode == 'LEND' ? 'BORROW' : mode,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Condition: $condition', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Transaction Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white),
            ),
            child: Column(
              children: [
                if (duration.isNotEmpty) ...[
                  _buildDetailRow('Duration', duration),
                  const Divider(height: 24),
                ],
                if (dateStr.isNotEmpty) ...[
                  _buildDetailRow('Time', dateStr),
                  const Divider(height: 24),
                ],
                _buildDetailRow('Status', _currentStatus.replaceAll('_', ' ')),
              ],
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Message Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Text(
                '"$message"',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[800], height: 1.5),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14),
          ),
        ),
      ],
    );
  }
'''

    start_idx = content.find('Widget _buildRequestDetailsGlassCard() {')
    if start_idx == -1:
        print(f'Could not find _buildRequestDetailsGlassCard in {filepath}')
        return
        
    if is_owner_page:
        end_str = 'Widget _buildGenerateHandoffButton'
    else:
        end_str = 'Widget _buildHandoffCodeDisplay'
        
    end_idx = content.find(end_str)
    if end_idx == -1:
        print(f'Could not find {end_str} in {filepath}')
        end_idx = len(content) - 2 
    
    new_content = content[:start_idx] + new_request_details + '\n\n  ' + content[end_idx:]
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

fix_file('lib/features/requests/presentation/requester_request_detail_page.dart', False)
fix_file('lib/features/requests/presentation/owner_request_detail_page.dart', True)
print('Done!')
