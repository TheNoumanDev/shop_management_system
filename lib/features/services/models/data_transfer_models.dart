import 'package:cloud_firestore/cloud_firestore.dart';

// Data Transfer Income/Transaction Model - Simple like photocopy
class DataTransferIncome {
  final String id;
  final double totalAmount;
  final String? customerName;
  final DateTime date;
  final DateTime createdAt;

  DataTransferIncome({
    required this.id,
    required this.totalAmount,
    this.customerName,
    required this.date,
    required this.createdAt,
  });

  factory DataTransferIncome.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DataTransferIncome(
      id: doc.id,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      customerName: data['customerName'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalAmount': totalAmount,
      'customerName': customerName,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  DataTransferIncome copyWith({
    double? totalAmount,
    String? customerName,
    DateTime? date,
  }) {
    return DataTransferIncome(
      id: id,
      totalAmount: totalAmount ?? this.totalAmount,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }
}

// Data Transfer Service Summary Model (for dashboard stats)
class DataTransferStats {
  final double totalIncome;
  final int totalTransfers;
  final DateTime lastUpdated;

  DataTransferStats({
    required this.totalIncome,
    required this.totalTransfers,
    required this.lastUpdated,
  });

  factory DataTransferStats.empty() {
    return DataTransferStats(
      totalIncome: 0,
      totalTransfers: 0,
      lastUpdated: DateTime.now(),
    );
  }
}