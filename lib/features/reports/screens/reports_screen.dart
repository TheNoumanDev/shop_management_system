import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../sales/providers/sales_provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../services/providers/photocopy_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesProvider>(context, listen: false).loadSales();
      Provider.of<InventoryProvider>(context, listen: false).loadProducts();
      Provider.of<PhotocopyProvider>(context, listen: false).loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Business Reports & Analytics',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Overview of your business performance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Overall Summary
          _buildOverallSummary(),
          const SizedBox(height: 24),

          // Sales Summary
          _buildSalesSummary(),
          const SizedBox(height: 24),

          // Inventory Summary
          _buildInventorySummary(),
          const SizedBox(height: 24),

          // Photocopy Service Summary
          _buildPhotocopyServiceSummary(),
        ],
      ),
    );
  }

  Widget _buildOverallSummary() {
    return Consumer3<SalesProvider, InventoryProvider, PhotocopyProvider>(
      builder: (context, salesProvider, inventoryProvider, photocopyProvider, child) {
        final totalBusinessIncome = salesProvider.totalSalesAmount + photocopyProvider.stats.totalIncome;
        final totalBusinessProfit = salesProvider.totalProfit + photocopyProvider.stats.netProfit;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Business Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Revenue',
                        '${AppConstants.currencySymbol}${totalBusinessIncome.toStringAsFixed(0)}',
                        Colors.green,
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Profit',
                        '${AppConstants.currencySymbol}${totalBusinessProfit.toStringAsFixed(0)}',
                        Colors.blue,
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Products',
                        '${inventoryProvider.products.length}',
                        Colors.orange,
                        Icons.inventory,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesSummary() {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.point_of_sale, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Sales Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Total Sales',
                        '${salesProvider.sales.length}',
                        Icons.receipt_long,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Revenue',
                        '${AppConstants.currencySymbol}${salesProvider.totalSalesAmount.toStringAsFixed(0)}',
                        Icons.attach_money,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Profit',
                        '${AppConstants.currencySymbol}${salesProvider.totalProfit.toStringAsFixed(0)}',
                        Icons.trending_up,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Today\'s Sales',
                        '${salesProvider.todaysSales.length}',
                        Icons.today,
                      ),
                    ),
                  ],
                ),
                if (salesProvider.sales.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Recent Sales',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...salesProvider.sales.take(3).map((sale) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              sale.productName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            'Qty: ${sale.quantity}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${AppConstants.currencySymbol}${sale.totalAmount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInventorySummary() {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final lowStockCount = inventoryProvider.lowStockProducts.length;
        final outOfStockCount = inventoryProvider.outOfStockProducts.length;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Inventory Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Total Products',
                        '${inventoryProvider.products.length}',
                        Icons.category,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Low Stock',
                        '$lowStockCount',
                        Icons.warning,
                        color: lowStockCount > 0 ? Colors.orange : null,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Out of Stock',
                        '$outOfStockCount',
                        Icons.error,
                        color: outOfStockCount > 0 ? Colors.red : null,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Categories',
                        '${AppConstants.mobileAccessoryCategories.length}',
                        Icons.list,
                      ),
                    ),
                  ],
                ),
                if (lowStockCount > 0 || outOfStockCount > 0) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (outOfStockCount > 0) ...[
                    Text(
                      'Out of Stock Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...inventoryProvider.outOfStockProducts.take(3).map((product) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(product.name)),
                            Text(
                              '${product.currentStock} left',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (lowStockCount > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Low Stock Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...inventoryProvider.lowStockProducts.take(3).map((product) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(product.name)),
                            Text(
                              '${product.currentStock} left',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotocopyServiceSummary() {
    return Consumer<PhotocopyProvider>(
      builder: (context, photocopyProvider, child) {
        final stats = photocopyProvider.stats;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.print, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Photocopy Service Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Total Income',
                        '${AppConstants.currencySymbol}${stats.totalIncome.toStringAsFixed(0)}',
                        Icons.trending_up,
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Total Expenses',
                        '${AppConstants.currencySymbol}${stats.totalExpenses.toStringAsFixed(0)}',
                        Icons.trending_down,
                        color: Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Net Profit',
                        '${AppConstants.currencySymbol}${stats.netProfit.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        color: stats.netProfit >= 0 ? Colors.blue : Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Total Copies',
                        '${stats.totalCopies}',
                        Icons.copy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
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

  Widget _buildMetricItem(String title, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey[600]),
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
    );
  }
}