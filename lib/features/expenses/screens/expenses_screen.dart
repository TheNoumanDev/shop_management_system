import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_styles.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  ExpenseType _selectedType = ExpenseType.electricity;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'all';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Expenses'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_dummy',
                child: Row(
                  children: [
                    Icon(Icons.data_object),
                    SizedBox(width: 8),
                    Text('Add Dummy Data'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'add_dummy') {
                context.read<ExpenseProvider>().addDummyData();
              }
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Stats and Controls Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: [
                    // Stats Cards - Simplified and more valuable
                    Consumer<ExpenseProvider>(
                      builder: (context, provider, child) {
                        final currentMonthExpenses = _getFilteredExpenses(provider);
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'This Month',
                                '₨${provider.currentMonthTotal.toStringAsFixed(0)}',
                                Colors.red,
                                Icons.calendar_month,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Total Entries',
                                '${currentMonthExpenses.length}',
                                Colors.blue,
                                Icons.receipt_long,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Avg per Entry',
                                currentMonthExpenses.isNotEmpty
                                    ? '₨${(provider.currentMonthTotal / currentMonthExpenses.length).toStringAsFixed(0)}'
                                    : '₨0',
                                Colors.green,
                                Icons.analytics,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filters
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedFilter,
                            decoration: const InputDecoration(
                              labelText: 'Filter by Type',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Expenses')),
                              DropdownMenuItem(value: 'electricity', child: Text('Electricity')),
                              DropdownMenuItem(value: 'internet', child: Text('Internet')),
                              DropdownMenuItem(value: 'rent', child: Text('Rent')),
                              DropdownMenuItem(value: 'miscellaneous', child: Text('Miscellaneous')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedFilter = value ?? 'all';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: List.generate(12, (index) {
                              final month = index + 1;
                              return DropdownMenuItem(
                                value: month,
                                child: Text(DateFormat('MMMM').format(DateTime(2024, month))),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedMonth = value ?? DateTime.now().month;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: List.generate(5, (index) {
                              final year = DateTime.now().year - 2 + index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value ?? DateTime.now().year;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Add Expense Form (always visible)
              _buildAddExpenseForm(),

              // Expense List
              Expanded(
                child: _buildExpenseList(provider),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddExpenseForm() {
    return AppStyles.formCardWithHeader(
      context: context,
      title: 'Add New Expense',
      icon: Icons.add_box,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ExpenseType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Expense Type *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    items: ExpenseType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getExpenseIcon(type), size: 20),
                            const SizedBox(width: 8),
                            Text(_getExpenseDisplayName(type)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value ?? ExpenseType.electricity;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _titleController,
                    decoration: AppStyles.standardInputDecoration('Title *'),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) return 'Title is required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: AppStyles.standardInputDecoration('Amount *', prefixText: '₨'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) return 'Amount is required';
                      if (double.tryParse(value!) == null) return 'Invalid amount';
                      if (double.parse(value) <= 0) return 'Amount must be positive';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: AppStyles.standardInputDecoration('Description'),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _submitExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearForm,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList(ExpenseProvider provider) {
    final filteredExpenses = _getFilteredExpenses(provider);

    if (filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No expenses found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Add your first expense using the + button above'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildExpensesTable(context, filteredExpenses),
    );
  }

  Widget _buildExpensesTable(BuildContext context, List<ShopExpense> expenses) {
    return AppStyles.responsiveTable(
      context: context,
      dataTable: DataTable(
        columnSpacing: 16,
        horizontalMargin: 12,
        headingRowColor: WidgetStateProperty.all(AppStyles.tableHeaderBackgroundColor(context)),
        columns: [
          AppStyles.standardDataColumn(context, 'Type'),
          AppStyles.standardDataColumn(context, 'Title'),
          AppStyles.standardDataColumn(context, 'Description'),
          AppStyles.standardDataColumn(context, 'Amount'),
          AppStyles.standardDataColumn(context, 'Date'),
          AppStyles.actionsDataColumn(context),
        ],
        rows: expenses.map((expense) => _buildExpenseRow(context, expense)).toList(),
      ),
    );
  }

  DataRow _buildExpenseRow(BuildContext context, ShopExpense expense) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getExpenseIcon(expense.type),
                color: _getExpenseTypeColor(expense.type),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                expense.typeDisplayName,
                style: TextStyle(
                  color: _getExpenseTypeColor(expense.type),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            expense.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Text(
            expense.description ?? '-',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          Text(
            '₨${expense.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        DataCell(Text(DateFormat('MMM dd, yyyy').format(expense.expenseDate))),
        DataCell(
          AppStyles.actionButtonRow(
            children: [
              AppStyles.editButton(onPressed: () => _editExpense(expense)),
              AppStyles.deleteButton(onPressed: () => _showDeleteConfirmation(expense)),
            ],
          ),
        ),
      ],
    );
  }

  void _editExpense(ShopExpense expense) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }


  List<ShopExpense> _getFilteredExpenses(ExpenseProvider provider) {
    List<ShopExpense> expenses = provider.expenses;

    // Filter by type
    if (_selectedFilter != 'all') {
      final type = ExpenseType.values.firstWhere(
        (e) => e.toString().split('.').last == _selectedFilter,
        orElse: () => ExpenseType.miscellaneous,
      );
      expenses = provider.getExpensesByType(type);
    }

    // Filter by month/year
    expenses = provider.getExpensesForMonth(_selectedYear, _selectedMonth);

    return expenses;
  }


  Color _getExpenseTypeColor(ExpenseType type) {
    switch (type) {
      case ExpenseType.electricity:
        return Colors.yellow.shade700;
      case ExpenseType.internet:
        return Colors.blue;
      case ExpenseType.rent:
        return Colors.purple;
      case ExpenseType.miscellaneous:
        return Colors.grey;
    }
  }

  IconData _getExpenseIcon(ExpenseType type) {
    switch (type) {
      case ExpenseType.electricity:
        return Icons.electrical_services;
      case ExpenseType.internet:
        return Icons.wifi;
      case ExpenseType.rent:
        return Icons.home;
      case ExpenseType.miscellaneous:
        return Icons.miscellaneous_services;
    }
  }

  String _getExpenseDisplayName(ExpenseType type) {
    switch (type) {
      case ExpenseType.electricity:
        return 'Electricity Bill';
      case ExpenseType.internet:
        return 'Internet Bill';
      case ExpenseType.rent:
        return 'Shop Rent';
      case ExpenseType.miscellaneous:
        return 'Miscellaneous';
    }
  }

  void _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final expense = ShopExpense(
      id: '',
      type: _selectedType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      amount: double.parse(_amountController.text),
      expenseDate: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await context.read<ExpenseProvider>().addExpense(expense);
    if (success && mounted) {
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense "${expense.title}" added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<ExpenseProvider>().errorMessage ?? 'Failed to add expense'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _titleController.clear();
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedType = ExpenseType.electricity;
      _selectedDate = DateTime.now();
    });
  }

  void _showDeleteConfirmation(ShopExpense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final provider = context.read<ExpenseProvider>();
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final success = await provider.deleteExpense(expense.id);
              if (success && mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Expense deleted successfully'),
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