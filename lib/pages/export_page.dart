import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';

import '../models/expense.dart';
import '../services/local_storage_service.dart';
import '../shared_widgets/primary_button.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/category_dropdown.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];

  String? _selectedCategory;
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _allExpenses = LocalStorageService.getExpenses();
    _filteredExpenses = _allExpenses;
  }

  void _applyFilters() {
    setState(() {
      _filteredExpenses = _allExpenses.where((e) {
        final matchMonth = _selectedMonth == null ||
            (e.date.month == _selectedMonth!.month &&
                e.date.year == _selectedMonth!.year);
        final matchCategory =
            _selectedCategory == null || e.category == _selectedCategory;
        return matchMonth && matchCategory;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedMonth = null;
      _filteredExpenses = _allExpenses;
    });
  }

  Future<void> _exportCSV() async {
    final rows = [
      ['Title', 'Amount', 'Date', 'Category'],
      ..._filteredExpenses.map((e) => [
            e.title,
            e.amount.toString(),
            DateFormat.yMd().format(e.date),
            e.category,
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expenses.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)],
        text: 'My exported expenses (CSV)');
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Expense Report', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Title', 'Amount', 'Date', 'Category'],
              data: _filteredExpenses.map((e) {
                return [
                  e.title,
                  e.amount.toString(),
                  DateFormat.yMd().format(e.date),
                  e.category
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expenses.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)],
        text: 'My exported expenses (PDF)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Filters',
            onPressed: _clearFilters,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month Filter
            ListTile(
              title: Text(
                _selectedMonth == null
                    ? 'Select Month'
                    : DateFormat.yMMM().format(_selectedMonth!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialEntryMode: DatePickerEntryMode.calendar,
                );
                if (picked != null) {
                  setState(() => _selectedMonth = picked);
                  _applyFilters();
                }
              },
            ),

            const SizedBox(height: 12),

            // Category Dropdown (shared widget)
            CategoryDropdown(
              selectedCategory: _selectedCategory ?? CategoryDropdown.categories.first,
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                  _applyFilters();
                });
              },
            ),

            const SizedBox(height: 24),

            // Export Buttons (shared PrimaryButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PrimaryButton(
                  text: 'Export CSV',
                  icon: Icons.file_copy,
                  onPressed: _filteredExpenses.isEmpty
                      ? null
                      : () async {
                          await _exportCSV();
                        },
                ),
                PrimaryButton(
                  text: 'Export PDF',
                  icon: Icons.picture_as_pdf,
                  onPressed: _filteredExpenses.isEmpty
                      ? null
                      : () async {
                          await _exportPDF();
                        },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Expense Count
            Text(
              'Filtered Expenses: ${_filteredExpenses.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Filtered List
            Expanded(
              child: _filteredExpenses.isEmpty
                  ? const EmptyStateWidget(message: 'No expenses found.')
                  : ListView.builder(
                      itemCount: _filteredExpenses.length,
                      itemBuilder: (_, i) {
                        final e = _filteredExpenses[i];
                        return ListTile(
                          title: Text('${e.title} (${e.category})'),
                          subtitle: Text(
                            '₹${e.amount.toStringAsFixed(2)} • ${DateFormat.yMMMd().format(e.date)}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}