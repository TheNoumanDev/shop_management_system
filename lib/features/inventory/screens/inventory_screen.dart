import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_styles.dart';
import '../providers/inventory_provider.dart';
import '../models/product_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  Product? _editingProduct;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minStockController = TextEditingController();
  String _formSelectedCategory = AppConstants.mobileAccessoryCategories.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with actions
        _buildHeader(context),

        // Add/Edit Product Form (always visible)
        _buildProductForm(context),

        // Filters and search
        _buildFilters(context),

        // Products list
        Expanded(
          child: Consumer<InventoryProvider>(
            builder: (context, inventoryProvider, child) {
              if (inventoryProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (inventoryProvider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(inventoryProvider.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => inventoryProvider.loadProducts(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredProducts = _filterProducts(inventoryProvider.products);

              if (filteredProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != 'All'
                            ? 'No products found matching your criteria'
                            : 'No products in inventory',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Use the form above to add your first product',
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
                child: _buildProductsTable(context, filteredProducts),
              );
            },
          ),
        ),
      ],
    );
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      '${provider.products.length} products • ${provider.lowStockProducts.length} low stock',
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
          Consumer<InventoryProvider>(
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
                    onTap: () => provider.loadProducts(),
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
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
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
          const SizedBox(height: 16),
          
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All'),
                ...AppConstants.mobileAccessoryCategories.map(
                  (category) => _buildCategoryChip(category),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          category,
          style: isSelected
              ? AppStyles.selectedFilterChipTextStyle(context)
              : AppStyles.unselectedFilterChipTextStyle(context),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Theme.of(context).primaryColor,
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildProductsTable(BuildContext context, List<Product> products) {
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
                        width: 250,
                        child: Text('Product Name', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150,
                        child: Text('Category', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150,
                        child: Text('Purchase Price', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150,
                        child: Text('Selling Price', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150,
                        child: Text('Stock', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 150,
                        child: Text('Actions', style: AppStyles.tableHeaderStyle(context)),
                      ),
                    ),
                  ],
                  rows: products.map((product) => _buildProductRow(context, product)).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildProductRow(BuildContext context, Product product) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 250,
            child: Text(
              product.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(product.category),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text('${AppConstants.currencySymbol}${product.purchasePrice.toStringAsFixed(0)}'),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text('${AppConstants.currencySymbol}${product.sellingPrice.toStringAsFixed(0)}'),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${product.currentStock}'),
                if (product.isLowStock) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.warning,
                    color: product.isOutOfStock ? Colors.red : Colors.orange,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: AppStyles.actionButtonRow(
              minWidth: 140,
              children: [
                AppStyles.editButton(
                  onPressed: () => _populateFormForEdit(product),
                  tooltip: 'Edit Product',
                ),
                AppStyles.deleteButton(
                  onPressed: () => _showDeleteConfirmation(context, product),
                  tooltip: 'Delete Product',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildProductForm(BuildContext context) {
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
                    _editingProduct == null ? Icons.add_box : Icons.edit,
                    color: AppStyles.sectionHeaderIconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _editingProduct == null ? 'Add New Product' : 'Edit Product',
                    style: AppStyles.sectionHeaderStyle(context),
                  ),
                  const Spacer(),
                  if (_editingProduct != null)
                    IconButton(
                      onPressed: () => _cancelForm(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Cancel Edit',
                    ),
                ],
              ),
            ),
            // Form content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                // Row 1: Product Name and Category
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Product name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _formSelectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: AppConstants.mobileAccessoryCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _formSelectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 2: Purchase Price and Selling Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Purchase Price (${AppConstants.currencySymbol}) *',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          // Auto-calculate selling price when purchase price changes
                          final purchasePrice = double.tryParse(value);
                          if (purchasePrice != null) {
                            _sellingPriceController.text = (purchasePrice * 2).toStringAsFixed(0);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Purchase price is required';
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
                      child: TextFormField(
                        controller: _sellingPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Selling Price (${AppConstants.currencySymbol}) *',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
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
                  ],
                ),
                const SizedBox(height: 16),

                // Row 3: Stock fields
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currentStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Current Stock *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Stock is required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock Level (Optional)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
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
                      onPressed: () => _cancelForm(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _handleFormSubmit(),
                      child: Text(_editingProduct == null ? 'Add Product' : 'Update Product'),
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

  void _clearForm() {
    _nameController.clear();
    _purchasePriceController.clear();
    _sellingPriceController.clear();
    _currentStockController.clear();
    _minStockController.clear();
    _formSelectedCategory = AppConstants.mobileAccessoryCategories.first;
    _editingProduct = null;
  }

  void _cancelForm() {
    setState(() {
      _clearForm();
    });
  }

  void _populateFormForEdit(Product product) {
    _nameController.text = product.name;
    _purchasePriceController.text = product.purchasePrice.toString();
    _sellingPriceController.text = product.sellingPrice.toString();
    _currentStockController.text = product.currentStock.toString();
    _minStockController.text = product.minStockLevel.toString();
    _formSelectedCategory = product.category;
    setState(() {
      _editingProduct = product;
    });
  }

  Future<void> _handleFormSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: _editingProduct?.id ?? '',
      name: _nameController.text.trim(),
      category: _formSelectedCategory,
      purchasePrice: double.parse(_purchasePriceController.text),
      sellingPrice: double.parse(_sellingPriceController.text),
      currentStock: int.parse(_currentStockController.text),
      minStockLevel: int.tryParse(_minStockController.text) ?? 0,
      description: null,
      createdAt: _editingProduct?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

    bool success;
    if (_editingProduct == null) {
      success = await inventoryProvider.addProduct(product);
    } else {
      success = await inventoryProvider.updateProduct(product);
    }

    if (success && mounted) {
      _cancelForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingProduct == null
                ? 'Product added successfully'
                : 'Product updated successfully',
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(inventoryProvider.errorMessage ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery) ||
          product.category.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }



  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await Provider.of<InventoryProvider>(context, listen: false)
                  .deleteProduct(product.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted successfully')),
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