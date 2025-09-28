import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_styles.dart';
import '../../../core/widgets/searchable_customer_field.dart';
import '../providers/photocopy_provider.dart';
import '../models/photocopy_models.dart';
import '../../customers/providers/customer_provider.dart';
import '../../customers/models/customer_model.dart';

class PhotocopyServiceScreen extends StatefulWidget {
  const PhotocopyServiceScreen({super.key});

  @override
  State<PhotocopyServiceScreen> createState() => _PhotocopyServiceScreenState();
}

class _PhotocopyServiceScreenState extends State<PhotocopyServiceScreen> {
  // final _incomeFormKey = GlobalKey<FormState>(); // TODO: Implement form validation
  final _expenseFormKey = GlobalKey<FormState>();

  // Income form controllers
  final _customAmountController = TextEditingController();
  final _customerController = TextEditingController();

  // Expense form controllers
  final _expenseTypeController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _expenseDescriptionController = TextEditingController();

  // DateTime _selectedIncomeDate = DateTime.now(); // TODO: Implement date selection
  DateTime _selectedExpenseDate = DateTime.now();

  // Month filtering state
  String? _selectedMonth;
  List<String> _availableMonths = [];

  // Income type state
  String _selectedIncomeType = 'B/W'; // Default to B/W
  final List<String> _incomeTypes = ['B/W', 'Color', 'Sticker'];

