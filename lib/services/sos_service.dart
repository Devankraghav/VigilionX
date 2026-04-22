import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionSubscription;

  Future<void> triggerSOS() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service is disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    if (userData == null) {
      throw Exception('User document not found');
    }

    final String senderName =
    (userData['username'] ?? 'Unknown User').toString().trim();
    final String senderPhone =
    (userData['phone'] ?? 'No Number').toString().trim();

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final double lat = position.latitude;
    final double lng = position.longitude;
    final String mapsLink = 'https://www.google.com/maps?q=$lat,$lng';

    final int batteryLevel = await Battery().batteryLevel;

    await _firestore.collection('sos_alerts').doc(user.uid).set({
      'userUid': user.uid,
      'name': senderName,
      'phone': senderPhone,
      'isActive': true,
      'startedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'latitude': lat,
      'longitude': lng,
      'mapsLink': mapsLink,
      'battery': batteryLevel,
    }, SetOptions(merge: true));

    final contactsSnapshot = await _firestore
        .collection('emergency_contacts')
        .where('ownerUid', isEqualTo: user.uid)
        .get();

    final List<String> phoneNumbers = contactsSnapshot.docs
        .map((doc) => (doc.data()['phone'] ?? '').toString().trim())
        .where((phone) => phone.isNotEmpty)
        .toList();

    if (phoneNumbers.isEmpty) {
      throw Exception('No trusted contacts found');
    }

    final String message = '''
EMERGENCY ALERT

Name: $senderName
Phone: $senderPhone

I may be in danger. Please track my live location:
$mapsLink

Please help immediately.
''';

    await _openSmsApp(phoneNumbers, message);
    _startLiveLocationUpdates(user.uid);
  }

  Future<void> _openSmsApp(List<String> phones, String body) async {
    final String numbers = phones.join(',');
    final Uri uri = Uri.parse(
      'sms:$numbers?body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not open SMS app');
    }
  }

  void _startLiveLocationUpdates(String uid) {
    _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      final double lat = position.latitude;
      final double lng = position.longitude;
      final String mapsLink = 'https://www.google.com/maps?q=$lat,$lng';

      await _firestore.collection('sos_alerts').doc(uid).set({
        'lastUpdated': FieldValue.serverTimestamp(),
        'latitude': lat,
        'longitude': lng,
        'mapsLink': mapsLink,
      }, SetOptions(merge: true));
    });
  }

  Future<void> stopSOS() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    await _firestore.collection('sos_alerts').doc(user.uid).set({
      'isActive': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}