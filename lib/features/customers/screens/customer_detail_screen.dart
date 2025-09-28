import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/customer_provider.dart';
import '../models/customer_model.dart';
import '../models/credit_transaction_model.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _transactionFormKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _editFormKey = GlobalKey<FormState>();
  final _editNameController = TextEditingController();
  final _editPhoneController = TextEditingController();
  final _editEmailController = TextEditingController();
  final _editAddressController = TextEditingController();

  TransactionType _selectedTransactionType = TransactionType.taken;
  bool _showEditForm = false;
  late Customer _currentCustomer;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _loadEditFormData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCreditTransactions(_currentCustomer.id);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _editNameController.dispose();
    _editPhoneController.dispose();
    _editEmailController.dispose();
    _editAddressController.dispose();
    super.dispose();
  }

  void _loadEditFormData() {
    _editNameController.text = _currentCustomer.name;
    _editPhoneController.text = _currentCustomer.phoneNumber ?? '';
    _editEmailController.text = _currentCustomer.email ?? '';
    _editAddressController.text = _currentCustomer.address ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCustomer.name),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => setState(() => _showEditForm = !_showEditForm),
            icon: Icon(_showEditForm ? Icons.close : Icons.edit),
            tooltip: _showEditForm ? 'Cancel Edit' : 'Edit Customer',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Customer'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') _showDeleteConfirmation();
            },
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          // Update current customer if it was modified
          final updatedCustomer = provider.customers
              .where((c) => c.id == _currentCustomer.id)
              .firstOrNull;
          if (updatedCustomer != null) {
            _currentCustomer = updatedCustomer;
          }

          return Column(
            children: [
              // Customer Info Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: _showEditForm ? _buildEditForm() : _buildCustomerInfo(),
              ),

              // Transaction Form
              _buildTransactionForm(),

              // Transaction History
              Expanded(child: _buildTransactionHistory(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _getBalanceColor(_currentCustomer.creditBalance),
              child: Text(
                _currentCustomer.name.isNotEmpty ? _currentCustomer.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentCustomer.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentCustomer.phoneNumber?.isNotEmpty ?? false)
                    Text('📞 ${_currentCustomer.phoneNumber}'),
                  if (_currentCustomer.email?.isNotEmpty ?? false)
                    Text('✉️ ${_currentCustomer.email}'),
                  if (_currentCustomer.address?.isNotEmpty ?? false)
                    Text('📍 ${_currentCustomer.address}'),
                  Text(
                    'Customer since ${DateFormat('MMM dd, yyyy').format(_currentCustomer.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Balance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBalanceColor(_currentCustomer.creditBalance).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBalanceColor(_currentCustomer.creditBalance).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _getBalanceText(_currentCustomer.creditBalance),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getBalanceColor(_currentCustomer.creditBalance),
                    ),
                  ),
                  Text(
                    _getBalanceLabel(_currentCustomer.creditBalance),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _editFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Customer Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _editNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) return 'Name is required';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _editPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _editEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _editAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _updateCustomer,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() => _showEditForm = false);
                  _loadEditFormData(); // Reset form data
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Form(
        key: _transactionFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Credit Transaction',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.taken,
                        label: Text('Money Received'),
                        icon: Icon(Icons.south, color: Colors.green),
                      ),
                      ButtonSegment(
                        value: TransactionType.given,
                        label: Text('Money Given'),
                        icon: Icon(Icons.north, color: Colors.red),
                      ),
                    ],
                    selected: {_selectedTransactionType},
                    onSelectionChanged: (types) {
                      setState(() {
                        _selectedTransactionType = types.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '₨',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) return 'Amount is required';
                      if (double.tryParse(value!) == null) return 'Invalid amount';
                      if (double.parse(value) <= 0) return 'Amount must be positive';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addTransaction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTransactionType == TransactionType.taken
                        ? Colors.green
                        : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(CustomerProvider provider) {
    final customerTransactions = provider.getTransactionsForCustomer(_currentCustomer.id);

    if (customerTransactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transactions yet'),
            Text('Add the first transaction using the form above'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Transaction History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: customerTransactions.length,
            itemBuilder: (context, index) {
              final transaction = customerTransactions[index];
              final isReceived = transaction.type == TransactionType.taken;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isReceived ? Colors.green : Colors.red,
                    child: Icon(
                      isReceived ? Icons.south : Icons.north,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    transaction.description,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (transaction.note?.isNotEmpty ?? false)
                        Text('Note: ${transaction.note}'),
                      Text(
                        DateFormat('MMM dd, yyyy - HH:mm').format(transaction.transactionDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    transaction.displayAmount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isReceived ? Colors.green : Colors.red,
                    ),
                  ),
                  isThreeLine: (transaction.note?.isNotEmpty ?? false),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getBalanceColor(double balance) {
    if (balance > 0) return Colors.red; // Customer owes us
    if (balance < 0) return Colors.green; // We owe customer
    return Colors.grey; // Clear balance
  }

  String _getBalanceText(double balance) {
    if (balance == 0) return '₨0';
    return '₨${balance.abs().toStringAsFixed(0)}';
  }

  String _getBalanceLabel(double balance) {
    if (balance > 0) return 'Customer Owes';
    if (balance < 0) return 'We Owe Customer';
    return 'Clear Balance';
  }

  void _addTransaction() async {
    if (!_transactionFormKey.currentState!.validate()) return;

    final transaction = CreditTransaction(
      id: '',
      customerId: _currentCustomer.id,
      customerName: _currentCustomer.name,
      type: _selectedTransactionType,
      amount: double.parse(_amountController.text),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final success = await context.read<CustomerProvider>().addCreditTransaction(transaction);
    if (success && mounted) {
      _amountController.clear();
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction added successfully'),
          backgroundColor: _selectedTransactionType == TransactionType.taken
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  void _updateCustomer() async {
    if (!_editFormKey.currentState!.validate()) return;

    final updatedCustomer = _currentCustomer.copyWith(
      name: _editNameController.text.trim(),
      phoneNumber: _editPhoneController.text.trim().isEmpty
          ? null
          : _editPhoneController.text.trim(),
      email: _editEmailController.text.trim().isEmpty
          ? null
          : _editEmailController.text.trim(),
      address: _editAddressController.text.trim().isEmpty
          ? null
          : _editAddressController.text.trim(),
    );

    final success = await context.read<CustomerProvider>().updateCustomer(updatedCustomer);
    if (success && mounted) {
      setState(() => _showEditForm = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${_currentCustomer.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final provider = context.read<CustomerProvider>();
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              navigator.pop();
              final success = await provider.deleteCustomer(_currentCustomer.id);
              if (success && mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Customer deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}