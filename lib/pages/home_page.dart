import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/local_storage_service.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';

  final List<String> _categories = ['Food', 'Transport', 'Bills', 'Shopping', 'Other'];

  double _totalAmount = 0.0;
  List<Expense> _expenses = [];

  String _selectedExportOption = 'Current View'; // default
  String? _selectedCategoryForExport;

  final List<String> _exportOptions = [
    'Current View',
    'All Expenses',
    'Filter by Category',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    final allExpenses = LocalStorageService.getExpenses();

    final filtered = allExpenses.where((e) =>
      e.date.month == _selectedMonth && e.date.year == _selectedYear).toList();

    setState(() {
      _expenses = filtered;
      _totalAmount = filtered.fold(0.0, (sum, e) => sum + e.amount);
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

  void _showEditDialog(Expense expense) {
    final titleController = TextEditingController(text: expense.title);
    final amountController = TextEditingController(text: expense.amount.toString());
    DateTime selectedDate = expense.date;
    String selectedCategory = expense.category;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Expense'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat.yMd().format(selectedDate)),
                      decoration: const InputDecoration(labelText: 'Date'),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = titleController.text;
                final newAmount = double.tryParse(amountController.text) ?? 0.0;

                if (newTitle.isEmpty || newAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid title and amount')),
                  );
                  return;
                }

                // Update the existing expense object
                expense.title = newTitle;
                expense.amount = newAmount;
                expense.date = selectedDate;
                expense.category = selectedCategory;

                await expense.save(); // Save changes to Hive
                Navigator.pop(context);
                _loadExpenses();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToCSV() async {
    final expensesToExport = _getFilteredExportExpenses();

    if (expensesToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses to export.')),
      );
      return;
    }

    List<List<dynamic>> rows = [
      ['Title', 'Amount', 'Date', 'Category']
    ];

    for (var expense in expensesToExport) {
      rows.add([
        expense.title,
        expense.amount.toStringAsFixed(2),
        DateFormat.yMd().format(expense.date),
        expense.category
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expenses_export.csv');
    await file.writeAsString(csv);

    Share.shareXFiles([XFile(file.path)], text: 'My exported expenses');
  }

  Future<void> _exportToPDF() async {
    final expensesToExport = _getFilteredExportExpenses();

    if (expensesToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses to export.')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Exported Expenses',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Title', 'Amount', 'Date', 'Category'],
                data: expensesToExport.map((e) => [
                  e.title,
                  '₹${e.amount.toStringAsFixed(2)}',
                  DateFormat.yMd().format(e.date),
                  e.category
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  List<Expense> _getFilteredExportExpenses() {
    final all = LocalStorageService.getExpenses();

    if (_selectedExportOption == 'All Expenses') return all;

    if (_selectedExportOption == 'Filter by Category') {
      return all.where((e) => e.category == _selectedCategoryForExport).toList();
    }

    // Default: Current view (filtered by month/year)
    return all.where((e) =>
      e.date.month == _selectedMonth &&
      e.date.year == _selectedYear
    ).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('myBudget Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
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
          
          Row(
            children: [
              DropdownButton<int>(
                value: _selectedMonth,
                items: List.generate(12, (i) {
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(DateFormat.MMMM().format(DateTime(0, i + 1))),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMonth = val;
                      _loadExpenses();
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _selectedYear,
                items: List.generate(10, (i) {
                  int year = DateTime.now().year - i;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedYear = val;
                      _loadExpenses();
                    });
                  }
                },
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _selectedExportOption,
            decoration: const InputDecoration(labelText: 'Export Option'),
            items: _exportOptions.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedExportOption = val;
                  _selectedCategoryForExport = null; // reset category if needed
                });
              }
            },
          ),

          if (_selectedExportOption == 'Filter by Category')
            DropdownButtonFormField<String>(
              value: _selectedCategoryForExport,
              decoration: const InputDecoration(labelText: 'Select Category'),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategoryForExport = val;
                  });
                }
              },
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.file_download),
                label: const Text('Export CSV'),
                onPressed: _expenses.isNotEmpty ? _exportToCSV : null,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
                onPressed: _expenses.isNotEmpty ? _exportToPDF : null,
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                  title: Text('${e.title} (${e.category})'),
                  subtitle: Text('${e.amount.toStringAsFixed(2)} • ${DateFormat.yMMMd().format(e.date)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(e),
                  ),
                  onLongPress: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Expense'),
                        content: const Text('Are you sure you want to delete this expense?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      await e.delete();
                      _loadExpenses(); // Refresh list and total
                    }
                  },
                );

              },
            ),
          )
        ]),
      ),
    );
  }
}
