import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/local_storage_service.dart';
import 'expense_form.dart';
import 'export_page.dart';
import 'expense_details.dart';

class HomePage extends StatefulWidget {
  final ValueNotifier<String> currencyNotifier;
  const HomePage({
    super.key,
    required this.currencyNotifier
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> _expenses = [];
  double _totalAmount = 0.0;
  double _monthlyBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    
    final expenses = LocalStorageService.getExpenses();
    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((e) =>
      e.date.year == now.year && e.date.month == now.month);

    double monthlyIncome = currentMonthExpenses
      .where((e) => e.type == ExpenseType.income)
      .fold(0.0, (sum, e) => sum + e.amount);

    double monthlyExpense = currentMonthExpenses
      .where((e) => e.type == ExpenseType.expense)
      .fold(0.0, (sum, e) => sum + e.amount);

    
    setState(() {
      _expenses = expenses;
      _totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
      _monthlyBalance = monthlyIncome - monthlyExpense;
    });
  }

  Future<void> _addOrEditExpense({Expense? existingExpense}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormPage(existingExpense: existingExpense, currencyNotifier: widget.currencyNotifier),
      ),
    );

    if (result != null && result is Expense) {
      if (existingExpense != null) {
        existingExpense
          ..title = result.title
          ..amount = result.amount
          ..category = result.category
          ..date = result.date;
        await existingExpense.save();
      } else {
        await LocalStorageService.addExpense(result);
      }
      _loadExpenses();
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    await expense.delete();
    _loadExpenses();
  }

  void _openExportPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExportPage()),
    );
  }

  void _openDetailsPage(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailsPage(
          expense: expense,
          onDelete: () => _deleteExpense(expense),
          onUpdate: (updatedExpense) => _loadExpenses(),
          onEdit: () => _addOrEditExpense(existingExpense: expense), // Pass onEdit callback here
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.currencyNotifier.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('myBudget Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _openExportPage,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Current Balance: $currency ${_monthlyBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _monthlyBalance >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _expenses.isEmpty
                  ? const Center(child: Text('No expenses added yet.'))
                  : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (_, i) {
                        final e = _expenses[i];
                        return ListTile(
                          title: Text('${e.title} (${e.category})'),
                          subtitle: Text(
                              '$currency ${e.amount.toStringAsFixed(2)} • ${DateFormat.yMMMd().format(e.date)}'),
                          onTap: () => _openDetailsPage(e),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteExpense(e),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditExpense(),
        child: const Icon(Icons.add),
        tooltip: 'Add Expense',
      ),
    );
  }
}