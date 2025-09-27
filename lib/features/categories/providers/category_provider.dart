import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get categories by type
  List<Category> getCategoriesByType(CategoryType type) =>
      _categories.where((category) => category.type == type).toList();

  // Get product categories
  List<Category> get productCategories => getCategoriesByType(CategoryType.product);

  // Get expense categories
  List<Category> get expenseCategories => getCategoriesByType(CategoryType.expense);

  // Get service categories
  List<Category> get serviceCategories => getCategoriesByType(CategoryType.service);

  // Get general categories
  List<Category> get generalCategories => getCategoriesByType(CategoryType.general);

  // Load all categories
  Future<void> loadCategories() async {
    _setLoading(true);
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _categories = querySnapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();

      _clearError();
    } catch (e) {
      _setError('Failed to load categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a new category
  Future<bool> addCategory(Category category) async {
    try {
      final docRef = await _firestore.collection('categories').add(category.toFirestore());
      final newCategory = Category(
        id: docRef.id,
        name: category.name,
        description: category.description,
        type: category.type,
        color: category.color,
        icon: category.icon,
        isActive: category.isActive,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
      );

      _categories.add(newCategory);
      _categories.sort((a, b) => a.name.compareTo(b.name));
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add category: $e');
      return false;
    }
  }

  // Update category
  Future<bool> updateCategory(Category category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.toFirestore());

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        _categories.sort((a, b) => a.name.compareTo(b.name));
        _clearError();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update category: $e');
      return false;
    }
  }

  // Delete category (soft delete)
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _firestore
          .collection('categories')
          .doc(categoryId)
          .update({'isActive': false, 'updatedAt': Timestamp.now()});

      _categories.removeWhere((category) => category.id == categoryId);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete category: $e');
      return false;
    }
  }

  // Search categories
  List<Category> searchCategories(String query) {
    if (query.isEmpty) return _categories;
    return _categories
        .where((category) =>
            category.name.toLowerCase().contains(query.toLowerCase()) ||
            (category.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
  }

  // Find category by name
  Category? findCategoryByName(String name, CategoryType type) {
    return _categories
        .where((c) => c.name.toLowerCase() == name.toLowerCase() && c.type == type)
        .firstOrNull;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Add default categories for each type
  Future<void> addDefaultCategories() async {
    final defaultCategories = [
      // Product Categories
      Category(
        id: '',
        name: 'Mobile Phones',
        description: 'Smartphones and basic mobile phones',
        type: CategoryType.product,
        color: '#2196F3',
        icon: 'phone_android',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: '',
        name: 'Phone Accessories',
        description: 'Cases, chargers, earphones, screen protectors',
        type: CategoryType.product,
        color: '#4CAF50',
        icon: 'phone_iphone',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: '',
        name: 'Tablets',
        description: 'Android and iPad tablets',
        type: CategoryType.product,
        color: '#FF9800',
        icon: 'tablet_android',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Service Categories
      Category(
        id: '',
        name: 'Photocopying',
        description: 'Document copying services',
        type: CategoryType.service,
        color: '#9C27B0',
        icon: 'content_copy',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: '',
        name: 'Printing',
        description: 'Document and photo printing',
        type: CategoryType.service,
        color: '#673AB7',
        icon: 'print',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: '',
        name: 'Lamination',
        description: 'Document lamination services',
        type: CategoryType.service,
        color: '#00BCD4',
        icon: 'layers',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Expense Categories
      Category(
        id: '',
        name: 'Utilities',
        description: 'Electricity, water, internet bills',
        type: CategoryType.expense,
        color: '#FFEB3B',
        icon: 'electrical_services',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: '',
        name: 'Rent & Property',
        description: 'Shop rent and property expenses',
        type: CategoryType.expense,
        color: '#795548',
        icon: 'home',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: '',
        name: 'Marketing',
        description: 'Advertising and promotional expenses',
        type: CategoryType.expense,
        color: '#E91E63',
        icon: 'campaign',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // General Categories
      Category(
        id: '',
        name: 'Urgent',
        description: 'High priority items',
        type: CategoryType.general,
        color: '#F44336',
        icon: 'priority_high',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: '',
        name: 'Seasonal',
        description: 'Season-specific items and services',
        type: CategoryType.general,
        color: '#8BC34A',
        icon: 'ac_unit',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final category in defaultCategories) {
      await addCategory(category);
    }
  }
}