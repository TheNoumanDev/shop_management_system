import 'package:cloud_firestore/cloud_firestore.dart';

// Photocopy Expense Model
class PhotocopyExpense {
  final String id;
  final String type; // Machine Purchase, Ink Refill, Paper Purchase, etc.
  final double amount;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  PhotocopyExpense({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  factory PhotocopyExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotocopyExpense(
      id: doc.id,
      type: data['type'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PhotocopyExpense copyWith({
    String? type,
    double? amount,
    String? description,
    DateTime? date,
  }) {
    return PhotocopyExpense(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }
}

// Photocopy Income/Transaction Model
class PhotocopyIncome {
  final String id;
  final int copies;
  final double ratePerCopy;
  final double totalAmount;
  final String? customerName;
  final String? notes;
  final String? incomeType; // B/W, Color, Sticker
  final DateTime date;
  final DateTime createdAt;

  PhotocopyIncome({
    required this.id,
    required this.copies,
    required this.ratePerCopy,
    required this.totalAmount,
    this.customerName,
    this.notes,
    this.incomeType,
    required this.date,
    required this.createdAt,
  });

  factory PhotocopyIncome.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotocopyIncome(
      id: doc.id,
      copies: data['copies'] ?? 0,
      ratePerCopy: (data['ratePerCopy'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      customerName: data['customerName'],
      notes: data['notes'],
      incomeType: data['incomeType'] ?? 'B/W',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'copies': copies,
      'ratePerCopy': ratePerCopy,
      'totalAmount': totalAmount,
      'customerName': customerName,
      'notes': notes,
      'incomeType': incomeType,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PhotocopyIncome copyWith({
    int? copies,
    double? ratePerCopy,
    double? totalAmount,
    String? customerName,
    String? notes,
    String? incomeType,
    DateTime? date,
  }) {
    return PhotocopyIncome(
      id: id,
      copies: copies ?? this.copies,
      ratePerCopy: ratePerCopy ?? this.ratePerCopy,
      totalAmount: totalAmount ?? this.totalAmount,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      incomeType: incomeType ?? this.incomeType,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }
}

// Photocopy Service Summary Model (for dashboard stats)
class PhotocopyStats {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final int totalCopies;
  final DateTime lastUpdated;

  PhotocopyStats({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalCopies,
    required this.lastUpdated,
  });

  factory PhotocopyStats.empty() {
    return PhotocopyStats(
      totalIncome: 0,
      totalExpenses: 0,
      netProfit: 0,
      totalCopies: 0,
      lastUpdated: DateTime.now(),
    );
  }
}