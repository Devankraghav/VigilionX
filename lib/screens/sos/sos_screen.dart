/// VigilionX - SOS Emergency Screen
/// Large emergency button with animated UI, GPS fetching, and alert workflow.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sos_provider.dart';
import '../../utils/helpers.dart';


class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact();

    final confirm = await Helpers.showConfirmDialog(
      context,
      title: '🚨 Trigger Emergency SOS?',
      message:
      'This will immediately send your current GPS location to all your trusted contacts and create an emergency alert record.',
      confirmText: 'YES, SEND SOS',
      cancelText: 'Cancel',
      isDangerous: true,
    );

    if (!confirm || !mounted) return;

    final uid = Provider.of<AuthProvider>(context, listen: false).uid;
    if (uid == null) {
      Helpers.showSnackbar(
        context,
        'User not logged in',
        isError: true,
      );
      return;
    }

    final sosProvider = Provider.of<SOSProvider>(context, listen: false);
    final success = await sosProvider.triggerSOS(ownerUid: uid);

    if (!mounted) return;

    if (success) {
      HapticFeedback.heavyImpact();
      Helpers.showSnackbar(
        context,
        'SOS Alert sent successfully!',
        isSuccess: true,
      );
    } else {
      Helpers.showSnackbar(
        context,
        sosProvider.error ?? 'Failed to send SOS',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sosProvider = Provider.of<SOSProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF1A0A0A),
              Color(0xFF0A0E21),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              child: Column(
                children: [
                  // App bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Emergency SOS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Status text
                  if (sosProvider.isSending) ...[
                    const Text(
                      'Sending SOS Alert...',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fetching your location & alerting contacts',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ] else if (sosProvider.isSent) ...[
                    const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'SOS Alert Sent!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your trusted contacts have been notified',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight.withValues(alpha: 0.7),
                      ),
                    ),
                    if (sosProvider.lastAlert != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on,
                                    color: AppColors.accent, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '${sosProvider.lastAlert!.latitude.toStringAsFixed(4)}, '
                                  '${sosProvider.lastAlert!.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Helpers.formatDateTime(sosProvider.lastAlert!.createdAt),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      'Press the button to send\nan emergency alert',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // SOS BUTTON
                  SizedBox(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple rings
                        ...List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _rippleAnimation,
                            builder: (context, child) {
                              final delay = index * 0.3;
                              final value =
                                  ((_rippleAnimation.value + delay) % 1.0);
                              return Container(
                                width: (size.width * 0.5) * (1 + value * 0.5),
                                height: (size.width * 0.5) * (1 + value * 0.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: (1 - value) * 0.3),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          );
                        }),

                        // Main button
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: sosProvider.isSending ? 0.9 : _pulseAnimation.value,
                              child: GestureDetector(
                                onTap: sosProvider.isSending ? null : _triggerSOS,
                                child: Container(
                                  width: size.width * 0.42,
                                  height: size.width * 0.42,
                                  decoration: BoxDecoration(
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFF1744),
                                        Color(0xFFE53935),
                                        Color(0xFFB71C1C),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.6),
                                        blurRadius: 40,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: sosProvider.isSending
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.sos,
                                                color: Colors.white, size: 48),
                                            SizedBox(height: 8),
                                            Text(
                                              'SOS',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 4,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom info
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'SOS will share your GPS location with all trusted contacts instantly.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight.withValues(alpha: 0.6),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Reset button if sent
                  if (sosProvider.isSent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                      child: TextButton(
                        onPressed: () {
                          sosProvider.reset();
                        },
                        child: const Text(
                          'Send Another SOS',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
