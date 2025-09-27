import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final int currentStock;
  final int minStockLevel;
  final String? description;
  final String? imageUrl;
  final String? supplierId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentStock,
    this.minStockLevel = 0,
    this.description,
    this.imageUrl,
    this.supplierId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Convert from Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final purchasePrice = (data['purchasePrice'] ?? 0).toDouble();
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      purchasePrice: purchasePrice,
      sellingPrice: (data['sellingPrice'] ?? purchasePrice * 2).toDouble(),
      currentStock: data['currentStock'] ?? 0,
      minStockLevel: data['minStockLevel'] ?? 0,
      description: data['description'],
      imageUrl: data['imageUrl'],
      supplierId: data['supplierId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'minStockLevel': minStockLevel,
      'description': description,
      'imageUrl': imageUrl,
      'supplierId': supplierId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Copy with method for updates
  Product copyWith({
    String? name,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    int? currentStock,
    int? minStockLevel,
    String? description,
    String? imageUrl,
    String? supplierId,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      supplierId: supplierId ?? this.supplierId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  // Check if stock is low
  bool get isLowStock => currentStock <= minStockLevel;
  
  // Check if out of stock
  bool get isOutOfStock => currentStock <= 0;
}