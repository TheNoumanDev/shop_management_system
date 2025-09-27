import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final double creditBalance; // Udhar amount (positive = they owe us, negative = we owe them)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.address,
    this.creditBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Convert from Firestore document
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      address: data['address'],
      creditBalance: (data['creditBalance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'creditBalance': creditBalance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Copy with method for updates
  Customer copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    String? address,
    double? creditBalance,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      creditBalance: creditBalance ?? this.creditBalance,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper getters
  bool get hasDebt => creditBalance > 0;
  bool get hasCredit => creditBalance < 0;
  String get creditStatus {
    if (creditBalance > 0) return 'Owes us';
    if (creditBalance < 0) return 'We owe them';
    return 'Clear';
  }
}