import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryType { product, expense, service, general }

class Category {
  final String id;
  final String name;
  final String? description;
  final CategoryType type;
  final String color; // Hex color string
  final String? icon; // Icon name or code
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.color,
    this.icon,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore document
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      type: CategoryType.values.firstWhere(
        (e) => e.toString() == 'CategoryType.${data['type']}',
        orElse: () => CategoryType.general,
      ),
      color: data['color'] ?? '#9E9E9E',
      icon: data['icon'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'color': color,
      'icon': icon,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method for updates
  Category copyWith({
    String? name,
    String? description,
    CategoryType? type,
    String? color,
    String? icon,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper getters
  String get typeDisplayName {
    switch (type) {
      case CategoryType.product:
        return 'Product Category';
      case CategoryType.expense:
        return 'Expense Category';
      case CategoryType.service:
        return 'Service Category';
      case CategoryType.general:
        return 'General Category';
    }
  }

  // Get predefined icons for different types
  String get defaultIcon {
    switch (type) {
      case CategoryType.product:
        return 'inventory_2';
      case CategoryType.expense:
        return 'receipt_long';
      case CategoryType.service:
        return 'build';
      case CategoryType.general:
        return 'category';
    }
  }

  // Color convenience methods
  int get colorValue {
    String hexColor = color.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // Add alpha channel
    }
    return int.parse(hexColor, radix: 16);
  }

  // Predefined color options
  static List<String> get defaultColors => [
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#9E9E9E', // Grey
    '#607D8B', // Blue Grey
  ];
}