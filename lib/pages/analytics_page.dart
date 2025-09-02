import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/local_storage_service.dart';
import '../shared_widgets/empty_state_widget.dart';

import 'compare_months_page.dart';

class AnalyticsPage extends StatefulWidget {
  final ValueNotifier<String> currencyNotifier;

  const AnalyticsPage({
    super.key,
    required this.currencyNotifier,
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDateFilter = 'Overall';
  DateTimeRange? _customDateRange;

  final List<String> _dateFilters = [
    'Overall',
    'This Year',
    'This Month',
    'This Week',
    'Today',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
      });
    }
  }

  List<Expense> _filterExpenses(List<Expense> expenses, ExpenseType type) {
    final now = DateTime.now();

    return expenses.where((e) {
      if (e.type != type) return false;

      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);

      switch (_selectedDateFilter) {
        case 'Today':
          return expenseDate == DateTime(now.year, now.month, now.day);

        case 'This Week':
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));

          return expenseDate.isAtSameMomentAs(startOfWeek) ||
              expenseDate.isAtSameMomentAs(endOfWeek) ||
              (expenseDate.isAfter(startOfWeek) &&
                  expenseDate.isBefore(endOfWeek));

        case 'This Month':
          return expenseDate.year == now.year &&
              expenseDate.month == now.month;

        case 'This Year':
          return expenseDate.year == now.year;

        case 'Custom Range':
          if (_customDateRange == null) return true;
          final start = DateTime(
              _customDateRange!.start.year,
              _customDateRange!.start.month,
              _customDateRange!.start.day);
          final end = DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day);

          return expenseDate.isAtSameMomentAs(start) ||
              expenseDate.isAtSameMomentAs(end) ||
              (expenseDate.isAfter(start) && expenseDate.isBefore(end));

        case 'Overall':
        default:
          return true;
      }
    }).toList();
  }

  Map<String, double> _getCategoryTotals(List<Expense> expenses) {
    final Map<String, double> totals = {};
    for (var e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Widget _buildFilterSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedDateFilter,
            onChanged: (val) async {
              if (val == null) return;
              if (val == 'Custom Range') {
                await _pickCustomDateRange();
                if (_customDateRange == null) return;
              } else {
                _customDateRange = null;
              }
              setState(() => _selectedDateFilter = val);
            },
            items: _dateFilters
                .map((filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    ))
                .toList(),
          ),
          if (_selectedDateFilter == 'Custom Range' && _customDateRange != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                '${DateFormat.yMMMd().format(_customDateRange!.start)} - ${DateFormat.yMMMd().format(_customDateRange!.end)}',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryTotals) {
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
    ];

    if (total == 0.0) {
      return const EmptyStateWidget(message: 'No data for selected filter.');
    }

    int colorIndex = 0;
    return PieChart(
      PieChartData(
        sections: categoryTotals.entries.map((entry) {
          final percentage = (entry.value / total) * 100;
          return PieChartSectionData(
            value: entry.value,
            title: '${percentage.toStringAsFixed(1)}%',
            color: colors[colorIndex++ % colors.length],
            radius: 70,
            titleStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
        sectionsSpace: 4,
        centerSpaceRadius: 50,
      ),
    );
  }

  Widget _buildLegend(Map<String, double> categoryTotals) {
    final currency = widget.currencyNotifier.value;
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
    ];

    int colorIndex = 0;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: categoryTotals.entries.map((entry) {
        final color = colors[colorIndex++ % colors.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('${entry.key} ($currency ${entry.value.toStringAsFixed(2)})'),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAnalyticsTab(
      Map<String, double> data, String label, double totalAmount) {
    final currency = widget.currencyNotifier.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: $currency ${totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SizedBox(height: 250, child: _buildPieChart(data)),
                  const SizedBox(height: 16),
                  _buildLegend(data),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allExpenses = LocalStorageService.getExpenses();

    final expenses = _filterExpenses(allExpenses, ExpenseType.expense);
    final incomes = _filterExpenses(allExpenses, ExpenseType.income);

    final expenseTotals = _getCategoryTotals(expenses);
    final incomeTotals = _getCategoryTotals(incomes);

    final expenseTotalAmount =
        expenseTotals.values.fold(0.0, (a, b) => a + b);
    final incomeTotalAmount =
        incomeTotals.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Compare Months',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompareMonthsPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterSelector(),
            const Divider(height: 0),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAnalyticsTab(
                    expenseTotals,
                    'Spending by Category',
                    expenseTotalAmount,
                  ),
                  _buildAnalyticsTab(
                    incomeTotals,
                    'Income by Category',
                    incomeTotalAmount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}