  // Customer and Udhar state
  bool _isUdharSelected = false;
  Customer? _selectedCustomer; // ignore: unused_field

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotocopyProvider>().loadAllData();
      context.read<CustomerProvider>().loadCustomers();
      _initializeMonthFilter();
    });
  }

  void _initializeMonthFilter() {
    final provider = context.read<PhotocopyProvider>();
    final months = <String>{};

    // Add months from income data
    for (final income in provider.incomes) {
      final monthYear = DateFormat('MMM yyyy').format(income.date);
      months.add(monthYear);
    }

    // Add months from expense data
    for (final expense in provider.expenses) {
      final monthYear = DateFormat('MMM yyyy').format(expense.date);
      months.add(monthYear);
    }

    // Sort months (most recent first)
    final sortedMonths = months.toList();
    sortedMonths.sort((a, b) {
      final dateA = DateFormat('MMM yyyy').parse(a);
      final dateB = DateFormat('MMM yyyy').parse(b);
      return dateB.compareTo(dateA);
    });

    setState(() {
      _availableMonths = sortedMonths;
      // Default to current month if available
      final currentMonth = DateFormat('MMM yyyy').format(DateTime.now());
      _selectedMonth = _availableMonths.contains(currentMonth) ? currentMonth : _availableMonths.isNotEmpty ? _availableMonths.first : null;
    });
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _customerController.dispose();
    _expenseTypeController.dispose();
    _expenseAmountController.dispose();
    _expenseDescriptionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photocopy Service'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Consumer<PhotocopyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Month filter and Stats Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppStyles.formCardDecoration(context),
                child: Column(
                  children: [
                    // Month filter dropdown
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Month Filter:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedMonth,
                            decoration: AppStyles.standardInputDecoration('Select Month'),
                            items: _availableMonths.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMonth = value;
                              });
                            },
                            hint: const Text('All Months'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats Summary (removed Total Copies)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Income',
                            '₨${_getFilteredStats(provider).totalIncome.toStringAsFixed(0)}',
                            Colors.green,
                            Icons.trending_up,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Total Expenses',
                            '₨${_getFilteredStats(provider).totalExpenses.toStringAsFixed(0)}',
                            Colors.red,
                            Icons.trending_down,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Net Profit',
                            '₨${_getFilteredStats(provider).netProfit.toStringAsFixed(0)}',
                            _getFilteredStats(provider).netProfit >= 0 ? Colors.blue : Colors.red,
                            Icons.account_balance_wallet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content - Two Column Layout
              Expanded(
                child: Row(
                  children: [
                    // Left side - Income section
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.05),
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income Management',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Make the income section scrollable
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Quick action buttons
                                    _buildQuickActionButtons(),
                                    const SizedBox(height: 24),

                                    // Income list
                                    _buildIncomeList(_getFilteredIncomes(provider.incomes)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right side - Expense section
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.red.withValues(alpha: 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expense Management',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Make the expense section scrollable
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Expense form
                                    _buildExpenseForm(),
                                    const SizedBox(height: 24),

                                    // Expense list
                                    _buildExpenseList(_getFilteredExpenses(provider.expenses)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildQuickActionButtons() {
    final amounts = [10, 20, 30, 50, 100, 150, 200, 500];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Amount Buttons',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),

        // First row: 10, 20, 30, 50
        Row(
          children: amounts.take(4).map((amount) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ElevatedButton(
                onPressed: () => _addQuickIncomeByAmount(amount.toDouble()),
                child: Text('₨$amount'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 6),

        // Second row: 100, 150, 200, 500
        Row(
          children: amounts.skip(4).map((amount) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ElevatedButton(
                onPressed: () => _addQuickIncomeByAmount(amount.toDouble()),
                child: Text('₨$amount'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),

        // Income type dropdown
        DropdownButtonFormField<String>(
          value: _selectedIncomeType,
          decoration: AppStyles.standardInputDecoration('Income Type'),
          items: _incomeTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedIncomeType = value ?? 'B/W';
            });
          },
        ),
        const SizedBox(height: 12),

        // Custom amount field
        TextFormField(
          controller: _customAmountController,
          decoration: AppStyles.standardInputDecoration('Custom Amount'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),

        // Customer and Udhar section
        UdharCustomerSection(
          customerController: _customerController,
          isUdharSelected: _isUdharSelected,
          onUdharChanged: (value) {
            setState(() {
              _isUdharSelected = value;
              if (!value) {
                _customerController.clear();
                _selectedCustomer = null;
              }
            });
          },
          onCustomerSelected: (customer) {
            _selectedCustomer = customer;
          },
        ),
        const SizedBox(height: 12),

        // Add button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addCustomAmount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text('Add Income'),
          ),
        ),
      ],
    );
  }


  Widget _buildExpenseForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _expenseFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Expense',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _expenseTypeController.text.isEmpty ? null : _expenseTypeController.text,
                decoration: const InputDecoration(
                  labelText: 'Expense Type',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Machine Purchase', child: Text('Machine Purchase')),
                  DropdownMenuItem(value: 'Ink Refill', child: Text('Ink Refill')),
                  DropdownMenuItem(value: 'Paper Purchase', child: Text('Paper Purchase')),
                  DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  _expenseTypeController.text = value ?? '';
                },
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _expenseAmountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _expenseDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitExpense,
                  icon: const Icon(Icons.remove),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeList(List<PhotocopyIncome> incomes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Income',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        incomes.isEmpty
            ? Container(
                height: 200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No income entries yet'),
                      Text('Use quick actions above to add income'),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: incomes.length,
                itemBuilder: (context, index) {
                  final income = incomes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        income.customerName ?? 'Cash Income',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Type: ${income.incomeType ?? 'B/W'} • Amount: ₨${income.totalAmount.toStringAsFixed(0)}\n'
                        '${DateFormat('MMM dd, yyyy').format(income.date)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₨${income.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () => _deleteIncome(income.id),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildExpenseList(List<PhotocopyExpense> expenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Expenses',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        expenses.isEmpty
            ? Container(
                height: 200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No expense entries yet'),
                      Text('Use the form above to add expenses'),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(
                          _getExpenseIcon(expense.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        expense.type,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${expense.description}\n'
                        '${DateFormat('MMM dd, yyyy').format(expense.date)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₨${expense.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () => _deleteExpense(expense.id),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ],
    );
  }

  IconData _getExpenseIcon(String type) {
    switch (type.toLowerCase()) {
      case 'machine purchase':
        return Icons.print;
      case 'ink refill':
        return Icons.colorize;
      case 'paper purchase':
        return Icons.description;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.attach_money;
    }
  }

  void _addQuickIncomeByAmount(double amount) async {
    final income = PhotocopyIncome(
      id: '',
      copies: 1, // We don't track copies anymore, just amount
      ratePerCopy: amount,
      totalAmount: amount,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      incomeType: 'B/W', // Default B/W for quick buttons
    );

    final success = await context.read<PhotocopyProvider>().addIncome(income);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Income added: ₨${amount.toStringAsFixed(0)} (B/W)'),
          backgroundColor: Colors.green,
        ),
      );
      _initializeMonthFilter(); // Refresh month filter
    }
  }

  void _addCustomAmount() async {
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

    // Validate customer name if udhar is selected
    if (_isUdharSelected && _customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer name is required for Udhar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final customerName = _customerController.text.trim();

    // Add income
    final income = PhotocopyIncome(
      id: '',
      copies: 1, // We don't track copies anymore, just amount
      ratePerCopy: amount,
      totalAmount: amount,
      customerName: customerName.isNotEmpty ? customerName : null,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      incomeType: _selectedIncomeType,
    );

    final photocopyProvider = context.read<PhotocopyProvider>();
    final customerProvider = context.read<CustomerProvider>();

    final success = await photocopyProvider.addIncome(income);
    if (!success) return;

    // Add udhar transaction if selected
    if (_isUdharSelected && customerName.isNotEmpty) {
      final udharSuccess = await customerProvider.addUdharTransaction(
        customerName: customerName,
        amount: amount,
        source: 'photocopy',
      );

      if (!udharSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income added but failed to create Udhar record'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (mounted) {
      final message = _isUdharSelected
          ? 'Income added: ₨${amount.toStringAsFixed(0)} ($_selectedIncomeType) - Added to Udhar for $customerName'
          : 'Income added: ₨${amount.toStringAsFixed(0)} ($_selectedIncomeType)';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
      _initializeMonthFilter(); // Refresh month filter
      _customAmountController.clear();
      _customerController.clear();
      setState(() {
        _isUdharSelected = false;
        _selectedCustomer = null;
      });
    }
  }


  void _submitExpense() async {
    if (!_expenseFormKey.currentState!.validate()) return;

    final expense = PhotocopyExpense(
      id: '',
      type: _expenseTypeController.text,
      amount: double.parse(_expenseAmountController.text),
      description: _expenseDescriptionController.text,
      date: _selectedExpenseDate,
      createdAt: DateTime.now(),
    );

    final success = await context.read<PhotocopyProvider>().addExpense(expense);
    if (success && mounted) {
      _clearExpenseForm();
      _initializeMonthFilter(); // Refresh month filter
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added successfully'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteIncome(String incomeId) async {
    final success = await context.read<PhotocopyProvider>().deleteIncome(incomeId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income entry deleted')),
      );
    }
  }

  void _deleteExpense(String expenseId) async {
    final success = await context.read<PhotocopyProvider>().deleteExpense(expenseId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense entry deleted')),
      );
    }
  }


  void _clearExpenseForm() {
    _expenseTypeController.clear();
    _expenseAmountController.clear();
    _expenseDescriptionController.clear();
    setState(() {
      _selectedExpenseDate = DateTime.now();
    });
  }

  // Helper methods for month filtering
  List<PhotocopyIncome> _getFilteredIncomes(List<PhotocopyIncome> incomes) {
    if (_selectedMonth == null) return incomes;

    return incomes.where((income) {
      final incomeMonth = DateFormat('MMM yyyy').format(income.date);
      return incomeMonth == _selectedMonth;
    }).toList();
  }

  List<PhotocopyExpense> _getFilteredExpenses(List<PhotocopyExpense> expenses) {
    if (_selectedMonth == null) return expenses;

    return expenses.where((expense) {
      final expenseMonth = DateFormat('MMM yyyy').format(expense.date);
      return expenseMonth == _selectedMonth;
    }).toList();
  }

  PhotocopyStats _getFilteredStats(PhotocopyProvider provider) {
    final filteredIncomes = _getFilteredIncomes(provider.incomes);
    final filteredExpenses = _getFilteredExpenses(provider.expenses);

    final totalIncome = filteredIncomes.fold(0.0, (sum, income) => sum + income.totalAmount);
    final totalExpenses = filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final netProfit = totalIncome - totalExpenses;
    final totalCopies = filteredIncomes.fold(0, (sum, income) => sum + income.copies);

    return PhotocopyStats(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      totalCopies: totalCopies,
      lastUpdated: DateTime.now(),
    );
  }
}