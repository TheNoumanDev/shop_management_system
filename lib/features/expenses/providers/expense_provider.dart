import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ShopExpense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ShopExpense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get total expenses
  double get totalExpenses =>
      _expenses.fold(0.0, (total, expense) => total + expense.amount);

  // Get expenses by type
  List<ShopExpense> getExpensesByType(ExpenseType type) =>
      _expenses.where((expense) => expense.type == type).toList();

  // Get current month expenses
  List<ShopExpense> get currentMonthExpenses {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return _expenses.where((expense) => expense.monthYear == currentMonth).toList();
  }

  // Get current month total
  double get currentMonthTotal =>
      currentMonthExpenses.fold(0.0, (total, expense) => total + expense.amount);

  // Load all expenses
  Future<void> loadExpenses() async {
    _setLoading(true);
    try {
      final querySnapshot = await _firestore
          .collection('shop_expenses')
          .where('isActive', isEqualTo: true)
          .orderBy('expenseDate', descending: true)
          .get();

      _expenses = querySnapshot.docs
          .map((doc) => ShopExpense.fromFirestore(doc))
          .toList();

      _clearError();
    } catch (e) {
      _setError('Failed to load expenses: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a new expense
  Future<bool> addExpense(ShopExpense expense) async {
    try {
      final docRef = await _firestore.collection('shop_expenses').add(expense.toFirestore());
      final newExpense = ShopExpense(
        id: docRef.id,
        type: expense.type,
        title: expense.title,
        description: expense.description,
        amount: expense.amount,
        expenseDate: expense.expenseDate,
        createdAt: expense.createdAt,
        updatedAt: expense.updatedAt,
        isActive: expense.isActive,
      );

      _expenses.insert(0, newExpense);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add expense: $e');
      return false;
    }
  }

  // Update expense
  Future<bool> updateExpense(ShopExpense expense) async {
    try {
      await _firestore
          .collection('shop_expenses')
          .doc(expense.id)
          .update(expense.toFirestore());

      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        _expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
        _clearError();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update expense: $e');
      return false;
    }
  }

  // Delete expense (soft delete)
  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _firestore
          .collection('shop_expenses')
          .doc(expenseId)
          .update({'isActive': false, 'updatedAt': Timestamp.now()});

      _expenses.removeWhere((expense) => expense.id == expenseId);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete expense: $e');
      return false;
    }
  }

  // Get expenses for a specific month
  List<ShopExpense> getExpensesForMonth(int year, int month) {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    return _expenses.where((expense) => expense.monthYear == monthKey).toList();
  }

  // Get monthly totals (for charts/reports)
  Map<String, double> getMonthlyTotals() {
    final monthlyTotals = <String, double>{};
    for (final expense in _expenses) {
      final key = expense.monthYear;
      monthlyTotals[key] = (monthlyTotals[key] ?? 0) + expense.amount;
    }
    return monthlyTotals;
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

  // Add dummy data for testing
  Future<void> addDummyData() async {
    final now = DateTime.now();
    final dummyExpenses = [
      ShopExpense(
        id: '',
        type: ExpenseType.electricity,
        title: 'Electricity Bill - December',
        amount: 3500.0,
        expenseDate: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      ShopExpense(
        id: '',
        type: ExpenseType.internet,
        title: 'Internet Bill - December',
        amount: 2000.0,
        expenseDate: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      ShopExpense(
        id: '',
        type: ExpenseType.rent,
        title: 'Shop Rent - December',
        amount: 25000.0,
        expenseDate: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ShopExpense(
        id: '',
        type: ExpenseType.miscellaneous,
        title: 'Cleaning Supplies',
        description: 'Broom, mop, detergent',
        amount: 1200.0,
        expenseDate: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    for (final expense in dummyExpenses) {
      await addExpense(expense);
    }
  }
}