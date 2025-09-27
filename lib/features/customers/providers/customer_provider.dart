import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_model.dart';
import '../models/credit_transaction_model.dart';

class CustomerProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Customer> _customers = [];
  List<CreditTransaction> _creditTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Customer> get customers => _customers;
  List<CreditTransaction> get creditTransactions => _creditTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get customers with debt
  List<Customer> get customersWithDebt =>
      _customers.where((customer) => customer.hasDebt).toList();

  // Get customers with credit
  List<Customer> get customersWithCredit =>
      _customers.where((customer) => customer.hasCredit).toList();

  // Get total debt amount (customers owe us)
  double get totalDebtAmount =>
      _customers.fold(0.0, (total, customer) =>
          total + (customer.creditBalance > 0 ? customer.creditBalance : 0));

  // Get total credit amount (we owe customers)
  double get totalCreditAmount =>
      _customers.fold(0.0, (total, customer) =>
          total + (customer.creditBalance < 0 ? customer.creditBalance.abs() : 0));

  // Get transactions for a specific customer
  List<CreditTransaction> getTransactionsForCustomer(String customerId) {
    return _creditTransactions.where((transaction) => transaction.customerId == customerId).toList();
  }

  // Load all customers
  Future<void> loadCustomers() async {
    _setLoading(true);
    try {
      final querySnapshot = await _firestore
          .collection('customers')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _customers = querySnapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .toList();

      _clearError();
    } catch (e) {
      _setError('Failed to load customers: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load credit transactions for a specific customer
  Future<void> loadCreditTransactions(String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('credit_transactions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('transactionDate', descending: true)
          .get();

      _creditTransactions = querySnapshot.docs
          .map((doc) => CreditTransaction.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load transactions: $e');
    }
  }

  // Add a new customer
  Future<bool> addCustomer(Customer customer) async {
    try {
      final docRef = await _firestore.collection('customers').add(customer.toFirestore());
      final newCustomer = customer.copyWith();
      _customers.add(Customer(
        id: docRef.id,
        name: newCustomer.name,
        phoneNumber: newCustomer.phoneNumber,
        email: newCustomer.email,
        address: newCustomer.address,
        creditBalance: newCustomer.creditBalance,
        createdAt: newCustomer.createdAt,
        updatedAt: newCustomer.updatedAt,
        isActive: newCustomer.isActive,
      ));
      _customers.sort((a, b) => a.name.compareTo(b.name));
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add customer: $e');
      return false;
    }
  }

  // Update customer
  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _firestore
          .collection('customers')
          .doc(customer.id)
          .update(customer.toFirestore());

      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        _customers.sort((a, b) => a.name.compareTo(b.name));
        _clearError();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update customer: $e');
      return false;
    }
  }

  // Delete customer (soft delete)
  Future<bool> deleteCustomer(String customerId) async {
    try {
      await _firestore
          .collection('customers')
          .doc(customerId)
          .update({'isActive': false, 'updatedAt': Timestamp.now()});

      _customers.removeWhere((customer) => customer.id == customerId);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete customer: $e');
      return false;
    }
  }

  // Add credit transaction
  Future<bool> addCreditTransaction(CreditTransaction transaction) async {
    try {
      // Add transaction to database
      final docRef = await _firestore
          .collection('credit_transactions')
          .add(transaction.toFirestore());

      // Update customer balance
      final customer = _customers.firstWhere((c) => c.id == transaction.customerId);
      final balanceChange = transaction.type == TransactionType.given
          ? transaction.amount  // Customer owes us more
          : -transaction.amount; // Customer owes us less

      final updatedCustomer = customer.copyWith(
        creditBalance: customer.creditBalance + balanceChange,
      );

      await updateCustomer(updatedCustomer);

      // Add to local list if we're viewing this customer's transactions
      if (_creditTransactions.isNotEmpty &&
          _creditTransactions.first.customerId == transaction.customerId) {
        _creditTransactions.insert(0, CreditTransaction(
          id: docRef.id,
          customerId: transaction.customerId,
          customerName: transaction.customerName,
          type: transaction.type,
          amount: transaction.amount,
          note: transaction.note,
          transactionDate: transaction.transactionDate,
          createdAt: transaction.createdAt,
        ));
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add transaction: $e');
      return false;
    }
  }

  // Find customer by name (for autocomplete)
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    return _customers
        .where((customer) =>
            customer.name.toLowerCase().contains(query.toLowerCase()) ||
            (customer.phoneNumber?.contains(query) ?? false))
        .toList();
  }

  // Find or create customer by name
  Future<Customer?> findOrCreateCustomer(String name, {String? phoneNumber}) async {
    // First try to find existing customer
    final existing = _customers
        .where((c) => c.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;

    if (existing != null) return existing;

    // Create new customer
    final newCustomer = Customer(
      id: '',
      name: name.trim(),
      phoneNumber: phoneNumber?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await addCustomer(newCustomer);
    if (success) {
      return _customers.lastWhere((c) => c.name == name.trim());
    }
    return null;
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
    final dummyCustomers = [
      Customer(
        id: '',
        name: 'Ahmed Ali',
        phoneNumber: '03001234567',
        creditBalance: 1500.0, // Owes us
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      Customer(
        id: '',
        name: 'Fatima Khan',
        phoneNumber: '03009876543',
        creditBalance: -500.0, // We owe them
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      Customer(
        id: '',
        name: 'Muhammad Hassan',
        phoneNumber: '03005555555',
        creditBalance: 0.0, // Clear
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final customer in dummyCustomers) {
      await addCustomer(customer);
    }
  }
}