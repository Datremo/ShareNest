import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      context.go('/auth'); // Route to the new AuthGate/AuthLandingScreen
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // Show confirmation dialog before deleting
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // In a real app, call a Supabase Edge Function to delete the user account
      // For now, just sign out
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          const SizedBox(height: 12),
          _buildSettingsGroup([
            _buildSettingsItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () => context.push('/edit_profile'),
            ),
            _buildSettingsItem(
              icon: Icons.verified_user_outlined,
              title: 'Verification',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                    const SizedBox(width: 4),
                    const Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              iconColor: AppColors.success,
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.lock_outline,
              title: 'Privacy',
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.location_on_outlined,
              title: 'Location Preferences',
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.language,
              title: 'Language',
              trailingText: 'English',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),
          const Text('Safety', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          const SizedBox(height: 12),
          _buildSettingsGroup([
            _buildSettingsItem(
              icon: Icons.shield_outlined,
              title: 'Safety Tips',
              iconColor: AppColors.success,
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.report_problem_outlined,
              title: 'Report a User',
              iconColor: AppColors.error,
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.block,
              title: 'Blocked Users',
              iconColor: AppColors.error,
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),
          const Text('Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          const SizedBox(height: 12),
          _buildSettingsGroup([
            _buildSettingsItem(
              icon: Icons.help_outline,
              title: 'Help Centre',
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.contact_support_outlined,
              title: 'Contact Us',
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: 'About ShareNest',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),
          const Text('Account Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 12),
          _buildSettingsGroup([
            _buildSettingsItem(
              icon: Icons.logout,
              title: 'Log Out',
              iconColor: Colors.orange,
              onTap: () => _logout(context),
            ),
            _buildSettingsItem(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              iconColor: Colors.red,
              onTap: () => _deleteAccount(context),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Color? iconColor,
    Widget? trailing,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primaryDark, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.primaryDark)),
            ),
            if (trailingText != null)
              Text(trailingText, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 4),
            ],
            if (trailing == null && trailingText == null)
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
            if (trailingText != null)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
