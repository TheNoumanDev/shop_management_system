import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/sales_provider.dart';
import '../models/sale_model.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../inventory/models/product_model.dart';

class AddSaleDialog extends StatefulWidget {
  const AddSaleDialog({super.key});

  @override
  State<AddSaleDialog> createState() => _AddSaleDialogState();
}

class _AddSaleDialogState extends State<AddSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  Product? _selectedProduct;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _sellingPriceController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
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
                    'Record New Sale',
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
                      // Product Selection
                      Consumer<InventoryProvider>(
                        builder: (context, inventoryProvider, child) {
                          if (inventoryProvider.products.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                border: Border.all(color: Colors.orange.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No products available. Please add products to inventory first.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            );
                          }

                          return DropdownButtonFormField<Product>(
                            value: _selectedProduct,
                            decoration: const InputDecoration(
                              labelText: 'Select Product *',
                              border: OutlineInputBorder(),
                            ),
                            items: inventoryProvider.products.map((product) {
                              return DropdownMenuItem(
                                value: product,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name),
                                    Text(
                                      'Stock: ${product.currentStock} • Purchase: ${AppConstants.currencySymbol}${product.purchasePrice.toStringAsFixed(0)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (product) {
                              setState(() {
                                _selectedProduct = product;
                                // Suggest selling price (purchase price + 30% margin)
                                if (product != null) {
                                  final suggestedPrice = product.purchasePrice * 1.3;
                                  _sellingPriceController.text = suggestedPrice.toStringAsFixed(0);
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Please select a product' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quantity and Selling Price in a row
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Quantity is required';
                                }
                                final qty = int.tryParse(value);
                                if (qty == null || qty <= 0) {
                                  return 'Enter valid quantity';
                                }
                                if (_selectedProduct != null && qty > _selectedProduct!.currentStock) {
                                  return 'Not enough stock (${_selectedProduct!.currentStock})';
                                }
                                return null;
                              },
                              onChanged: (_) => _calculateTotals(),
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
                              ),
                              validator: MultiValidator([
                                RequiredValidator(errorText: 'Selling price is required'),
                                PatternValidator(r'^\d+(\.\d{1,2})?$', errorText: 'Enter a valid price'),
                              ]),
                              onChanged: (_) => _calculateTotals(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Customer Name (Optional)
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes (Optional)
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Calculation Summary
                      if (_selectedProduct != null && 
                          _quantityController.text.isNotEmpty && 
                          _sellingPriceController.text.isNotEmpty)
                        _buildCalculationSummary(),
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
                        : const Text('Record Sale'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationSummary() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
    final totalAmount = quantity * sellingPrice;
    final totalCost = quantity * _selectedProduct!.purchasePrice;
    final profit = totalAmount - totalCost;
    final margin = totalAmount > 0 ? (profit / totalAmount) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sale Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount:'),
              Text(
                '${AppConstants.currencySymbol}${totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Cost:'),
              Text('${AppConstants.currencySymbol}${totalCost.toStringAsFixed(0)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profit:'),
              Text(
                '${AppConstants.currencySymbol}${profit.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: profit >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Margin:'),
              Text(
                '${margin.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: profit >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _calculateTotals() {
    setState(() {
      // Trigger rebuild to update calculation summary
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final quantity = int.parse(_quantityController.text);
      final sellingPrice = double.parse(_sellingPriceController.text);
      final totalAmount = quantity * sellingPrice;
      final totalCost = quantity * _selectedProduct!.purchasePrice;
      final profit = totalAmount - totalCost;

      final sale = Sale(
        id: '',
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        quantity: quantity,
        purchasePrice: _selectedProduct!.purchasePrice,
        sellingPrice: sellingPrice,
        totalAmount: totalAmount,
        profit: profit,
        customerName: _customerNameController.text.trim().isEmpty 
            ? null 
            : _customerNameController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        saleDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      
      // Add sale
      final success = await salesProvider.addSale(sale);
      
      if (success) {
        // Update inventory stock
        final newStock = _selectedProduct!.currentStock - quantity;
        await inventoryProvider.updateStock(_selectedProduct!.id, newStock);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sale recorded successfully')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(salesProvider.errorMessage ?? 'An error occurred'),
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