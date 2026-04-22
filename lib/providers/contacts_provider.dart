/// VigilionX - Contacts Provider
/// Manages emergency contacts state and CRUD operations.

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../services/firestore_service.dart';

class ContactsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<EmergencyContact> _contacts = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<EmergencyContact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasContacts => _contacts.isNotEmpty;
  int get contactCount => _contacts.length;

  /// Start listening to contacts for a user
  void listenToContacts(String uid) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _firestoreService.getEmergencyContacts(uid).listen(
      (contacts) {
        _contacts = contacts;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load contacts';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Add a new emergency contact
  Future<bool> addContact({
    required String ownerUid,
    required String name,
    required String phone,
    String? email,
    required String relation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final contact = EmergencyContact(
        id: '',
        ownerUid: ownerUid,
        name: name,
        phone: phone,
        email: email,
        relation: relation,
        createdAt: DateTime.now(),
      );
      await _firestoreService.addEmergencyContact(contact);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add contact';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing contact
  Future<bool> updateContact(EmergencyContact contact) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateEmergencyContact(contact);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update contact';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a contact
  Future<bool> deleteContact(String contactId) async {
    try {
      await _firestoreService.deleteEmergencyContact(contactId);
      return true;
    } catch (e) {
      _error = 'Failed to delete contact';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
