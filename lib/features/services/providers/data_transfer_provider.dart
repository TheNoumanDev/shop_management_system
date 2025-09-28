import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/data_transfer_models.dart';

class DataTransferProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<DataTransferIncome> _incomes = [];
  DataTransferStats _stats = DataTransferStats.empty();
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<DataTransferIncome> get incomes => _incomes;
  DataTransferStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  // Load all data
  Future<void> loadAllData() async {
    await loadIncomes();
    _calculateStats();
  }

  // Load incomes
  Future<void> loadIncomes() async {
    try {
      _setLoading(true);
      _setError(null);

      final querySnapshot = await _firebaseService.firestore
          .collection(AppConstants.dataTransferIncomeCollection)
          .orderBy('date', descending: true)
          .get();

      _incomes = querySnapshot.docs
          .map((doc) => DataTransferIncome.fromFirestore(doc))
          .toList();

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
      await _firebaseService.firestore
          .collection('services')
          .doc('data_transfer')
          .collection(monthYear)
          .doc('income')
          .collection('transactions')
          .add(income.toFirestore());

      // Update monthly metadata
      await _updateMonthlyMetadata(monthYear, income);

      await loadIncomes();
      _calculateStats();
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

      await _firebaseService.firestore
          .collection(AppConstants.dataTransferIncomeCollection)
          .doc(income.id)
          .update(income.toFirestore());

      await loadIncomes();
      _calculateStats();
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

      await _firebaseService.firestore
          .collection(AppConstants.dataTransferIncomeCollection)
          .doc(incomeId)
          .delete();

      await loadIncomes();
      _calculateStats();
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