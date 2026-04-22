/// VigilionX - Helper Utilities
/// Common helper functions used throughout the app.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

class Helpers {
  /// Format DateTime to readable string
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  /// Format DateTime to date only
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  /// Format DateTime to time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format duration to readable string
  static String formatDuration(Duration duration) {
    if (duration.isNegative) return 'Overdue';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Get relative time string
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dateTime);
  }

  /// Show custom snackbar
  static void showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : isSuccess
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
              color: isError
                  ? AppColors.error
                  : isSuccess
                      ? AppColors.success
                      : AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? AppColors.error : AppColors.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Get status color for trips
  static Color getTripStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'late':
        return AppColors.warning;
      case 'alerted':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  /// Get status icon for trips
  static IconData getTripStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.directions_run;
      case 'completed':
        return Icons.check_circle;
      case 'late':
        return Icons.warning_amber;
      case 'alerted':
        return Icons.notification_important;
      default:
        return Icons.help_outline;
    }
  }

  /// Get SOS type display text
  static String getSOSTypeLabel(String type) {
    switch (type) {
      case 'manual':
        return 'Manual SOS';
      case 'automatic_trip_delay':
        return 'Trip Delay Auto-Alert';
      default:
        return type;
    }
  }
}
