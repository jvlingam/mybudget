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
  DateTime? _month1;
  DateTime? _month2;

  double _incomeMonth1 = 0.0;
  double _expenseMonth1 = 0.0;
  double _incomeMonth2 = 0.0;
  double _expenseMonth2 = 0.0;

  bool _showTable = false;

  void _pickMonth(int slot) async {
    
    final picked = await showMonthPicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: (slot == 1 ? _month1 : _month2) ?? DateTime.now(),
    ).then((picked) {
      if (picked != null) {
        setState(() {
          if (slot == 1) {
            _month1 = picked;
          } else {
            _month2 = picked;
          }
        });
      }
    });
  }

  void _compare() {
    if (_month1 == null || _month2 == null) return;

    final allExpenses = LocalStorageService.getExpenses();

    List<Expense> getMonthData(DateTime month) {
      return allExpenses.where((e) =>
          e.date.year == month.year && e.date.month == month.month).toList();
    }

    final m1Expenses = getMonthData(_month1!);
    final m2Expenses = getMonthData(_month2!);

    _incomeMonth1 = m1Expenses
        .where((e) => e.type == ExpenseType.income)
        .fold(0.0, (sum, e) => sum + e.amount);
    _expenseMonth1 = m1Expenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);

    _incomeMonth2 = m2Expenses
        .where((e) => e.type == ExpenseType.income)
        .fold(0.0, (sum, e) => sum + e.amount);
    _expenseMonth2 = m2Expenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);

    setState(() {
      _showTable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = '₹'; // Replace with dynamic currency if needed

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Months'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(_month1 == null
                        ? 'Select Month 1'
                        : DateFormat.yMMM().format(_month1!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickMonth(1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: Text(_month2 == null
                        ? 'Select Month 2'
                        : DateFormat.yMMM().format(_month2!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickMonth(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.compare),
              label: const Text('Compare'),
              onPressed:
                  _month1 != null && _month2 != null ? _compare : null,
            ),
            const SizedBox(height: 32),
            if (_showTable)
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Category',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(DateFormat.yMMM().format(_month1!),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(DateFormat.yMMM().format(_month2!),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  TableRow(children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Income'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('$currency ${_incomeMonth1.toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('$currency ${_incomeMonth2.toStringAsFixed(2)}'),
                    ),
                  ]),
                  TableRow(children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Expenses'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('$currency ${_expenseMonth1.toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('$currency ${_expenseMonth2.toStringAsFixed(2)}'),
                    ),
                  ]),
                  TableRow(children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Balance'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '$currency ${(_incomeMonth1 - _expenseMonth1).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: (_incomeMonth1 - _expenseMonth1) >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '$currency ${(_incomeMonth2 - _expenseMonth2).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: (_incomeMonth2 - _expenseMonth2) >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
          ],
        ),
      ),
    );
  }
}