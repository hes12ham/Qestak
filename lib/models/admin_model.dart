import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final DateTime createdAt;

  AdminModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.businessName = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Display name: businessName if available, else name
  String get displayName =>
      businessName.isNotEmpty ? businessName : name;

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'businessName': businessName,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      businessName: data['businessName'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
