import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String?> onChanged;
  final List<String> categories;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    required this.categories,
  });

  static const List<String> defaultCategories = [
    'Food',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Phone',
    'Education',
    'Health',
    'Beauty',
    'Sports',
    'Groceries',
    'Clothing',
    'Vehicles',
    'Electronics',
    'Pets',
    'Gift',
    'snacks',
    'kids',
    'Vegetables',
    'Fruits',
    'Travel',
    'Bills',
    'Internet',
    'Savings',
    'Repairs',
    'Housing',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: categories.contains(selectedCategory) ? selectedCategory : categories.first,
      decoration: const InputDecoration(
        labelText: 'Category',           // <-- this makes the label appear on top border
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: categories.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text(cat),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}