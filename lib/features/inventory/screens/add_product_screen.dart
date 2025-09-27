import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/inventory_provider.dart';
import '../models/product_model.dart';

class AddProductDialog extends StatefulWidget {
  final Product? product; // For editing existing product

  const AddProductDialog({super.key, this.product});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = AppConstants.mobileAccessoryCategories.first;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _purchasePriceController.text = product.purchasePrice.toString();
    _currentStockController.text = product.currentStock.toString();
    _minStockController.text = product.minStockLevel.toString();
    _descriptionController.text = product.description ?? '';
    _selectedCategory = product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.product == null ? 'Add New Product' : 'Edit Product',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Product Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Product name is required'),
                          MinLengthValidator(2, errorText: 'Name must be at least 2 characters'),
                        ]).call,
                      ),
                      const SizedBox(height: 16),

                      // Category
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: AppConstants.mobileAccessoryCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                        validator: RequiredValidator(errorText: 'Please select a category').call,
                      ),
                      const SizedBox(height: 16),

                      // Purchase Price
                      TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Purchase Price (${AppConstants.currencySymbol}) *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Purchase price is required'),
                          PatternValidator(r'^\d+(\.\d{1,2})?$', errorText: 'Enter a valid price'),
                        ]).call,
                      ),
                      const SizedBox(height: 16),

                      // Stock fields in a row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _currentStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Current Stock *',
                                border: OutlineInputBorder(),
                              ),
                              validator: MultiValidator([
                                RequiredValidator(errorText: 'Stock is required'),
                                PatternValidator(r'^\d+$', errorText: 'Enter a valid number'),
                              ]).call,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min Stock Level',
                                border: OutlineInputBorder(),
                              ),
                              validator: PatternValidator(r'^\d*$', errorText: 'Enter a valid number').call,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.product == null ? 'Add Product' : 'Update Product'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        purchasePrice: double.parse(_purchasePriceController.text),
        currentStock: int.parse(_currentStockController.text),
        minStockLevel: int.tryParse(_minStockController.text) ?? 0,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(), sellingPrice: 0.0,
      );

      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      
      bool success;
      if (widget.product == null) {
        success = await inventoryProvider.addProduct(product);
      } else {
        success = await inventoryProvider.updateProduct(product);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null 
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}