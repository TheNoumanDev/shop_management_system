import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/product_model.dart';

class InventoryProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Get products by category
  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }
  
  // Get low stock products
  List<Product> get lowStockProducts {
    return _products.where((product) => product.isLowStock).toList();
  }
  
  // Get out of stock products
  List<Product> get outOfStockProducts {
    return _products.where((product) => product.isOutOfStock).toList();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Load all products
  Future<void> loadProducts() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final querySnapshot = await _firebaseService.firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      _products = querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      
    } catch (e) {
      _setError('Failed to load products: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Add new product
  Future<bool> addProduct(Product product) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.productsCollection)
          .add(product.toFirestore());
      
      await loadProducts(); // Refresh the list
      return true;
    } catch (e) {
      _setError('Failed to add product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update product
  Future<bool> updateProduct(Product product) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .update(product.copyWith(updatedAt: DateTime.now()).toFirestore());
      
      await loadProducts(); // Refresh the list
      return true;
    } catch (e) {
      _setError('Failed to update product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete product (soft delete)
  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      await loadProducts(); // Refresh the list
      return true;
    } catch (e) {
      _setError('Failed to delete product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update stock quantity
  Future<bool> updateStock(String productId, int newStock) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({
        'currentStock': newStock,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      await loadProducts(); // Refresh the list
      return true;
    } catch (e) {
      _setError('Failed to update stock: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Add dummy data for testing
  Future<void> addDummyData() async {
    final dummyProducts = [
      Product(
        id: '',
        name: 'iPhone 14 Case',
        category: 'Phone Cases',
        purchasePrice: 150,
        currentStock: 25,
        minStockLevel: 5,
        description: 'Transparent silicone case for iPhone 14',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), sellingPrice: 0.0,
      ),
      Product(
        id: '',
        name: 'Samsung S23 Screen Protector',
        category: 'Screen Protectors',
        purchasePrice: 80,
        currentStock: 50,
        minStockLevel: 10,
        description: 'Tempered glass screen protector',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), sellingPrice: 0.0,
      ),
      Product(
        id: '',
        name: 'USB-C Fast Charger',
        category: 'Chargers',
        purchasePrice: 300,
        currentStock: 15,
        minStockLevel: 3,
        description: '25W fast charging adapter',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), sellingPrice: 0.0,
      ),
      Product(
        id: '',
        name: 'Power Bank 10000mAh',
        category: 'Power Banks',
        purchasePrice: 800,
        currentStock: 8,
        minStockLevel: 2,
        description: 'Portable power bank with fast charging',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), sellingPrice: 0.0,
      ),
      Product(
        id: '',
        name: 'Wireless Earbuds',
        category: 'Headphones',
        purchasePrice: 1200,
        currentStock: 12,
        minStockLevel: 3,
        description: 'Bluetooth 5.0 wireless earbuds',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), sellingPrice: 0.0,
      ),
    ];
    
    for (final product in dummyProducts) {
      await addProduct(product);
    }
  }
}