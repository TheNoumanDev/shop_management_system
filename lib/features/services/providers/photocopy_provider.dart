import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../models/photocopy_models.dart';

class PhotocopyProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<PhotocopyExpense> _expenses = [];
  List<PhotocopyIncome> _incomes = [];
  PhotocopyStats _stats = PhotocopyStats.empty();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDataLoaded = false;  // Cache flag to avoid reloading

  // Getters
  List<PhotocopyExpense> get expenses => _expenses;
  List<PhotocopyIncome> get incomes => _incomes;
  PhotocopyStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDataLoaded => _isDataLoaded;
  
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

  // Force refresh data
  Future<void> refreshData() async {
    await loadAllData(forceRefresh: true);
  }
  
  // Load all data (with caching)
  Future<void> loadAllData({bool forceRefresh = false}) async {
    // Skip if already loaded unless force refresh
    if (_isDataLoaded && !forceRefresh) {
      return;
    }

    await Future.wait([
      loadExpenses(),
      loadIncomes(),
    ]);
    _calculateStats();
    _isDataLoaded = true;
  }
  
  // Load expenses (from month/year organization)
  Future<void> loadExpenses() async {
    try {
      _setLoading(true);
      _setError(null);

      List<PhotocopyExpense> allExpenses = [];
      final now = DateTime.now();

      // Load last 12 months of expense data
      for (int i = 0; i < 12; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthYear = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        try {
          final querySnapshot = await _firebaseService.firestore
              .collection('services')
              .doc('photocopy')
              .collection(monthYear)
              .doc('expenses')
              .collection('transactions')
              .orderBy('date', descending: true)
              .get();

          final monthExpenses = querySnapshot.docs
              .map((doc) => PhotocopyExpense.fromFirestore(doc))
              .toList();

          allExpenses.addAll(monthExpenses);
        } catch (e) {
          // If month doesn't exist, continue to next month
          continue;
        }
      }

      _expenses = allExpenses;

    } catch (e) {
      _setError('Failed to load expenses: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load incomes (from month/year organization)
  Future<void> loadIncomes() async {
    try {
      _setLoading(true);
      _setError(null);

      List<PhotocopyIncome> allIncomes = [];
      final now = DateTime.now();

      // Load last 12 months of income data
      for (int i = 0; i < 12; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthYear = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        try {
          final querySnapshot = await _firebaseService.firestore
              .collection('services')
              .doc('photocopy')
              .collection(monthYear)
              .doc('income')
              .collection('transactions')
              .orderBy('date', descending: true)
              .get();

          final monthIncomes = querySnapshot.docs
              .map((doc) => PhotocopyIncome.fromFirestore(doc))
              .toList();

          allIncomes.addAll(monthIncomes);
        } catch (e) {
          // If month doesn't exist, continue to next month
          continue;
        }
      }

      _incomes = allIncomes;

    } catch (e) {
      _setError('Failed to load incomes: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Add expense (using month/year organization)
  Future<bool> addExpense(PhotocopyExpense expense) async {
    try {
      _setLoading(true);
      _setError(null);

      final expenseDate = expense.date;
      final monthYear = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';

      // Add expense to month/year collection
      final docRef = await _firebaseService.firestore
          .collection('services')
          .doc('photocopy')
          .collection(monthYear)
          .doc('expenses')
          .collection('transactions')
          .add(expense.toFirestore());

      // Update monthly metadata
      await _updateMonthlyExpenseMetadata(monthYear, expense);

      // Add to local list instead of reloading
      final newExpense = PhotocopyExpense(
        id: docRef.id,
        type: expense.type,
        amount: expense.amount,
        description: expense.description,
        date: expense.date,
        createdAt: expense.createdAt,
      );
      _expenses.insert(0, newExpense);
      _calculateStats();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Add income (using month/year organization)
  Future<bool> addIncome(PhotocopyIncome income) async {
    try {
      _setLoading(true);
      _setError(null);

      final incomeDate = income.date;
      final monthYear = '${incomeDate.year}-${incomeDate.month.toString().padLeft(2, '0')}';

      // Add income to month/year collection
      final docRef = await _firebaseService.firestore
          .collection('services')
          .doc('photocopy')
          .collection(monthYear)
          .doc('income')
          .collection('transactions')
          .add(income.toFirestore());

      // Update monthly metadata
      await _updateMonthlyIncomeMetadata(monthYear, income);

      // Add to local list instead of reloading
      final newIncome = PhotocopyIncome(
        id: docRef.id,
        copies: income.copies,
        ratePerCopy: income.ratePerCopy,
        totalAmount: income.totalAmount,
        customerName: income.customerName,
        notes: income.notes,
        date: income.date,
        createdAt: income.createdAt,
        incomeType: income.incomeType,
      );
      _incomes.insert(0, newIncome);
      _calculateStats();
      notifyListeners();
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

      final expenseDate = expense.date;
      final monthYear = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';

      await _firebaseService.firestore
          .collection('services')
          .doc('photocopy')
          .collection(monthYear)
          .doc('expenses')
          .collection('transactions')
          .doc(expense.id)
          .update(expense.toFirestore());

      // Update local list instead of reloading
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        _calculateStats();
        notifyListeners();
      }
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

      final incomeDate = income.date;
      final monthYear = '${incomeDate.year}-${incomeDate.month.toString().padLeft(2, '0')}';

      await _firebaseService.firestore
          .collection('services')
          .doc('photocopy')
          .collection(monthYear)
          .doc('income')
          .collection('transactions')
          .doc(income.id)
          .update(income.toFirestore());

      // Update local list instead of reloading
      final index = _incomes.indexWhere((i) => i.id == income.id);
      if (index != -1) {
        _incomes[index] = income;
        _calculateStats();
        notifyListeners();
      }
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

      // Find the expense in the list to get its date
      final expense = _expenses.firstWhere((e) => e.id == expenseId);
      final expenseDate = expense.date;
      final monthYear = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';

      await _firebaseService.firestore
          .collection('services')
          .doc('photocopy')
          .collection(monthYear)
          .doc('expenses')
          .collection('transactions')
          .doc(expenseId)
          .delete();

      // Remove from local list instead of reloading
      _expenses.removeWhere((e) => e.id == expenseId);
      _calculateStats();
      notifyListeners();
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

      // Find the income in the list to get its date
      final income = _incomes.firstWhere((i) => i.id == incomeId);
      final incomeDate = income.date;
      final monthYear = '${incomeDate.year}-${incomeDate.month.toString().padLeft(2, '0')}';

      await _firebaseService.firestore
          .collection('services')
          .doc('photocopy')
          .collection(monthYear)
          .doc('income')
          .collection('transactions')
          .doc(incomeId)
          .delete();

      // Remove from local list instead of reloading
      _incomes.removeWhere((i) => i.id == incomeId);
      _calculateStats();
      notifyListeners();
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

  // Update monthly expense metadata for analytics
  Future<void> _updateMonthlyExpenseMetadata(String monthYear, PhotocopyExpense expense) async {
    try {
      final monthDoc = _firebaseService.firestore
          .collection('services')
          .doc('photocopy')
          .collection(monthYear)
          .doc('expenses');

      await _firebaseService.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(monthDoc);

        if (snapshot.exists) {
          // Update existing metadata
          final data = snapshot.data() as Map<String, dynamic>;
          transaction.update(monthDoc, {
            'totalExpenses': (data['totalExpenses'] ?? 0.0) + expense.amount,
            'expenseCount': (data['expenseCount'] ?? 0) + 1,
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
        } else {
          // Create new metadata
          transaction.set(monthDoc, {
            'month': monthYear,
            'totalExpenses': expense.amount,
            'expenseCount': 1,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to update monthly expense metadata: $e');
    }
  }

  // Update monthly income metadata for analytics
  Future<void> _updateMonthlyIncomeMetadata(String monthYear, PhotocopyIncome income) async {
    try {
      final monthDoc = _firebaseService.firestore
          .collection('services')
          .doc('photocopy')
          .collection(monthYear)
          .doc('income');

      await _firebaseService.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(monthDoc);

        if (snapshot.exists) {
          // Update existing metadata
          final data = snapshot.data() as Map<String, dynamic>;
          transaction.update(monthDoc, {
            'totalIncome': (data['totalIncome'] ?? 0.0) + income.totalAmount,
            'totalCopies': (data['totalCopies'] ?? 0) + income.copies,
            'incomeCount': (data['incomeCount'] ?? 0) + 1,
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
        } else {
          // Create new metadata
          transaction.set(monthDoc, {
            'month': monthYear,
            'totalIncome': income.totalAmount,
            'totalCopies': income.copies,
            'incomeCount': 1,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to update monthly income metadata: $e');
    }
  }
}