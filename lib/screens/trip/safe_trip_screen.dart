/// VigilionX - Safe Trip Screen
/// Start a monitored trip with destination, ETA, and automatic alert generation.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';

class SafeTripScreen extends StatefulWidget {
  const SafeTripScreen({super.key});

  @override
  State<SafeTripScreen> createState() => _SafeTripScreenState();
}

class _SafeTripScreenState extends State<SafeTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  DateTime? _selectedETA;

  @override
  void dispose() {
    _destinationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.darkSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.darkSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedETA = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _startTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedETA == null) {
      Helpers.showSnackbar(context, 'Please select expected arrival time',
          isError: true);
      return;
    }
    if (_selectedETA!.isBefore(DateTime.now())) {
      Helpers.showSnackbar(context, 'ETA must be in the future', isError: true);
      return;
    }

    final uid = Provider.of<AuthProvider>(context, listen: false).uid;
    if (uid == null) return;

    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    // Default coordinates if not provided
    double lat = double.tryParse(_latController.text) ?? 28.6139;
    double lng = double.tryParse(_lngController.text) ?? 77.2090;

    final success = await tripProvider.startTrip(
      ownerUid: uid,
      destinationName: _destinationController.text.trim(),
      destinationLat: lat,
      destinationLng: lng,
      expectedArrivalTime: _selectedETA!,
    );

    if (mounted) {
      if (success) {
        Helpers.showSnackbar(context, 'Trip started! Stay safe.', isSuccess: true);
        Navigator.pop(context);
      } else {
        Helpers.showSnackbar(
            context, tripProvider.error ?? 'Failed to start trip',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tripProvider = Provider.of<TripProvider>(context);

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
          child: Column(
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
                        'Safe Trip',
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Active Trip indicator
                      if (tripProvider.hasActiveTrip) ...[
                        _buildActiveTripCard(tripProvider),
                        const SizedBox(height: 24),
                      ],

                      // New Trip Form (show only if no active trip)
                      if (!tripProvider.hasActiveTrip) ...[
                        // Info card
                        GlassCard(
                          gradientColors: const [
                            Color(0xFF1A237E),
                            Color(0xFF0D47A1),
                          ],
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppColors.accent, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Set your destination and expected arrival time. '
                                  'If you don\'t mark your trip as completed by the '
                                  'ETA, an automatic alert will be sent to your '
                                  'trusted contacts.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Colors.white.withValues(alpha: 0.8),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _destinationController,
                                hint: 'e.g., Home, Office, Airport',
                                label: 'Destination Name',
                                prefixIcon: Icons.place,
                                validator: (v) => Validators.validateRequired(
                                    v, 'Destination'),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _latController,
                                      hint: 'Latitude',
                                      label: 'Lat (optional)',
                                      prefixIcon: Icons.explore,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _lngController,
                                      hint: 'Longitude',
                                      label: 'Lng (optional)',
                                      prefixIcon: Icons.explore,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ETA Picker
                              GestureDetector(
                                onTap: _pickDateTime,
                                child: GlassCard(
                                  margin: EdgeInsets.zero,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.schedule,
                                            color: AppColors.accent),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Expected Arrival Time',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _selectedETA != null
                                                  ? DateFormat(
                                                          'MMM dd, yyyy • hh:mm a')
                                                      .format(_selectedETA!)
                                                  : 'Tap to set ETA',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedETA != null
                                                    ? null
                                                    : AppColors.textMuted,
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
                              ),
                              const SizedBox(height: 32),

                              GradientButton(
                                text: 'Start Safe Trip',
                                icon: Icons.route,
                                gradient: AppColors.safeGradient,
                                isLoading: tripProvider.isLoading,
                                onPressed: _startTrip,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(TripProvider tripProvider) {
    final trip = tripProvider.activeTrip!;
    return Column(
      children: [
        GlassCard(
          gradientColors: trip.isOverdue
              ? [const Color(0xFF4A0000), const Color(0xFF8B0000)]
              : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    trip.isOverdue ? Icons.warning_amber : Icons.directions_run,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Trip',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          trip.destinationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (trip.isOverdue
                              ? AppColors.error
                              : AppColors.success)
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trip.isOverdue ? 'OVERDUE' : 'ON TRACK',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: trip.timeProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  color:
                      trip.isOverdue ? AppColors.error : AppColors.success,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Started: ${Helpers.formatTime(trip.startTime)}',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  Text(
                    'ETA: ${Helpers.formatTime(trip.expectedArrivalTime)}',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  trip.isOverdue
                      ? '⚠️ Trip is overdue!'
                      : '${Helpers.formatDuration(trip.remainingTime)} remaining',
                  style: TextStyle(
                    color: trip.isOverdue
                        ? AppColors.warning
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          text: 'Mark Trip Complete',
          icon: Icons.check_circle,
          gradient: AppColors.safeGradient,
          onPressed: () async {
            final success = await tripProvider.completeTrip();
            if (mounted) {
              Helpers.showSnackbar(
                context,
                success
                    ? 'Trip completed safely! 🎉'
                    : 'Failed to complete trip',
                isSuccess: success,
                isError: !success,
              );
            }
          },
        ),
      ],
    );
  }
}
