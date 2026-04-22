/// VigilionX - Onboarding Screen
/// Multi-page intro showcasing key features with smooth animations.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/custom_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.sos,
      title: 'Instant SOS Alerts',
      subtitle:
          'Trigger an emergency alert with a single tap. Your GPS location '
          'is instantly shared with your trusted contacts.',
      gradient: AppColors.sosGradient,
    ),
    _OnboardingData(
      icon: Icons.route,
      title: 'Safe Trip Monitoring',
      subtitle:
          'Set your destination and expected arrival time. If you don\'t arrive '
          'on time, an automatic alert is sent to your contacts.',
      gradient: AppColors.accentGradient,
    ),
    _OnboardingData(
      icon: Icons.location_on,
      title: 'Real-Time Tracking',
      subtitle:
          'Your live location is tracked on Google Maps with pinpoint accuracy. '
          'Stay connected, stay safe.',
      gradient: AppColors.safeGradient,
    ),
    _OnboardingData(
      icon: Icons.people,
      title: 'Trusted Contacts',
      subtitle:
          'Add your trusted emergency contacts. They receive instant notifications '
          'when you need help the most.',
      gradient: AppColors.purpleGradient,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF141A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    _currentPage == _pages.length - 1 ? '' : 'Skip',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Icon circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: size.width * 0.45,
                              height: size.width * 0.45,
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 200,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: page.gradient,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: page.gradient.first.withValues(alpha: 0.4),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                page.icon,
                                color: Colors.white,
                                size: size.width * 0.18 > 80 ? 80 : size.width * 0.18,
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Title
                            Text(
                              page.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Subtitle
                            Text(
                              page.subtitle,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textLight.withValues(alpha: 0.8),
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Indicator & Button
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.primary,
                        dotColor: AppColors.textMuted.withValues(alpha: 0.3),
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      text: _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingDone, true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
