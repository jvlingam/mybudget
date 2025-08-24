import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/local_storage_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';

  final List<String> _categories = ['Food', 'Transport', 'Bills', 'Shopping', 'Other'];

  double _totalAmount = 0.0;
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    final expenses = LocalStorageService.getExpenses();
    setState(() {
      _expenses = expenses;
      _totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
    });
  }

  void _addExpense() async {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) return;

    final expense = Expense(
      title: title,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
    );

    await LocalStorageService.addExpense(expense);

    _titleController.clear();
    _amountController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedCategory = _categories[0];
    });

    _loadExpenses(); // will recalculate total
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(cat),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCategory = val;
                });
              }
            },
            decoration: const InputDecoration(labelText: 'Category'),
          ),

          TextFormField(
            readOnly: true,
            controller: TextEditingController(text: DateFormat.yMd().format(_selectedDate)),
            decoration: const InputDecoration(labelText: 'Date'),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
                   
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addExpense,
            child: const Text('Add Expense'),
          ),
          
          Text(
            'Total: ₹${_totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (_, i) {
                final e = _expenses[i];
                return ListTile(
                  title: Text(e.title),
                  subtitle: Text('${e.amount.toStringAsFixed(2)} • ${DateFormat.yMMMd().format(e.date)}'),
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}
