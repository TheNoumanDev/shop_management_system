import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { given, taken }

class CreditTransaction {
  final String id;
  final String customerId;
  final String customerName;
  final TransactionType type; // given (we gave money to customer) or taken (customer gave money to us)
  final double amount;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;

  CreditTransaction({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.amount,
    this.note,
    required this.transactionDate,
    required this.createdAt,
  });

  // Convert from Firestore document
  factory CreditTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditTransaction(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.taken,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      note: data['note'],
      transactionDate: (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'type': type.toString().split('.').last,
      'amount': amount,
      'note': note,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Helper getters
  String get displayAmount {
    final sign = type == TransactionType.given ? '-' : '+';
    return '$sign$amount';
  }

  String get description {
    return type == TransactionType.given
        ? 'Money given to customer'
        : 'Money received from customer';
  }
}