import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../shared_widgets/custom_text_field.dart';
import '../shared_widgets/date_picker_field.dart';
import '../shared_widgets/category_dropdown.dart';
import '../shared_widgets/primary_button.dart';
import '../shared_widgets/snackbar_helper.dart';

class ExpenseFormPage extends StatefulWidget {
  final Expense? existingExpense;

  const ExpenseFormPage({super.key, this.existingExpense});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = CategoryDropdown.categories.first;

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toString();
      _selectedDate = e.date;
      _selectedCategory = e.category;
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) {
      SnackbarHelper.showError(context, 'Please enter valid title and amount');
      return;
    }

    final expense = Expense(
      title: title,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
    );

    Navigator.pop(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExpense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Title',
              icon: Icons.title,
            ),
            const SizedBox(height: 12),
            CategoryDropdown(
              selectedCategory: _selectedCategory,
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
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: isEditing ? 'Update Expense' : 'Add Expense',
              onPressed: () async {
                await _submit();
              },
            ),
          ],
        ),
      ),
    );
  }
}
