/// VigilionX - Settings Screen
/// App settings for permissions, notifications, appearance, and logout.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationTracking = true;
  bool _darkMode = true;

  Future<void> _handleLogout() async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to log out of VigilionX?',
      confirmText: 'Logout',
      isDangerous: true,
    );

    if (confirm && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0E21), Color(0xFF141A2E)],
                )
              : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios),
                      ),
                      const Expanded(
                        child: Text(
                          'Settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account section
                      const SectionHeader(title: 'Account'),
                      GlassCard(
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.profile),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: AppColors.primaryGradient),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  auth.user?.fullName != null && auth.user!.fullName.isNotEmpty
                                      ? auth.user!.fullName.substring(0, 1).toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.user?.fullName ?? 'User',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    auth.user?.email ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.textLight
                                          : AppColors.textDarkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textMuted),
                          ],
                        ),
                      ),

                      // Safety section
                      const SectionHeader(title: 'Safety'),
                      _buildSettingTile(
                        icon: Icons.people,
                        title: 'Trusted Contacts',
                        subtitle: 'Manage emergency contacts',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.contacts),
                      ),
                      _buildSettingTile(
                        icon: Icons.history,
                        title: 'Alert History',
                        subtitle: 'View past SOS alerts',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.alertHistory),
                      ),
                      _buildSettingTile(
                        icon: Icons.route,
                        title: 'Trip History',
                        subtitle: 'View past trips',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.tripHistory),
                      ),

                      // Permissions section
                      const SectionHeader(title: 'Permissions'),
                      _buildSwitchTile(
                        icon: Icons.notifications_active,
                        title: 'Push Notifications',
                        subtitle: 'Receive emergency alerts',
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                      ),
                      _buildSwitchTile(
                        icon: Icons.location_on,
                        title: 'Location Tracking',
                        subtitle: 'Allow GPS access for SOS & trips',
                        value: _locationTracking,
                        onChanged: (v) {
                          setState(() => _locationTracking = v);
                          if (!v) {
                            LocationService().openAppSettings();
                          }
                        },
                      ),

                      // Appearance
                      const SectionHeader(title: 'Appearance'),
                      _buildSwitchTile(
                        icon: Icons.dark_mode,
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme',
                        value: _darkMode,
                        onChanged: (v) => setState(() => _darkMode = v),
                      ),

                      // About
                      const SectionHeader(title: 'About'),
                      _buildSettingTile(
                        icon: Icons.info_outline,
                        title: 'VigilionX',
                        subtitle: 'Version 1.0.0 • Safety First',
                      ),

                      const SizedBox(height: 24),

                      // Logout
                      GradientButton(
                        text: 'Logout',
                        icon: Icons.logout,
                        gradient: [AppColors.error, AppColors.primaryDark],
                        onPressed: _handleLogout,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
