import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/local_storage_service.dart';
import 'expense_form.dart';
import 'export_page.dart';
import 'expense_details.dart';
import 'analytics_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final ValueNotifier<String> currencyNotifier;
  const HomePage({
    super.key,
    required this.currencyNotifier,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> _expenses = [];
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
      _monthlyBalance = monthlyIncome - monthlyExpense;
    });
  }

  Future<void> _addOrEditExpense({Expense? existingExpense}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormPage(
              existingExpense: existingExpense,
              currencyNotifier: widget.currencyNotifier,
            ),
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
        builder: (_) =>
            ExpenseDetailsPage(
              expense: expense,
              onDelete: () => _deleteExpense(expense),
              onUpdate: (updatedExpense) => _loadExpenses(),
              onEdit: () => _addOrEditExpense(existingExpense: expense),
            ),
      ),
    );
  }

  void _openAnalyticsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnalyticsPage(currencyNotifier: widget.currencyNotifier)),
    );
  }

  void _openSettingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          themeNotifier: ValueNotifier(ThemeMode.system),
          currencyNotifier: widget.currencyNotifier,
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
        centerTitle: true,
        elevation: 1
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'myBudget Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                // Already on Home page; no navigation needed
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context);
                _openAnalyticsPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                _openExportPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _openSettingsPage();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'myBudget Tracker',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.account_balance_wallet),
                  children: [
                    const Text('A simple app to track your income and expenses.'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$currency ${_monthlyBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _monthlyBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _expenses.isEmpty
                  ? const Center(
                child: Text(
                  'No expenses added yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _expenses.length,
                itemBuilder: (_, i) {
                  final e = _expenses[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(
                        e.type == ExpenseType.income
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: e.type == ExpenseType.income ? Colors.green : Colors.red,
                      ),
                      title: Text('${e.title} (${e.category})'),
                      subtitle: Text(
                        '$currency ${e.amount.toStringAsFixed(2)} • ${DateFormat.yMMMd().format(e.date)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteExpense(e),
                        tooltip: 'Delete Expense',
                      ),
                      onTap: () => _openDetailsPage(e),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditExpense(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        tooltip: 'Add Expense',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}