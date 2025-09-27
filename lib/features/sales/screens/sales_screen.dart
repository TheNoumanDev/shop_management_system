import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_styles.dart';
import '../providers/sales_provider.dart';
import '../models/sale_model.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../inventory/models/product_model.dart';
import '../../customers/providers/customer_provider.dart';
import '../../customers/models/customer_model.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _searchQuery = '';
  Sale? _editingSale;

  // Form controllers for sale form
  final _saleFormKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _sellingPriceController = TextEditingController();
  final _customerController = TextEditingController();
  Product? _selectedProduct;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesProvider>(context, listen: false).loadSales();
      Provider.of<InventoryProvider>(context, listen: false).loadProducts();
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _sellingPriceController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with stats
        _buildHeader(context),

        // Sales Form (always visible)
        _buildSalesForm(context),

        // Search filters
        _buildSearchSection(context),

        // Sales list
        Expanded(
          child: Consumer<SalesProvider>(
            builder: (context, salesProvider, child) {
              if (salesProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (salesProvider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(salesProvider.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => salesProvider.loadSales(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredSales = _filterSales(salesProvider.currentMonthSales);

              if (filteredSales.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.point_of_sale_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No sales found matching your search'
                            : 'No sales recorded yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Use the form above to record your first sale',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSalesTable(context, filteredSales),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSalesForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
            Theme.of(context).primaryColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header with primary color background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppStyles.cardHeaderDecoration(context),
              child: Row(
                children: [
                  Icon(
                    _editingSale == null ? Icons.point_of_sale : Icons.edit,
                    color: AppStyles.sectionHeaderIconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _editingSale == null ? 'Record New Sale' : 'Edit Sale',
                    style: AppStyles.sectionHeaderStyle(context),
                  ),
                  const Spacer(),
                  if (_editingSale != null)
                    IconButton(
                      onPressed: () => _cancelSaleForm(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Cancel Edit',
                    ),
                ],
              ),
            ),
            // Form content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _saleFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const SizedBox(height: 20),

                // Row 1: Product Search
                Consumer<InventoryProvider>(
                  builder: (context, inventoryProvider, child) {
                    final availableProducts = inventoryProvider.products
                        .where((product) => product.currentStock > 0)
                        .toList();

                    return Autocomplete<Product>(
                      displayStringForOption: (Product product) =>
                          '${product.name} (Stock: ${product.currentStock})',
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return availableProducts.take(10);
                        }
                        return availableProducts.where((Product product) {
                          return product.name.toLowerCase().contains(
                              textEditingValue.text.toLowerCase());
                        }).take(10);
                      },
                      onSelected: (Product product) {
                        _onProductSelected(product);
                      },
                      fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController controller,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Search & Select Product *',
                            hintText: 'Type product name to search...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(Icons.search),
                          ),
                          validator: (value) {
                            if (_selectedProduct == null) {
                              return 'Please select a product';
                            }
                            return null;
                          },
                          onFieldSubmitted: (value) => onFieldSubmitted(),
                        );
                      },
                    );
                  },
                ),
                if (_selectedProduct != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected: ${_selectedProduct!.name} (Stock: ${_selectedProduct!.currentStock})',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_totalAmount > 0)
                                Text(
                                  'Total Amount: ${AppConstants.currencySymbol}${_totalAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Row 2: Quantity, Selling Price, Customer
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          // Update selling price when quantity changes
                          _updateTotalAmount();
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Quantity is required';
                          }
                          final quantity = int.tryParse(value);
                          if (quantity == null || quantity <= 0) {
                            return 'Enter a valid quantity';
                          }
                          if (_selectedProduct != null && quantity > _selectedProduct!.currentStock) {
                            return 'Max ${_selectedProduct!.currentStock} available';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Unit Price (${AppConstants.currencySymbol}) *',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          // Update total when price changes
                          _updateTotalAmount();
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Selling price is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter a valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<CustomerProvider>(
                        builder: (context, customerProvider, child) {
                          return Autocomplete<Customer>(
                            displayStringForOption: (Customer customer) => customer.name,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return customerProvider.customers.take(5);
                              }
                              return customerProvider.searchCustomers(textEditingValue.text);
                            },
                            onSelected: (Customer customer) {
                              _customerController.text = customer.name;
                            },
                            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                              // Sync with our main controller
                              if (controller.text != _customerController.text) {
                                controller.text = _customerController.text;
                              }
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                onEditingComplete: onEditingComplete,
                                onChanged: (value) {
                                  _customerController.text = value;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Customer Name (Optional)',
                                  border: OutlineInputBorder(),
                                  hintText: 'Type to search or add new customer',
                                ),
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final customer = options.elementAt(index);
                                        return ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            radius: 16,
                                            backgroundColor: customer.hasDebt
                                                ? Colors.red
                                                : customer.hasCredit
                                                    ? Colors.green
                                                    : Colors.grey,
                                            child: Text(
                                              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            customer.name,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: customer.phoneNumber?.isNotEmpty ?? false
                                              ? Text('📞 ${customer.phoneNumber}')
                                              : null,
                                          trailing: customer.creditBalance != 0
                                              ? Text(
                                                  '₹${customer.creditBalance.abs().toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    color: customer.hasDebt ? Colors.red : Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : null,
                                          onTap: () => onSelected(customer),
                                        );
                                      },
                                    ),
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
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => _cancelSaleForm(),
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _selectedProduct != null ? _handleSaleSubmit : null,
                      child: Text(_editingSale == null ? 'Record Sale' : 'Update Sale'),
                    ),
                  ],
                ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search sales by product or customer...',
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
    );
  }

  Widget _buildSalesTable(BuildContext context, List<Sale> sales) {
    final ScrollController _horizontalScrollController = ScrollController();

    return Card(
      child: SizedBox(
        width: 1500,
        height: double.infinity,
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notif) => notif.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1500, // Fixed table width
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 4,
                  horizontalMargin: 4,
                  headingRowColor: WidgetStateProperty.all(AppStyles.tableHeaderBackgroundColor(context)),
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width: 250, // Adjusted width
                        child: Text('Product', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150, // Adjusted width
                        child: Text('Customer', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150, // Adjusted width
                        child: Text('Quantity', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150, // Adjusted width
                        child: Text('Total Amount', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150, // Adjusted width
                        child: Text('Profit', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150, // Adjusted width
                        child: Text('Date', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150, // Adjusted width for actions
                        child: Text('Actions', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                  ],
                  rows: sales.map((sale) => _buildSaleRow(context, sale)).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildSaleRow(BuildContext context, Sale sale) {
    return DataRow(
      cells: [
        DataCell(SizedBox(
          width: 250,
          child: Text(sale.productName),
        )),
        DataCell(SizedBox(
          width: 150,
          child: Text(sale.customerName ?? 'Walk-in'),
        )),
        DataCell(SizedBox(
          width: 150,
          child: Text(sale.quantity.toString()),
        )),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              '${AppConstants.currencySymbol}${sale.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        )),
        DataCell(SizedBox(
          width: 150,
          child: Text(
            '${AppConstants.currencySymbol}${sale.profit.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: sale.profit > 0 ? Colors.green : Colors.red,
            ),
          ),
        )),
        DataCell(SizedBox(
          width: 150,
          child: Text(DateFormat('MMM dd, HH:mm').format(sale.saleDate)),
        )),
        DataCell(
          AppStyles.actionButtonRow(
            minWidth: 140,
            children: [
              AppStyles.editButton(
                onPressed: () => _editSale(sale),
                tooltip: 'Edit Sale',
              ),
              AppStyles.deleteButton(
                onPressed: () => _showDeleteConfirmation(context, sale),
                tooltip: 'Delete Sale',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onProductSelected(Product product) {
    setState(() {
      _selectedProduct = product;
      // Auto-fill selling price with the product's selling price
      _sellingPriceController.text = product.sellingPrice.toStringAsFixed(0);
      _updateTotalAmount();
    });
  }

  void _updateTotalAmount() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
    setState(() {
      _totalAmount = quantity * unitPrice;
    });
  }

  void _editSale(Sale sale) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _cancelSaleForm() {
    setState(() {
      _selectedProduct = null;
      _editingSale = null;
      _quantityController.text = '1';
      _sellingPriceController.clear();
      _customerController.clear();
      _totalAmount = 0.0;
    });
  }

  Future<void> _handleSaleSubmit() async {
    if (!_saleFormKey.currentState!.validate() || _selectedProduct == null) return;

    final quantity = int.parse(_quantityController.text);
    final sellingPrice = double.parse(_sellingPriceController.text);
    final totalAmount = quantity * sellingPrice;
    final profit = quantity * (sellingPrice - _selectedProduct!.purchasePrice);

    final sale = Sale(
      id: _editingSale?.id ?? '',
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      quantity: quantity,
      sellingPrice: sellingPrice,
      purchasePrice: _selectedProduct!.purchasePrice,
      totalAmount: totalAmount,
      profit: profit,
      customerName: _customerController.text.trim().isEmpty
          ? null
          : _customerController.text.trim(),
      saleDate: DateTime.now(),
      createdAt: _editingSale?.createdAt ?? DateTime.now(),
    );

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    bool success;

    // For now, we only support adding new sales
    // TODO: Implement updateSale in SalesProvider if editing is needed
    success = await salesProvider.addSale(sale);

    if (success && mounted) {
      _cancelSaleForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingSale == null
                ? 'Sale recorded successfully'
                : 'Sale updated successfully',
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.errorMessage ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Sale> _filterSales(List<Sale> sales) {
    if (_searchQuery.isEmpty) return sales;

    return sales.where((sale) {
      return sale.productName.toLowerCase().contains(_searchQuery) ||
             (sale.customerName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Consumer<SalesProvider>(
                      builder: (context, provider, child) {
                        final now = DateTime.now();
                        final monthName = DateFormat('MMMM yyyy').format(now);
                        return Text(
                          '${provider.currentMonthSales.length} sales this month ($monthName) • ${provider.todaysSales.length} today',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Consumer<SalesProvider>(
                builder: (context, provider, child) {
                  return PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 8),
                            Text('Refresh'),
                          ],
                        ),
                        onTap: () => provider.loadSales(),
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.data_saver_on),
                            SizedBox(width: 8),
                            Text('Add Dummy Data'),
                          ],
                        ),
                        onTap: () => provider.addDummyData(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quick stats
          Consumer<SalesProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Month Sales',
                      '${AppConstants.currencySymbol}${provider.currentMonthSalesAmount.toStringAsFixed(0)}',
                      Colors.green,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Month Profit',
                      '${AppConstants.currencySymbol}${provider.currentMonthProfit.toStringAsFixed(0)}',
                      Colors.blue,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Today\'s Sales',
                      '${provider.todaysSales.length}',
                      Colors.orange,
                      Icons.today,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  void _showDeleteConfirmation(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sale'),
        content: Text('Are you sure you want to delete this sale of "${sale.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await Provider.of<SalesProvider>(context, listen: false)
                  .deleteSale(sale.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sale deleted successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}