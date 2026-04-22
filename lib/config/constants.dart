/// VigilionX - Application Constants
/// Central configuration for app-wide constants, strings, and defaults.

class AppConstants {
  // App Info
  static const String appName = 'VigilionX';
  static const String appTagline = 'Your Safety, Our Priority';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String emergencyContactsCollection = 'emergency_contacts';
  static const String tripsCollection = 'trips';
  static const String sosAlertsCollection = 'sos_alerts';
  static const String alertLogsCollection = 'alert_logs';

  // Trip Statuses
  static const String tripActive = 'active';
  static const String tripCompleted = 'completed';
  static const String tripLate = 'late';
  static const String tripAlerted = 'alerted';

  // SOS Types
  static const String sosManual = 'manual';
  static const String sosAutoTripDelay = 'automatic_trip_delay';

  // Alert Statuses
  static const String alertSent = 'sent';
  static const String alertDelivered = 'delivered';
  static const String alertFailed = 'failed';
  static const String alertPending = 'pending';

  // SharedPreferences Keys
  static const String prefOnboardingDone = 'onboarding_completed';
  static const String prefThemeMode = 'theme_mode';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefLocationTrackingEnabled = 'location_tracking_enabled';

  // Default Messages
  static const String sosDefaultMessage =
      '🚨 EMERGENCY ALERT! I need immediate help! '
      'This is an emergency SOS from VigilionX. '
      'Please check my location and contact emergency services.';

  static const String tripDelayMessage =
      '⚠️ TRIP DELAY ALERT! I have not reached my destination on time. '
      'This is an automatic alert from VigilionX Safe Trip monitoring. '
      'My last known location is attached.';

  // Map defaults
  static const double defaultLat = 28.6139;   // New Delhi
  static const double defaultLng = 77.2090;
  static const double defaultZoom = 15.0;

  // Timing
  static const int splashDuration = 3;
  static const int locationUpdateInterval = 5; // seconds
  static const int tripCheckInterval = 60;     // seconds
}
