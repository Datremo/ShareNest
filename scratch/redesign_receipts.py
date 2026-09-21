import os

def update_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Redesign the RequestDetailsGlassCard to include item photo, title, mode, order ID, and user details in a single elegant receipt.
    
    new_card_code = '''
  Widget _buildRequestDetailsGlassCard() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    String dateStr = '';
    if (widget.request.startDate != null && widget.request.endDate != null) {
      if (widget.request.startDate!.day == widget.request.endDate!.day && widget.request.startDate!.month == widget.request.endDate!.month) {
        dateStr = '${dateFormat.format(widget.request.startDate!)}, ${timeFormat.format(widget.request.startDate!)} - ${timeFormat.format(widget.request.endDate!)}';
      } else {
        dateStr = '${dateFormat.format(widget.request.startDate!)} - ${dateFormat.format(widget.request.endDate!)}';
      }
    }

    final orderId = widget.request.id.substring(0, 8).toUpperCase();

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
              Text('#$orderId', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.listing.photoUrls.isNotEmpty
                    ? Image.network(widget.listing.photoUrls.first, width: 80, height: 80, fit: BoxFit.cover)
                    : Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.image, color: Colors.grey)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.listing.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.listing.mode == 'LEND' ? 'BORROW' : widget.listing.mode,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Condition: ${widget.listing.condition}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
                if (widget.request.duration != null) ...[
                  _buildDetailRow('Duration', widget.request.duration!),
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
          if (widget.request.message != null && widget.request.message!.isNotEmpty) ...[
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
                '"${widget.request.message!}"',
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
    
    # We will replace _buildRequestDetailsGlassCard entirely, and the old _buildDetailRow.
    import re
    # Pattern to match the old _buildRequestDetailsGlassCard down to the end of _buildDetailRow
    pattern = r'Widget _buildRequestDetailsGlassCard\(\) \{.*?\n  Widget _buildDetailRow\(String label, String value\) \{.*?\n  \}'
    content = re.sub(pattern, new_card_code.strip(), content, flags=re.DOTALL)
    
    # Also, we should remove _buildOwnerGlassCard() from RequesterRequestDetailPage and _buildRequesterGlassCard from OwnerRequestDetailPage, 
    # instead we will insert a nice Profile snippet.
    
    with open(filepath, 'w') as f:
        f.write(content)


update_file('lib/features/requests/presentation/requester_request_detail_page.dart')
update_file('lib/features/requests/presentation/owner_request_detail_page.dart')
print('Updated files.')
