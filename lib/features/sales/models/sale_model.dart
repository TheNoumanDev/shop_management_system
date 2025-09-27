import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double purchasePrice;
  final double sellingPrice;
  final double totalAmount;
  final double profit;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final DateTime saleDate;
  final DateTime createdAt;

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.totalAmount,
    required this.profit,
    this.customerName,
    this.customerPhone,
    this.notes,
    required this.saleDate,
    required this.createdAt,
  });

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (data['sellingPrice'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      profit: (data['profit'] ?? 0).toDouble(),
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      notes: data['notes'],
      saleDate: (data['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'totalAmount': totalAmount,
      'profit': profit,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'notes': notes,
      'saleDate': Timestamp.fromDate(saleDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Sale copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? purchasePrice,
    double? sellingPrice,
    double? totalAmount,
    double? profit,
    String? customerName,
    String? customerPhone,
    String? notes,
    DateTime? saleDate,
  }) {
    return Sale(
      id: id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      profit: profit ?? this.profit,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      saleDate: saleDate ?? this.saleDate,
      createdAt: createdAt,
    );
  }
}