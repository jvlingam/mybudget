  import 'package:flutter/material.dart';
  import 'package:fl_chart/fl_chart.dart';
  import 'package:intl/intl.dart';
  import '../models/expense.dart';
  import '../services/local_storage_service.dart';
  import '../shared_widgets/empty_state_widget.dart';

  class AnalyticsPage extends StatelessWidget {
    const AnalyticsPage({super.key});

    Map<String, double> _getCategoryTotals(List<Expense> expenses) {
      final Map<String, double> totals = {};
      for (var e in expenses) {
        totals[e.category] = (totals[e.category] ?? 0) + e.amount;
      }
      return totals;
    }

    Map<int, double> _getMonthlyTotals(List<Expense> expenses) {
      final Map<int, double> monthlyTotals = {};
      for (var e in expenses) {
        final month = e.date.month;
        monthlyTotals[month] = (monthlyTotals[month] ?? 0) + e.amount;
      }
      return monthlyTotals;
    }

    Widget _buildCategoryPieChart(Map<String, double> categoryTotals) {
      final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
      final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple
      ];

      if (total == 0.0) {
        return const EmptyStateWidget(message: 'No data available for category chart.');
      }

      int colorIndex = 0;
      return SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: categoryTotals.entries.map((entry) {
              final percentage = (entry.value / total) * 100;
              return PieChartSectionData(
                value: entry.value,
                title: '${percentage.toStringAsFixed(1)}%',
                color: colors[colorIndex++ % colors.length],
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
            sectionsSpace: 4,
            centerSpaceRadius: 40,
          ),
        ),
      );
    }

    Widget _buildMonthlyBarChart(Map<int, double> monthlyTotals) {
      if (monthlyTotals.isEmpty) {
        return const EmptyStateWidget(message: 'No data available for monthly chart.');
      }

      final maxY = monthlyTotals.values.fold(0.0, (a, b) => a > b ? a : b);
      return SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY + 50,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, interval: 100),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final month = value.toInt();
                    if (month >= 1 && month <= 12) {
                      return Text(DateFormat.MMM().format(DateTime(0, month)));
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: monthlyTotals.entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: Colors.blue,
                    width: 16,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      final expenses = LocalStorageService.getExpenses();
      final categoryTotals = _getCategoryTotals(expenses);
      final monthlyTotals = _getMonthlyTotals(expenses);

      if (expenses.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: const Text('Analytics')),
          body: const Center(
            child: EmptyStateWidget(message: 'No expenses found to display analytics.'),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text(
                'Spending by Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _buildCategoryPieChart(categoryTotals),
              const SizedBox(height: 24),
              const Text(
                'Monthly Spending Overview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _buildMonthlyBarChart(monthlyTotals),
            ],
          ),
        ),
      );
    }
  }