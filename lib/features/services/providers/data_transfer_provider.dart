import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../models/data_transfer_models.dart';

class DataTransferProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<DataTransferIncome> _incomes = [];
  DataTransferStats _stats = DataTransferStats.empty();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDataLoaded = false;  // Cache flag to avoid reloading

  // Getters
  List<DataTransferIncome> get incomes => _incomes;
  DataTransferStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDataLoaded => _isDataLoaded;

  // Get total income
  double get totalIncome => _incomes.fold<double>(0, (total, income) => total + income.totalAmount);

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

    await loadIncomes();
    _calculateStats();
    _isDataLoaded = true;
  }

  // Load incomes (from month/year organization)
  Future<void> loadIncomes() async {
    try {
      _setLoading(true);
      _setError(null);

      List<DataTransferIncome> allIncomes = [];
      final now = DateTime.now();

      // Load last 12 months of income data
      for (int i = 0; i < 12; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthYear = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        try {
          final querySnapshot = await _firebaseService.firestore
              .collection('services')
              .doc('data_transfer')
              .collection(monthYear)
              .doc('income')
              .collection('transactions')
              .orderBy('date', descending: true)
              .get();

          final monthIncomes = querySnapshot.docs
              .map((doc) => DataTransferIncome.fromFirestore(doc))
              .toList();

          allIncomes.addAll(monthIncomes);
        } catch (e) {
          // If month doesn't exist, continue to next month
          continue;
        }
      }

      _incomes = allIncomes;

    } catch (e) {
      _setError('Failed to load data transfer records: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add income
  Future<bool> addIncome(DataTransferIncome income) async {
    try {
      _setLoading(true);
      _setError(null);

      final incomeDate = income.date;
      final monthYear = '${incomeDate.year}-${incomeDate.month.toString().padLeft(2, '0')}';

      // Add income to month/year collection
      final docRef = await _firebaseService.firestore
          .collection('services')
          .doc('data_transfer')
          .collection(monthYear)
          .doc('income')
          .collection('transactions')
          .add(income.toFirestore());

      // Update monthly metadata
      await _updateMonthlyMetadata(monthYear, income);

      // Add to local list instead of reloading
      final newIncome = DataTransferIncome(
        id: docRef.id,
        totalAmount: income.totalAmount,
        customerName: income.customerName,
        date: income.date,
        createdAt: income.createdAt,
      );
      _incomes.insert(0, newIncome);
      _calculateStats();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add data transfer record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update income
  Future<bool> updateIncome(DataTransferIncome income) async {
    try {
      _setLoading(true);
      _setError(null);

      final incomeDate = income.date;
      final monthYear = '${incomeDate.year}-${incomeDate.month.toString().padLeft(2, '0')}';

      await _firebaseService.firestore
          .collection('services')
          .doc('data_transfer')
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
      _setError('Failed to update data transfer record: $e');
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
          .doc('data_transfer')
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
      _setError('Failed to delete data transfer record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calculate statistics
  void _calculateStats() {
    final totalIncome = _incomes.fold<double>(0, (total, income) => total + income.totalAmount);
    final totalTransfers = _incomes.length;

    _stats = DataTransferStats(
      totalIncome: totalIncome,
      totalTransfers: totalTransfers,
      lastUpdated: DateTime.now(),
    );

    notifyListeners();
  }

  // Get incomes by date range
  List<DataTransferIncome> getIncomesByDateRange(DateTime start, DateTime end) {
    return _incomes.where((income) =>
      income.date.isAfter(start.subtract(const Duration(days: 1))) &&
      income.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  // Add dummy data for testing
  Future<void> addDummyData() async {
    final dummyIncomes = [
      DataTransferIncome(
        id: '',
        totalAmount: 300,
        customerName: 'Ali Hassan',
        date: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
      ),
      DataTransferIncome(
        id: '',
        totalAmount: 500,
        customerName: 'Sara Ahmad',
        date: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now(),
      ),
      DataTransferIncome(
        id: '',
        totalAmount: 150,
        customerName: 'Ahmed Khan',
        date: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now(),
      ),
      DataTransferIncome(
        id: '',
        totalAmount: 200,
        customerName: 'Fatima Sheikh',
        date: DateTime.now().subtract(const Duration(days: 4)),
        createdAt: DateTime.now(),
      ),
      DataTransferIncome(
        id: '',
        totalAmount: 100,
        customerName: 'Usman Ali',
        date: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now(),
      ),
    ];

    // Add incomes
    for (final income in dummyIncomes) {
      await addIncome(income);
    }
  }

  // Update monthly metadata for analytics
  Future<void> _updateMonthlyMetadata(String monthYear, DataTransferIncome income) async {
    try {
      final monthDoc = _firebaseService.firestore
          .collection('services')
          .doc('data_transfer')
          .collection(monthYear)
          .doc('income');

      await _firebaseService.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(monthDoc);

        if (snapshot.exists) {
          // Update existing metadata
          final data = snapshot.data() as Map<String, dynamic>;
          transaction.update(monthDoc, {
            'totalIncome': (data['totalIncome'] ?? 0.0) + income.totalAmount,
            'incomeCount': (data['incomeCount'] ?? 0) + 1,
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
        } else {
          // Create new metadata
          transaction.set(monthDoc, {
            'month': monthYear,
            'totalIncome': income.totalAmount,
            'incomeCount': 1,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to update monthly metadata: $e');
    }
  }
}