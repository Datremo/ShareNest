import re

with open('lib/features/profile/presentation/profile_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix Edit Profile button routing
content = content.replace("context.push('/settings')", "context.push('/edit_profile')")

# Add Settings button at top right of the banner image
banner_replacement = """
              // Banner Image
              Stack(
                children: [
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/profile_banner.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
"""
content = re.sub(r'// Banner Image\s+Container\(\s+height: 190,\s+width: double\.infinity,\s+decoration: const BoxDecoration\(\s+image: DecorationImage\(\s+image: AssetImage\(\'assets/images/profile_banner\.png\'\),\s+fit: BoxFit\.cover,\s+\),\s+\),\s+\),', banner_replacement, content)

# Remove old small actions banner and old community impact, replace with the new banner
old_small_actions = r'Widget _buildSmallActionsBanner\(\) \{.*?(?=Widget _buildCommunityImpact\(\))'
content = re.sub(old_small_actions, '', content, flags=re.DOTALL)

old_community_impact = r'Widget _buildCommunityImpact\(\) \{.*?(?=Widget _buildDashboardButtons)'
content = re.sub(old_community_impact, '', content, flags=re.DOTALL)

old_build_impact_card = r'Widget _buildImpactCard\(.*?\{.*?return Container\(.*?\);\s+\}'
content = re.sub(old_build_impact_card, '', content, flags=re.DOTALL)

# Insert the new banner
new_banner = """
  Widget _buildCommunityImpact() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFFEAF5EF), Color(0xFFEAF0FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            // Left text section
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.energy_savings_leaf, color: AppColors.primary, size: 32),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Small Actions\\nBig Change',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), height: 1.1),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'My personal impact.',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Right stats section
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(Icons.card_giftcard, const Color(0xFF34C759), '${_stats['items'] ?? 0}', 'Items\\nShared'),
                  _buildStatItem(Icons.people, const Color(0xFFAF52DE), '${_stats['lends'] ?? 0}', 'Neighbours\\nHelped'),
                  _buildStatItem(Icons.autorenew, const Color(0xFFFF3B30), '${_stats['borrows'] ?? 0}', 'Items\\nReused'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.1),
        ),
      ],
    );
  }
"""

content = content.replace("Widget _buildDashboardButtons(BuildContext context) {", new_banner + "\n  Widget _buildDashboardButtons(BuildContext context) {")

# Remove the call to _buildSmallActionsBanner in build method
content = content.replace("_buildSmallActionsBanner(),\n            const SizedBox(height: 16),", "")

with open('lib/features/profile/presentation/profile_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
