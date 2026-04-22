/// VigilionX - Emergency Contact Model
/// Represents a trusted emergency contact for a user.

import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String id;
  final String ownerUid;
  final String name;
  final String phone;
  final String? email;
  final String relation;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.phone,
    this.email,
    required this.relation,
    required this.createdAt,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map, String docId) {
    return EmergencyContact(
      id: docId,
      ownerUid: map['ownerUid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      relation: map['relation'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'phone': phone,
      'email': email,
      'relation': relation,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? email,
    String? relation,
  }) {
    return EmergencyContact(
      id: id,
      ownerUid: ownerUid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relation: relation ?? this.relation,
      createdAt: createdAt,
    );
  }
}
