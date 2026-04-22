/// VigilionX - Application Routes
/// Named route constants and route generator for navigation.

import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/sos/sos_screen.dart';
import '../screens/tracking/live_tracking_screen.dart';
import '../screens/trip/safe_trip_screen.dart';
import '../screens/trip/trip_history_screen.dart';
import '../screens/alerts/alert_history_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String contacts = '/contacts';
  static const String sos = '/sos';
  static const String liveTracking = '/live-tracking';
  static const String safeTrip = '/safe-trip';
  static const String tripHistory = '/trip-history';
  static const String alertHistory = '/alert-history';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case signup:
        return _buildRoute(const SignupScreen(), settings);
      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case contacts:
        return _buildRoute(const ContactsScreen(), settings);
      case sos:
        return _buildRoute(const SOSScreen(), settings);
      case liveTracking:
        return _buildRoute(const LiveTrackingScreen(), settings);
      case safeTrip:
        return _buildRoute(const SafeTripScreen(), settings);
      case tripHistory:
        return _buildRoute(const TripHistoryScreen(), settings);
      case alertHistory:
        return _buildRoute(const AlertHistoryScreen(), settings);
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
