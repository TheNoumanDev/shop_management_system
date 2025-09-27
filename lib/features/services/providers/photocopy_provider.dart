import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/photocopy_models.dart';

class PhotocopyProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<PhotocopyExpense> _expenses = [];
  List<PhotocopyIncome> _incomes = [];
  PhotocopyStats _stats = PhotocopyStats.empty();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<PhotocopyExpense> get expenses => _expenses;
  List<PhotocopyIncome> get incomes => _incomes;
  PhotocopyStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
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
  
  // Load all data
  Future<void> loadAllData() async {
    await Future.wait([
      loadExpenses(),
      loadIncomes(),
    ]);
    _calculateStats();
  }
  
  // Load expenses
  Future<void> loadExpenses() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final querySnapshot = await _firebaseService.firestore
          .collection(AppConstants.photocopyExpensesCollection)
          .orderBy('date', descending: true)
          .get();
      
      _expenses = querySnapshot.docs
          .map((doc) => PhotocopyExpense.fromFirestore(doc))
          .toList();
      
    } catch (e) {
      _setError('Failed to load expenses: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load incomes
  Future<void> loadIncomes() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final querySnapshot = await _firebaseService.firestore
          .collection(AppConstants.photocopyIncomeCollection)
          .orderBy('date', descending: true)
          .get();
      
      _incomes = querySnapshot.docs
          .map((doc) => PhotocopyIncome.fromFirestore(doc))
          .toList();
      
    } catch (e) {
      _setError('Failed to load incomes: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Add expense
  Future<bool> addExpense(PhotocopyExpense expense) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.photocopyExpensesCollection)
          .add(expense.toFirestore());
      
      await loadExpenses();
      _calculateStats();
      return true;
    } catch (e) {
      _setError('Failed to add expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Add income
  Future<bool> addIncome(PhotocopyIncome income) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.photocopyIncomeCollection)
          .add(income.toFirestore());
      
      await loadIncomes();
      _calculateStats();
      return true;
    } catch (e) {
      _setError('Failed to add income: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update expense
  Future<bool> updateExpense(PhotocopyExpense expense) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.photocopyExpensesCollection)
          .doc(expense.id)
          .update(expense.toFirestore());
      
      await loadExpenses();
      _calculateStats();
      return true;
    } catch (e) {
      _setError('Failed to update expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update income
  Future<bool> updateIncome(PhotocopyIncome income) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.photocopyIncomeCollection)
          .doc(income.id)
          .update(income.toFirestore());
      
      await loadIncomes();
      _calculateStats();
      return true;
    } catch (e) {
      _setError('Failed to update income: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete expense
  Future<bool> deleteExpense(String expenseId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.photocopyExpensesCollection)
          .doc(expenseId)
          .delete();
      
      await loadExpenses();
      _calculateStats();
      return true;
    } catch (e) {
      _setError('Failed to delete expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete income
  Future<bool> deleteIncome(String incomeId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.firestore
          .collection(AppConstants.photocopyIncomeCollection)
          .doc(incomeId)
          .delete();
      
      await loadIncomes();
      _calculateStats();
      return true;
    } catch (e) {
      _setError('Failed to delete income: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Calculate statistics
  void _calculateStats() {
    final totalIncome = _incomes.fold<double>(0, (sum, income) => sum + income.totalAmount);
    final totalExpenses = _expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final totalCopies = _incomes.fold<int>(0, (sum, income) => sum + income.copies);
    
    _stats = PhotocopyStats(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: totalIncome - totalExpenses,
      totalCopies: totalCopies,
      lastUpdated: DateTime.now(),
    );
    
    notifyListeners();
  }
  
  // Get expenses by type
  List<PhotocopyExpense> getExpensesByType(String type) {
    return _expenses.where((expense) => expense.type == type).toList();
  }
  
  // Get incomes by date range
  List<PhotocopyIncome> getIncomesByDateRange(DateTime start, DateTime end) {
    return _incomes.where((income) => 
      income.date.isAfter(start.subtract(const Duration(days: 1))) &&
      income.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }
  
  // Add dummy data for testing
  Future<void> addDummyData() async {
    // Add dummy expenses
    final dummyExpenses = [
      PhotocopyExpense(
        id: '',
        type: 'Machine Purchase',
        amount: 25000,
        description: 'Canon imageRUNNER 2006N',
        date: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now(),
      ),
      PhotocopyExpense(
        id: '',
        type: 'Ink Refill',
        amount: 1500,
        description: 'Black toner cartridge',
        date: DateTime.now().subtract(const Duration(days: 15)),
        createdAt: DateTime.now(),
      ),
      PhotocopyExpense(
        id: '',
        type: 'Paper Purchase',
        amount: 800,
        description: 'A4 paper - 5 reams',
        date: DateTime.now().subtract(const Duration(days: 10)),
        createdAt: DateTime.now(),
      ),
    ];
    
    // Add dummy incomes
    final dummyIncomes = [
      PhotocopyIncome(
        id: '',
        copies: 50,
        ratePerCopy: 10,
        totalAmount: 500,
        customerName: 'Ahmad Ali',
        date: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
      ),
      PhotocopyIncome(
        id: '',
        copies: 20,
        ratePerCopy: 20,
        totalAmount: 400,
        customerName: 'Fatima Khan',
        notes: 'Color copies',
        date: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now(),
      ),
      PhotocopyIncome(
        id: '',
        copies: 100,
        ratePerCopy: 10,
        totalAmount: 1000,
        customerName: 'Office Documents',
        date: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now(),
      ),
    ];
    
    // Add expenses
    for (final expense in dummyExpenses) {
      await addExpense(expense);
    }
    
    // Add incomes
    for (final income in dummyIncomes) {
      await addIncome(income);
    }
  }
}