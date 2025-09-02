import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../models/expense.dart';
import '../services/local_storage_service.dart';

class CompareMonthsPage extends StatefulWidget {
  const CompareMonthsPage({super.key});

  @override
  State<CompareMonthsPage> createState() => _CompareMonthsPageState();
}

class _CompareMonthsPageState extends State<CompareMonthsPage> {
  List<DateTime> _selectedMonths = [];
  List<Expense> _allExpenses = [];
  List<String> _categories = [];

  // Map<Category, Map<YYYY-MM, totalAmount>>
  Map<String, Map<String, double>> _comparisonData = {};

  @override
  void initState() {
    super.initState();
    _allExpenses = LocalStorageService.getExpenses();
    _categories = _allExpenses
        .map((e) => e.category)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      // Check duplicate by year & month
      final exists = _selectedMonths.any(
          (m) => m.year == picked.year && m.month == picked.month);

      if (!exists) {
        setState(() {
          _selectedMonths.add(picked);
          _selectedMonths.sort((a, b) => a.compareTo(b));
          _buildComparisonData();
        });
      }
    }
  }

  void _removeMonth(DateTime month) {
    setState(() {
      _selectedMonths.removeWhere(
          (m) => m.year == month.year && m.month == month.month);
      _buildComparisonData();
    });
  }

  void _buildComparisonData() {
    // Clear previous data
    _comparisonData.clear();

    // For each category, initialize empty map
    for (final category in _categories) {
      _comparisonData[category] = {};
      for (final month in _selectedMonths) {
        final key = DateFormat('yyyy-MM').format(month);
        _comparisonData[category]![key] = 0;
      }
    }

    // Sum expenses by category and month
    for (final expense in _allExpenses) {
      final expenseMonth = DateFormat('yyyy-MM').format(expense.date);
      final isMonthSelected = _selectedMonths.any((m) =>
          DateFormat('yyyy-MM').format(m) == expenseMonth);

      if (isMonthSelected) {
        final category = expense.category;
        final amount = expense.amount;
        final catMap = _comparisonData[category];
        if (catMap != null) {
          catMap[expenseMonth] = (catMap[expenseMonth] ?? 0) + amount;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthFormatter = DateFormat.yMMM();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Months'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Button to add month
            ElevatedButton.icon(
              onPressed: _pickMonth,
              icon: const Icon(Icons.add),
              label: const Text('Add Month to Compare'),
            ),

            const SizedBox(height: 12),

            // Show selected months as chips with remove button
            Wrap(
              spacing: 8,
              children: _selectedMonths.map((month) {
                return Chip(
                  label: Text(monthFormatter.format(month)),
                  onDeleted: () => _removeMonth(month),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: _selectedMonths.isEmpty
                  ? const Center(
                      child: Text('Please add months to compare.'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('Category')),
                          ..._selectedMonths.map(
                            (m) => DataColumn(
                              label: Text(monthFormatter.format(m)),
                            ),
                          ),
                        ],
                        rows: _categories.map(
                          (category) {
                            return DataRow(
                              cells: [
                                DataCell(Text(category)),
                                ..._selectedMonths.map(
                                  (month) {
                                    final key =
                                        DateFormat('yyyy-MM').format(month);
                                    final amount =
                                        _comparisonData[category]?[key] ?? 0;
                                    return DataCell(
                                      Text('₹${amount.toStringAsFixed(2)}'),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
