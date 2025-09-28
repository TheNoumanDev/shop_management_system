import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_styles.dart';
import '../../sales/providers/sales_provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../services/providers/photocopy_provider.dart';
import '../../services/providers/data_transfer_provider.dart';
import '../../expenses/providers/expense_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().copyWith(day: 1); // First day of current month
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    // Defer data loading until after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final photocopyProvider = Provider.of<PhotocopyProvider>(context, listen: false);
    final dataTransferProvider = Provider.of<DataTransferProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    await Future.wait([
      salesProvider.loadSalesForDateRange(_startDate, _endDate),
      inventoryProvider.loadProducts(),
      photocopyProvider.loadAllData(),
      dataTransferProvider.loadIncomes(),
      expenseProvider.loadExpenses(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != DateTimeRange(start: _startDate, end: _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header with date range selector
          _buildHeader(),

          // Overall Business Stats (above tabs)
          _buildOverallStats(),

          // Tab bar
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              isScrollable: false,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(
                  text: 'Sales',
                  icon: Icon(
                    Icons.shopping_cart,
                    size: 18,
                    color: _selectedTabIndex == 0
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                  ),
                ),
                Tab(
                  text: 'Services',
                  icon: Icon(
                    Icons.business,
                    size: 18,
                    color: _selectedTabIndex == 1
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                  ),
                ),
                Tab(
                  text: 'Expenses',
                  icon: Icon(
                    Icons.money_off,
                    size: 18,
                    color: _selectedTabIndex == 2
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(),
                _buildServicesTab(),
                _buildExpensesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardHeaderDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Reports',
                      style: AppStyles.sectionHeaderStyle(context),
                    ),
                    Text(
                      'Analytics and performance insights',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('Date Range'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    return Consumer5<SalesProvider, InventoryProvider, PhotocopyProvider, DataTransferProvider, ExpenseProvider>(
      builder: (context, salesProvider, inventoryProvider, photocopyProvider, dataTransferProvider, expenseProvider, child) {
        final totalSales = salesProvider.sales
            .where((sale) => sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                           sale.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, sale) => sum + sale.totalAmount);

        final photocopyIncome = photocopyProvider.incomes
            .where((income) => income.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                             income.date.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, income) => sum + income.totalAmount);

        final dataTransferIncome = dataTransferProvider.incomes
            .where((income) => income.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                             income.date.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, income) => sum + income.totalAmount);

        final totalExpenses = expenseProvider.expenses
            .where((expense) => expense.expenseDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                              expense.expenseDate.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, expense) => sum + expense.amount);

        final photocopyExpenses = photocopyProvider.expenses
            .where((expense) => expense.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                              expense.date.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, expense) => sum + expense.amount);

        final totalRevenue = totalSales + photocopyIncome + dataTransferIncome;
        final netProfit = totalRevenue - (totalExpenses + photocopyExpenses);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 2.8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildCompactStatCard('Total Sales', '₨${totalRevenue.toStringAsFixed(0)}', Colors.green, Icons.trending_up),
              _buildCompactStatCard('Net Profit', '₨${netProfit.toStringAsFixed(0)}', Colors.blue, Icons.monetization_on),
              _buildCompactStatCard('Expenses', '₨${(totalExpenses + photocopyExpenses).toStringAsFixed(0)}', Colors.red, Icons.money_off),
              _buildCompactStatCard('Products', '${inventoryProvider.products.length}', Colors.orange, Icons.inventory),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalesTab() {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        final filteredSales = salesProvider.sales
            .where((sale) => sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                           sale.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Sales Overview Cards
              _buildServiceOverviewCards(
                title: 'Product Sales',
                data: filteredSales,
                getAmount: (sale) => sale.totalAmount,
                getProfit: (sale) => sale.profit,
                getDate: (sale) => sale.saleDate,
                color: Colors.blue,
                icon: Icons.shopping_cart,
              ),
              const SizedBox(height: 16),

              // Daily Sales Chart
              _buildDailySalesChart(
                title: 'Daily Sales Trend',
                data: filteredSales,
                getAmount: (sale) => sale.totalAmount,
                getDate: (sale) => sale.saleDate,
                color: Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServicesTab() {
    return DefaultTabController(
      key: const ValueKey('services_tab_controller'),
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Photocopy'),
              Tab(text: 'Data Transfer'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPhotocopyServiceTab(),
                _buildDataTransferServiceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotocopyServiceTab() {
    return Consumer<PhotocopyProvider>(
      builder: (context, photocopyProvider, child) {
        final filteredIncomes = photocopyProvider.incomes
            .where((income) => income.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                             income.date.isBefore(_endDate.add(const Duration(days: 1))))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildServiceOverviewCards(
                title: 'Photocopy Service',
                data: filteredIncomes,
                getAmount: (income) => income.totalAmount,
                getProfit: (income) => income.totalAmount, // For services, amount = profit
                getDate: (income) => income.date,
                color: Colors.green,
                icon: Icons.print,
              ),
              const SizedBox(height: 16),
              _buildDailySalesChart(
                title: 'Daily Photocopy Income',
                data: filteredIncomes,
                getAmount: (income) => income.totalAmount,
                getDate: (income) => income.date,
                color: Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataTransferServiceTab() {
    return Consumer<DataTransferProvider>(
      builder: (context, dataTransferProvider, child) {
        final filteredIncomes = dataTransferProvider.incomes
            .where((income) => income.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                             income.date.isBefore(_endDate.add(const Duration(days: 1))))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildServiceOverviewCards(
                title: 'Data Transfer Service',
                data: filteredIncomes,
                getAmount: (income) => income.totalAmount,
                getProfit: (income) => income.totalAmount, // For services, amount = profit
                getDate: (income) => income.date,
                color: Colors.orange,
                icon: Icons.data_object,
              ),
              const SizedBox(height: 16),
              _buildDailySalesChart(
                title: 'Daily Data Transfer Income',
                data: filteredIncomes,
                getAmount: (income) => income.totalAmount,
                getDate: (income) => income.date,
                color: Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    return Consumer5<SalesProvider, PhotocopyProvider, DataTransferProvider, ExpenseProvider, InventoryProvider>(
      builder: (context, salesProvider, photocopyProvider, dataTransferProvider, expenseProvider, inventoryProvider, child) {
        // Calculate total income from all services
        final totalSales = salesProvider.sales
            .where((sale) => sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                           sale.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, sale) => sum + sale.totalAmount);

        final photocopyIncome = photocopyProvider.incomes
            .where((income) => income.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                             income.date.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, income) => sum + income.totalAmount);

        final dataTransferIncome = dataTransferProvider.incomes
            .where((income) => income.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                             income.date.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, income) => sum + income.totalAmount);

        // Calculate total expenses
        final shopExpenses = expenseProvider.expenses
            .where((expense) => expense.expenseDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                              expense.expenseDate.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, expense) => sum + expense.amount);

        final photocopyExpenses = photocopyProvider.expenses
            .where((expense) => expense.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                              expense.date.isBefore(_endDate.add(const Duration(days: 1))))
            .fold<double>(0, (sum, expense) => sum + expense.amount);

        // Calculate totals
        final totalIncome = totalSales + photocopyIncome + dataTransferIncome;
        final totalExpenses = shopExpenses + photocopyExpenses;
        final totalProfit = totalIncome - totalExpenses;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Total Business Analysis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Business Analysis',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalysisCard('Total Income', totalIncome, Colors.green, Icons.trending_up),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnalysisCard('Total Expenses', totalExpenses, Colors.red, Icons.trending_down),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnalysisCard(
                              totalProfit >= 0 ? 'Total Profit' : 'Total Loss',
                              totalProfit.abs(),
                              totalProfit >= 0 ? Colors.blue : Colors.red,
                              totalProfit >= 0 ? Icons.monetization_on : Icons.money_off,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Product Sales Analysis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Sales Analysis',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalysisCard('Sales Income', totalSales, Colors.green, Icons.trending_up),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnalysisCard('Shop Expenses', shopExpenses, Colors.red, Icons.trending_down),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnalysisCard(
                              (totalSales - shopExpenses) >= 0 ? 'Net Profit' : 'Net Loss',
                              (totalSales - shopExpenses).abs(),
                              (totalSales - shopExpenses) >= 0 ? Colors.blue : Colors.red,
                              (totalSales - shopExpenses) >= 0 ? Icons.monetization_on : Icons.money_off,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Services Analysis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services Analysis',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Photocopy Service
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Photocopy Service',
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildAnalysisCard('Income', photocopyIncome, Colors.green, Icons.trending_up),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildAnalysisCard('Expenses', photocopyExpenses, Colors.red, Icons.trending_down),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildAnalysisCard(
                                        (photocopyIncome - photocopyExpenses) >= 0 ? 'Profit' : 'Loss',
                                        (photocopyIncome - photocopyExpenses).abs(),
                                        (photocopyIncome - photocopyExpenses) >= 0 ? Colors.blue : Colors.red,
                                        (photocopyIncome - photocopyExpenses) >= 0 ? Icons.monetization_on : Icons.money_off,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Data Transfer Service
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data Transfer Service',
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildAnalysisCard('Income', dataTransferIncome, Colors.green, Icons.trending_up),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildAnalysisCard('Expenses', 0, Colors.grey, Icons.trending_down),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildAnalysisCard('Profit', dataTransferIncome, Colors.blue, Icons.monetization_on),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceOverviewCards<T>({
    required String title,
    required List<T> data,
    required double Function(T) getAmount,
    required double Function(T) getProfit,
    required DateTime Function(T) getDate,
    required Color color,
    required IconData icon,
  }) {
    final totalAmount = data.fold<double>(0, (sum, item) => sum + getAmount(item));
    final totalProfit = data.fold<double>(0, (sum, item) => sum + getProfit(item));
    final totalTransactions = data.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('Total Sales', '₨${totalAmount.toStringAsFixed(0)}', color, Icons.monetization_on),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard('Total Profit', '₨${totalProfit.toStringAsFixed(0)}', Colors.green, Icons.trending_up),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard('Transactions', '$totalTransactions', Colors.blue, Icons.receipt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySalesChart<T>({
    required String title,
    required List<T> data,
    required double Function(T) getAmount,
    required DateTime Function(T) getDate,
    required Color color,
  }) {
    // Group data by day
    final Map<DateTime, double> dailyData = {};

    for (final item in data) {
      final date = DateTime(getDate(item).year, getDate(item).month, getDate(item).day);
      dailyData[date] = (dailyData[date] ?? 0) + getAmount(item);
    }

    if (dailyData.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No data available for the selected period',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    final sortedDates = dailyData.keys.toList()..sort();

    // Special handling for single day or two days
    if (sortedDates.length == 1) {
      final singleDayAmount = dailyData[sortedDates[0]]!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, color: color, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        DateFormat('MMM dd, yyyy').format(sortedDates[0]),
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₨${singleDayAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Single day data',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.grey,
                        ),
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

    // Create chart spots with proper spacing
    final spots = <FlSpot>[];
    double maxValue = 0;

    // For 2 days, spread them across the chart width
    if (sortedDates.length == 2) {
      spots.add(FlSpot(0, dailyData[sortedDates[0]]!));
      spots.add(FlSpot(3, dailyData[sortedDates[1]]!)); // Spread to position 3
      maxValue = dailyData.values.fold(0, (max, value) => value > max ? value : max);
    } else {
      // For more than 2 days, use normal indexing
      for (int i = 0; i < sortedDates.length; i++) {
        final value = dailyData[sortedDates[i]]!;
        spots.add(FlSpot(i.toDouble(), value));
        if (value > maxValue) maxValue = value;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (maxValue < 1000) {
                            return Text(
                              '₨${value.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10),
                            );
                          } else {
                            return Text(
                              '₨${(value / 1000).toStringAsFixed(0)}k',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (sortedDates.length == 2) {
                            // For 2 days, show titles at positions 0 and 3
                            if (value == 0) {
                              return Text(
                                DateFormat('MMM dd').format(sortedDates[0]),
                                style: const TextStyle(fontSize: 10),
                              );
                            } else if (value == 3) {
                              return Text(
                                DateFormat('MMM dd').format(sortedDates[1]),
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                          } else {
                            // Normal case for more than 2 days
                            if (value.toInt() < sortedDates.length) {
                              return Text(
                                DateFormat('MMM dd').format(sortedDates[value.toInt()]),
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: sortedDates.length == 2 ? 3 : (sortedDates.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxValue * 1.1, // Add 10% padding to top
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: sortedDates.length > 2,
                      color: color,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.3),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
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


  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAnalysisCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            '₨${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}