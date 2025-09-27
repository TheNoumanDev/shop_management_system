import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType { electricity, internet, rent, miscellaneous }

class ShopExpense {
  final String id;
  final ExpenseType type;
  final String title;
  final String? description;
  final double amount;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ShopExpense({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.amount,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Convert from Firestore document
  factory ShopExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopExpense(
      id: doc.id,
      type: ExpenseType.values.firstWhere(
        (e) => e.toString() == 'ExpenseType.${data['type']}',
        orElse: () => ExpenseType.miscellaneous,
      ),
      title: data['title'] ?? '',
      description: data['description'],
      amount: (data['amount'] ?? 0).toDouble(),
      expenseDate: (data['expenseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'amount': amount,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Copy with method for updates
  ShopExpense copyWith({
    ExpenseType? type,
    String? title,
    String? description,
    double? amount,
    DateTime? expenseDate,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ShopExpense(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper getters
  String get typeDisplayName {
    switch (type) {
      case ExpenseType.electricity:
        return 'Electricity Bill';
      case ExpenseType.internet:
        return 'Internet Bill';
      case ExpenseType.rent:
        return 'Shop Rent';
      case ExpenseType.miscellaneous:
        return 'Miscellaneous';
    }
  }

  // Get month/year for grouping
  String get monthYear {
    return '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';
  }
}