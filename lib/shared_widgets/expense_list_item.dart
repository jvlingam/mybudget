// lib/shared_widgets/expense_list_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseListItem({
    Key? key,
    required this.expense,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${expense.title} (${expense.category})'),
      subtitle: Text('${expense.amount.toStringAsFixed(2)} • ${DateFormat.yMMMd().format(expense.date)}'),
      trailing: onDelete != null 
        ? IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: onDelete,
          )
        : null,
      onTap: onTap,
    );
  }
}
