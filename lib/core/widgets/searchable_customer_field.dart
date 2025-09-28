import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/customers/providers/customer_provider.dart';
import '../../features/customers/models/customer_model.dart';

class SearchableCustomerField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final bool isRequired;
  final Function(Customer?)? onCustomerSelected;
  final String? Function(String?)? validator;

  const SearchableCustomerField({
    super.key,
    required this.controller,
    this.labelText = 'Customer Name',
    this.hintText = 'Search or enter customer name',
    this.isRequired = false,
    this.onCustomerSelected,
    this.validator,
  });

  @override
  State<SearchableCustomerField> createState() => _SearchableCustomerFieldState();
}

class _SearchableCustomerFieldState extends State<SearchableCustomerField> {
  List<Customer> _filteredCustomers = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    // Clean up overlay immediately and silently
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;

    final text = widget.controller.text.toLowerCase();
    final hasText = text.isNotEmpty;

    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    if (text.isEmpty) {
      _removeOverlay();
      widget.onCustomerSelected?.call(null);
      return;
    }

    final customers = Provider.of<CustomerProvider>(context, listen: false).customers;
    _filteredCustomers = customers
        .where((customer) => customer.name.toLowerCase().contains(text))
        .toList();

    if (_filteredCustomers.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
      widget.onCustomerSelected?.call(null);
    }
  }

  void _showOverlay() {
    if (!mounted) return;

    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getTextFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 55),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = _filteredCustomers[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      customer.name,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    subtitle: customer.phoneNumber != null
                        ? Text(
                            customer.phoneNumber!,
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          )
                        : null,
                    trailing: customer.hasDebt
                        ? Icon(Icons.warning, color: Colors.orange, size: 16)
                        : null,
                    onTap: () => _selectCustomer(customer),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectCustomer(Customer customer) {
    widget.controller.text = customer.name;
    widget.onCustomerSelected?.call(customer);
    _removeOverlay();
  }

  double _getTextFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onCustomerSelected?.call(null);
                    _removeOverlay();
                    if (mounted) {
                      setState(() {
                        _hasText = false;
                      });
                    }
                  },
                )
              : const Icon(
                  Icons.search,
                  color: Colors.grey,
                ),
        ),
        validator: widget.validator ?? (widget.isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Customer name is required';
                }
                return null;
              }
            : null),
        onTap: () {
          if (widget.controller.text.isNotEmpty && _filteredCustomers.isNotEmpty) {
            _showOverlay();
          }
        },
      ),
    );
  }
}

// Helper widget for Udhar checkbox with customer field
class UdharCustomerSection extends StatefulWidget {
  final TextEditingController customerController;
  final bool isUdharSelected;
  final ValueChanged<bool> onUdharChanged;
  final Function(Customer?)? onCustomerSelected;

  const UdharCustomerSection({
    super.key,
    required this.customerController,
    required this.isUdharSelected,
    required this.onUdharChanged,
    this.onCustomerSelected,
  });

  @override
  State<UdharCustomerSection> createState() => _UdharCustomerSectionState();
}

class _UdharCustomerSectionState extends State<UdharCustomerSection> {
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Customer field
        SearchableCustomerField(
          controller: widget.customerController,
          labelText: widget.isUdharSelected ? 'Customer Name *' : 'Customer Name (Optional)',
          hintText: 'Search or enter customer name',
          isRequired: widget.isUdharSelected,
          onCustomerSelected: (customer) {
            _selectedCustomer = customer;
            widget.onCustomerSelected?.call(customer);
          },
          validator: widget.isUdharSelected
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Customer name is required for Udhar';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 12),

        // Udhar checkbox
        Row(
          children: [
            Checkbox(
              value: widget.isUdharSelected,
              onChanged: (value) => widget.onUdharChanged(value ?? false),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onUdharChanged(!widget.isUdharSelected),
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

        // Show customer debt info if customer selected
        if (_selectedCustomer != null && _selectedCustomer!.hasDebt)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Customer owes: ₨${_selectedCustomer!.creditBalance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}