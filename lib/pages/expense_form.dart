import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/expense.dart';
import '../services/local_storage_service.dart';
import '../shared_widgets/custom_text_field.dart';
import '../shared_widgets/date_picker_field.dart';
import '../shared_widgets/category_dropdown.dart';
import '../shared_widgets/primary_button.dart';
import '../shared_widgets/snackbar_helper.dart';

class ExpenseFormPage extends StatefulWidget {
  final Expense? existingExpense;
  final ValueNotifier<String>? currencyNotifier;

  const ExpenseFormPage({
    super.key,
    this.existingExpense,
    this.currencyNotifier,
  });

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  File? _attachment;

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  String _selectedType = ExpenseType.expense.name;

  _getCurrencyIcon(String currency) {
    switch (currency) {
      case '\$':
        return Icons.attach_money;
      case '€':
        return Icons.euro;
      case '£':
        return Icons.currency_pound;
      case '¥':
        return Icons.currency_yen;
      case '₽':
        return Icons.currency_ruble;
      default:
        return Icons.currency_rupee;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toString();
      _selectedDate = e.date;
      _selectedCategory = e.category;
      _selectedType = e.type.name;
      _notesController.text = e.notes;
      if (e.attachmentPath != null && e.attachmentPath!.isNotEmpty) {
        _attachment = File(e.attachmentPath!);
      }
    } else {
      // Load from Hive category box
      final categories = CategoryService.getCategories();

      if (categories.isNotEmpty) {
        _selectedCategory = categories.first;
      } else {
        _selectedCategory = 'Other'; // fallback
      }
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) {
      SnackbarHelper.showError(context, 'Please enter valid title and amount');
      return;
    }

    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      e
        ..title = title
        ..amount = amount
        ..date = _selectedDate
        ..category = _selectedCategory ?? 'Other'
        ..type = _selectedType == ExpenseType.income.name
            ? ExpenseType.income
            : ExpenseType.expense
        ..notes = _notesController.text.trim()
        ..attachmentPath = _attachment?.path;

      await e.save();
      Navigator.pop(context, e);
    } else {
      final newExpense = Expense(
        title: title,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory ?? 'Other',
        type: _selectedType == ExpenseType.income.name
            ? ExpenseType.income
            : ExpenseType.expense,
        notes: _notesController.text.trim(),
        attachmentPath: _attachment?.path,
      );

      Navigator.pop(context, newExpense);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExpense != null;
    final currency = widget.currencyNotifier?.value ?? '₹';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        centerTitle: true,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Income / Expense Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _selectedType = ExpenseType.income.name);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedType == ExpenseType.income.name
                                ? Colors.green
                                : Colors.grey[200],
                            foregroundColor: _selectedType == ExpenseType.income.name
                                ? Colors.white
                                : Colors.black,
                          ),
                          child: const Text('Income'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _selectedType = ExpenseType.expense.name);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedType == ExpenseType.expense.name
                                ? Colors.red
                                : Colors.grey[200],
                            foregroundColor: _selectedType == ExpenseType.expense.name
                                ? Colors.white
                                : Colors.black,
                          ),
                          child: const Text('Expense'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Form Fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _titleController,
                        label: 'Title',
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 12),
                      CategoryDropdown(
                        selectedCategory: _selectedCategory ?? 'Other',
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DatePickerField(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) => setState(() => _selectedDate = date),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _amountController,
                        label: 'Amount',
                        icon: _getCurrencyIcon(currency),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _notesController,
                        label: 'Notes',
                        icon: Icons.note_alt_outlined,
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Attachment & Submit
              if (_attachment != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_attachment!, height: 150),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: Text(_attachment != null ? 'Change Attachment' : 'Add Attachment'),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            _attachment = File(pickedFile.path);
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: isEditing ? 'Update Expense' : 'Add Expense',
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}