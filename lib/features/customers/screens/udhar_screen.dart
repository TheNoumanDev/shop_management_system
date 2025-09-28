import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_styles.dart';
import '../providers/customer_provider.dart';
import '../models/customer_model.dart';
import '../models/credit_transaction_model.dart';
import 'customer_detail_screen.dart';

class UdharScreen extends StatefulWidget {
  const UdharScreen({super.key});

  @override
  State<UdharScreen> createState() => _UdharScreenState();
}

class _UdharScreenState extends State<UdharScreen> {
  // Customer form controllers
  final _customerFormKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerAddressController = TextEditingController();

  // Transaction form controllers
  final _transactionFormKey = GlobalKey<FormState>();
  final _transactionAmountController = TextEditingController();
  final _transactionNoteController = TextEditingController();

  String _selectedCustomerId = '';
  String _selectedCustomerName = '';
  TransactionType _selectedTransactionType = TransactionType.taken;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _customerAddressController.dispose();
    _transactionAmountController.dispose();
    _transactionNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Header with stats
            _buildHeader(context, provider),

            // Customer Form Section
            _buildCustomerForm(context),

            // Transaction Form Section
            _buildTransactionForm(context, provider),

            // Search filters
            _buildSearchSection(context),

            // Customer Table
            Expanded(
              child: _buildCustomersTable(context, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CustomerProvider provider) {
    return AppStyles.formCardWithHeader(
      context: context,
      title: 'Udhar Management',
      icon: Icons.account_balance_wallet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${provider.customers.length} customers • ${provider.customersWithDebt.length} with debt • ${provider.customersWithCredit.length} with credit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Debt',
                  '₨${provider.totalDebtAmount.toStringAsFixed(0)}',
                  Colors.red,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Credit',
                  '₨${provider.totalCreditAmount.toStringAsFixed(0)}',
                  Colors.green,
                  Icons.trending_down,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Net Balance',
                  '₨${(provider.totalDebtAmount - provider.totalCreditAmount.abs()).toStringAsFixed(0)}',
                  provider.totalDebtAmount > provider.totalCreditAmount.abs() ? Colors.green : Colors.red,
                  Icons.account_balance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerForm(BuildContext context) {
    return AppStyles.formCardWithHeader(
      context: context,
      title: 'Add New Customer',
      icon: Icons.person_add,
      child: Form(
        key: _customerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

                // Row 1: Name and Phone
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _customerNameController,
                        decoration: AppStyles.standardInputDecoration('Customer Name *'),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) return 'Name is required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _customerPhoneController,
                        decoration: AppStyles.standardInputDecoration('Phone Number'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _customerEmailController,
                        decoration: AppStyles.standardInputDecoration('Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _customerAddressController,
                        decoration: AppStyles.standardInputDecoration('Address'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: _clearCustomerForm,
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _submitCustomer,
                      child: const Text('Add Customer'),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionForm(BuildContext context, CustomerProvider provider) {
    return AppStyles.formCardWithHeader(
      context: context,
      title: 'Add Transaction',
      icon: Icons.account_balance,
      backgroundColor: Colors.orange.shade700,
      child: Form(
        key: _transactionFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

                // Transaction form row
                Row(
                  children: [
                    // Customer Selection
                    Expanded(
                      flex: 2,
                      child: _buildCustomerDropdown(provider),
                    ),
                    const SizedBox(width: 16),

                    // Transaction Type
                    Expanded(
                      child: SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionType.taken,
                            label: Text('Received'),
                            icon: Icon(Icons.south, size: 16),
                          ),
                          ButtonSegment(
                            value: TransactionType.given,
                            label: Text('Given'),
                            icon: Icon(Icons.north, size: 16),
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
                    const SizedBox(width: 16),

                    // Amount
                    Expanded(
                      child: TextFormField(
                        controller: _transactionAmountController,
                        decoration: AppStyles.standardInputDecoration('Amount *', prefixText: '₨'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) return 'Required';
                          if (double.tryParse(value!) == null) return 'Invalid';
                          if (double.parse(value) <= 0) return 'Must be positive';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Note
                    Expanded(
                      child: TextFormField(
                        controller: _transactionNoteController,
                        decoration: AppStyles.standardInputDecoration('Note (Optional)'),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: _selectedCustomerId.isEmpty ? null : _submitTransaction,
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

  Widget _buildCustomerDropdown(CustomerProvider provider) {
    final customers = provider.customers;
    return DropdownButtonFormField<String>(
      value: _selectedCustomerId.isEmpty ? null : _selectedCustomerId,
      decoration: AppStyles.standardInputDecoration('Select Customer *'),
      hint: const Text('Choose a customer'),
      items: customers.map((customer) {
        return DropdownMenuItem(
          value: customer.id,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _getBalanceColor(customer.creditBalance),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  customer.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getBalanceText(customer.creditBalance),
                style: TextStyle(
                  color: _getBalanceColor(customer.creditBalance),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCustomerId = value ?? '';
          if (value != null) {
            final customer = customers.firstWhere((c) => c.id == value);
            _selectedCustomerName = customer.name;
          }
        });
      },
      validator: (value) => value?.isEmpty ?? true ? 'Please select a customer' : null,
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filter',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Customers')),
                DropdownMenuItem(value: 'debt', child: Text('With Debt')),
                DropdownMenuItem(value: 'credit', child: Text('With Credit')),
                DropdownMenuItem(value: 'clear', child: Text('Clear Balance')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value ?? 'all';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTable(BuildContext context, CustomerProvider provider) {
    final filteredCustomers = _getFilteredCustomers(provider);

    if (filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No customers found matching your search'
                  : 'No customers yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Add your first customer using the form above',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return AppStyles.responsiveTable(
      context: context,
      dataTable: DataTable(
        columnSpacing: 16,
        horizontalMargin: 12,
        headingRowColor: WidgetStateProperty.all(AppStyles.tableHeaderBackgroundColor(context)),
        columns: [
          AppStyles.standardDataColumn(context, 'Customer'),
          AppStyles.standardDataColumn(context, 'Contact'),
          AppStyles.standardDataColumn(context, 'Balance'),
          AppStyles.standardDataColumn(context, 'Status'),
          AppStyles.standardDataColumn(context, 'Added Date'),
          AppStyles.actionsDataColumn(context),
        ],
        rows: filteredCustomers.map((customer) => _buildCustomerRow(context, customer)).toList(),
      ),
    );
  }

  DataRow _buildCustomerRow(BuildContext context, Customer customer) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _getBalanceColor(customer.creditBalance),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (customer.address?.isNotEmpty ?? false)
                    Text(
                      customer.address!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (customer.phoneNumber?.isNotEmpty ?? false)
                Text('📞 ${customer.phoneNumber}'),
              if (customer.email?.isNotEmpty ?? false)
                Text(
                  '✉️ ${customer.email}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Text(
            _getBalanceText(customer.creditBalance),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getBalanceColor(customer.creditBalance),
              fontSize: 16,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getBalanceColor(customer.creditBalance).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBalanceColor(customer.creditBalance).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _getBalanceLabel(customer.creditBalance),
              style: TextStyle(
                color: _getBalanceColor(customer.creditBalance),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(Text(DateFormat('MMM dd, yyyy').format(customer.createdAt))),
        DataCell(
          AppStyles.actionButtonRow(
            children: [
              AppStyles.viewButton(onPressed: () => _openCustomerDetail(customer)),
              IconButton(
                icon: Icon(Icons.south, color: Colors.green, size: 18),
                onPressed: () => _quickTransaction(customer, TransactionType.taken),
                tooltip: 'Quick Received',
                constraints: AppStyles.actionButtonConstraints,
              ),
              IconButton(
                icon: Icon(Icons.north, color: Colors.red, size: 18),
                onPressed: () => _quickTransaction(customer, TransactionType.given),
                tooltip: 'Quick Given',
                constraints: AppStyles.actionButtonConstraints,
              ),
              AppStyles.deleteButton(onPressed: () => _showDeleteConfirmation(customer)),
            ],
          ),
        ),
      ],
    );
  }

  List<Customer> _getFilteredCustomers(CustomerProvider provider) {
    List<Customer> customers = provider.customers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      customers = customers.where((customer) {
        return customer.name.toLowerCase().contains(_searchQuery) ||
               (customer.phoneNumber?.toLowerCase().contains(_searchQuery) ?? false) ||
               (customer.email?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Apply balance filter
    switch (_selectedFilter) {
      case 'debt':
        customers = customers.where((c) => c.hasDebt).toList();
        break;
      case 'credit':
        customers = customers.where((c) => c.hasCredit).toList();
        break;
      case 'clear':
        customers = customers.where((c) => c.creditBalance == 0).toList();
        break;
    }

    // Sort by balance amount (highest debt first, then highest credit)
    customers.sort((a, b) => b.creditBalance.compareTo(a.creditBalance));

    return customers;
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
    if (balance > 0) return 'Owes';
    if (balance < 0) return 'Credit';
    return 'Clear';
  }

  void _openCustomerDetail(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  void _submitCustomer() async {
    if (!_customerFormKey.currentState!.validate()) return;

    final customer = Customer(
      id: '',
      name: _customerNameController.text.trim(),
      phoneNumber: _customerPhoneController.text.trim().isEmpty ? null : _customerPhoneController.text.trim(),
      email: _customerEmailController.text.trim().isEmpty ? null : _customerEmailController.text.trim(),
      address: _customerAddressController.text.trim().isEmpty ? null : _customerAddressController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await context.read<CustomerProvider>().addCustomer(customer);
    if (success && mounted) {
      _clearCustomerForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer "${customer.name}" added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<CustomerProvider>().errorMessage ?? 'Failed to add customer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitTransaction() async {
    if (!_transactionFormKey.currentState!.validate()) return;

    final transaction = CreditTransaction(
      id: '',
      customerId: _selectedCustomerId,
      customerName: _selectedCustomerName,
      type: _selectedTransactionType,
      amount: double.parse(_transactionAmountController.text),
      note: _transactionNoteController.text.trim().isEmpty ? null : _transactionNoteController.text.trim(),
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final success = await context.read<CustomerProvider>().addCreditTransaction(transaction);
    if (success && mounted) {
      _clearTransactionForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction added for $_selectedCustomerName'),
          backgroundColor: _selectedTransactionType == TransactionType.taken
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  void _quickTransaction(Customer customer, TransactionType type) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${type == TransactionType.taken ? 'Money Received from' : 'Money Given to'} ${customer.name}',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              amountController.dispose();
              noteController.dispose();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final transaction = CreditTransaction(
                id: '',
                customerId: customer.id,
                customerName: customer.name,
                type: type,
                amount: double.parse(amountController.text),
                note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                transactionDate: DateTime.now(),
                createdAt: DateTime.now(),
              );

              final navigator = Navigator.of(context);
              final provider = context.read<CustomerProvider>();
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              final success = await provider.addCreditTransaction(transaction);
              if (success && mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Transaction added for ${customer.name}'),
                    backgroundColor: type == TransactionType.taken ? Colors.green : Colors.red,
                  ),
                );
              }

              amountController.dispose();
              noteController.dispose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: type == TransactionType.taken ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete "${customer.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final provider = context.read<CustomerProvider>();
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              // TODO: Implement delete customer functionality
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Delete functionality coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearCustomerForm() {
    _customerNameController.clear();
    _customerPhoneController.clear();
    _customerEmailController.clear();
    _customerAddressController.clear();
  }

  void _clearTransactionForm() {
    _transactionAmountController.clear();
    _transactionNoteController.clear();
    setState(() {
      _selectedCustomerId = '';
      _selectedCustomerName = '';
      _selectedTransactionType = TransactionType.taken;
    });
  }
}