import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class CategoryDropdown extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categories = CategoryService.getCategories();
    });
  }

  void _addNewCategory() async {
    final controller = TextEditingController();
    final newCategory = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      await CategoryService.addCategory(newCategory);
      _loadCategories(); // refresh
      widget.onChanged(newCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _categories.contains(widget.selectedCategory)
          ? widget.selectedCategory
          : null,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: [
        ..._categories.map((cat) => DropdownMenuItem(
              value: cat,
              child: Text(cat),
            )),
        const DropdownMenuItem(
          value: '__add_new__',
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('Add New Category'),
            ],
          ),
        )
      ],
      onChanged: (val) {
        if (val == '__add_new__') {
          _addNewCategory();
        } else {
          widget.onChanged(val);
        }
      },
    );
  }
}