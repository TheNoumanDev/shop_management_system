import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/widgets/searchable_customer_field.dart';
import '../providers/data_transfer_provider.dart';
import '../models/data_transfer_models.dart';
import '../../customers/providers/customer_provider.dart';
import '../../customers/models/customer_model.dart';

class DataTransferServiceScreen extends StatefulWidget {
  const DataTransferServiceScreen({super.key});

  @override
  State<DataTransferServiceScreen> createState() => _DataTransferServiceScreenState();
}

class _DataTransferServiceScreenState extends State<DataTransferServiceScreen> {
  final _customAmountController = TextEditingController();
  final _customerNameController = TextEditingController();
  bool _isUdharSelected = false;
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataTransferProvider>(context, listen: false).loadIncomes();
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    });
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with stats
          _buildHeader(context),

          // Income section
          _buildIncomeSection(context),

          // Data Transfer History - Fixed scrolling issue
          Container(
            height: MediaQuery.of(context).size.height * 0.5, // Increased height
            child: Consumer<DataTransferProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(provider.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadIncomes(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final incomes = provider.incomes;
                if (incomes.isEmpty) {
                  return const Center(
                    child: Text('No data transfer records yet'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: incomes.length,
                  itemBuilder: (context, index) {
                    final income = incomes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Text(
                            '₨',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '₨${income.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (income.customerName?.isNotEmpty ?? false)
                              Text('Customer: ${income.customerName}'),
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a').format(income.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppStyles.editButton(
                              onPressed: () => _editIncome(income),
                            ),
                            AppStyles.deleteButton(
                              onPressed: () => _deleteIncome(income),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<DataTransferProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.data_object, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Transfer Service',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Simple data transfer income tracking',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatChip('Total', '₨${provider.totalIncome.toStringAsFixed(0)}', Colors.green, Icons.trending_up),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSection(BuildContext context) {
    return AppStyles.formCardWithHeader(
      context: context,
      title: 'Add Data Transfer Income',
      icon: Icons.add_circle,
      child: Column(
        children: [
          // Quick amount buttons
          _buildQuickAmountButtons(),
          const SizedBox(height: 16),

          // Custom amount input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customAmountController,
                  keyboardType: TextInputType.number,
                  decoration: AppStyles.standardInputDecoration(
                    'Custom Amount (${AppConstants.currencySymbol})',
                    prefixText: AppConstants.currencySymbol,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _addCustomAmount,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Customer field with Udhar option
          SearchableCustomerField(
            controller: _customerNameController,
            labelText: _isUdharSelected ? 'Customer Name *' : 'Customer Name (Optional)',
            isRequired: _isUdharSelected,
            onCustomerSelected: (customer) {
              setState(() {
                _selectedCustomer = customer;
              });
            },
          ),
          const SizedBox(height: 12),

          // Udhar checkbox
          Row(
            children: [
              Checkbox(
                value: _isUdharSelected,
                onChanged: (value) {
                  setState(() {
                    _isUdharSelected = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isUdharSelected = !_isUdharSelected;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: 'Keep for '),
                        TextSpan(
                          text: 'Udhar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const TextSpan(text: ' (Add to customer credit)'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButtons() {
    final amounts = AppConstants.dataTransferRates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Add Amount:',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: amounts.take(4).map((amount) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: () => _addQuickAmount(amount),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text('₨$amount'),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: amounts.skip(4).map((amount) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: () => _addQuickAmount(amount),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text('₨$amount'),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Future<void> _addQuickAmount(int amount) async {
    await _addIncome(amount.toDouble());
  }

  Future<void> _addCustomAmount() async {
    final amountText = _customAmountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _addIncome(amount);
  }

  Future<void> _addIncome(double amount) async {
    final customerName = _customerNameController.text.trim();

    // Validate customer name if udhar is selected
    if (_isUdharSelected && customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer name is required for Udhar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<DataTransferProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

    final income = DataTransferIncome(
      id: '',
      totalAmount: amount,
      customerName: customerName.isEmpty ? null : customerName,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final success = await provider.addIncome(income);
    if (!success) return;

    // Add udhar transaction if selected
    if (_isUdharSelected && customerName.isNotEmpty) {
      final udharSuccess = await customerProvider.addUdharTransaction(
        customerName: customerName,
        amount: amount,
        source: 'data_transfer',
      );

      if (!udharSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add Udhar transaction'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // Clear form
    if (mounted) {
      setState(() {
        _customAmountController.clear();
        _customerNameController.clear();
        _isUdharSelected = false;
        _selectedCustomer = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data transfer income of ₨${amount.toStringAsFixed(0)} added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editIncome(DataTransferIncome income) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteIncome(DataTransferIncome income) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income Record'),
        content: Text('Are you sure you want to delete this ₨${income.totalAmount.toStringAsFixed(0)} record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<DataTransferProvider>(context, listen: false);
              final success = await provider.deleteIncome(income.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Income record deleted successfully'
                        : 'Failed to delete income record'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}