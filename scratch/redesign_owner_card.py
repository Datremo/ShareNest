import re

def update_file(filepath, method_name, role_name, profile_var, is_loading_check=None):
    with open(filepath, 'r') as f:
        content = f.read()

    new_card_code = f'''
  Widget {method_name}() {{
    return LiquidGlassContainer(
      sigma: 15,
      opacity: 0.7,
      padding: const EdgeInsets.all(20),
      child: {is_loading_check if is_loading_check else 'false'} 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('{role_name}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: {profile_var}?.photoUrl != null
                          ? NetworkImage({profile_var}!.photoUrl!)
                          : null,
                      child: {profile_var}?.photoUrl == null
                          ? const Icon(Icons.person, size: 28, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          {profile_var}?.displayName ?? 'Unknown User',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified_user, color: Colors.green, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Member • Trust Score: 100',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.message, color: AppColors.primary, size: 20),
                  )
                ],
              ),
            ],
          ),
    );
  }}
'''

    pattern = rf'Widget {method_name}\(\) {{.*?\n    \);\n  \}}'
    content = re.sub(pattern, new_card_code.strip(), content, flags=re.DOTALL)
    
    with open(filepath, 'w') as f:
        f.write(content)

update_file('lib/features/requests/presentation/requester_request_detail_page.dart', '_buildOwnerGlassCard', 'ITEM OWNER', '_ownerProfile', '_isLoadingOwner')
update_file('lib/features/requests/presentation/owner_request_detail_page.dart', '_buildRequesterGlassCard', 'BORROWER', 'widget.requester', 'false')

print('Updated user cards.')
