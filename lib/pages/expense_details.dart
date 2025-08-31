import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/expense.dart';
import 'expense_form.dart';
import '../shared_widgets/confirmation_dialog.dart';
import '../shared_widgets/currency_text.dart';

class ExpenseDetailsPage extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;
  final void Function(Expense updatedExpense)? onUpdate;
  final VoidCallback? onEdit;

  const ExpenseDetailsPage({
    super.key,
    required this.expense,
    this.onDelete,
    this.onUpdate,
    this.onEdit,
  });

void _navigateToEdit(BuildContext context) async {
  final updatedExpense = await Navigator.push<Expense>(
    context,
    MaterialPageRoute(
      builder: (_) => ExpenseFormPage(existingExpense: expense),
    ),
  );

  if (updatedExpense != null) {
    onUpdate?.call(updatedExpense); // Notify parent about the change
    Navigator.pop(context); // Close the details page
  }
}

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Expense',
      content: 'Are you sure you want to delete this expense?',
      confirmText: 'Delete',
    );

    if (confirmed == true) {
      onDelete?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
            tooltip: 'Edit Expense',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Delete Expense',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            CurrencyText(
              amount: expense.amount,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.category, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  expense.category,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().format(expense.date),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (expense.notes.isNotEmpty) ...[
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                expense.notes,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            if (expense.attachmentPath != null && expense.attachmentPath!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Attachment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Image.file(
                File(expense.attachmentPath!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
