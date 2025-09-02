import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  List<String> _customCategories = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _customCategories = CategoryService.getCustomCategories();
    });
  }

  Future<void> _deleteCategory(String category) async {
    final expenses = LocalStorageService.getExpenses();
    final isUsed = expenses.any((e) => e.category == category);

    if (isUsed) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text('This category is used in one or more expenses and cannot be deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await CategoryService.deleteCategory(category);
    _loadCategories();
  }

  Future<void> _addNewCategory() async {
    final newCategory = _controller.text.trim();
    if (newCategory.isEmpty) return;

    await CategoryService.addCategory(newCategory);
    _controller.clear();
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final defaultCategories = CategoryService.defaultCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Add New Category Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'New Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addNewCategory,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category List
            Expanded(
              child: ListView(
                children: [
                  const Text('Default Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...defaultCategories.map((cat) => ListTile(
                        title: Text(cat),
                        trailing: const Icon(Icons.lock, size: 18, color: Colors.grey),
                      )),
                  const SizedBox(height: 20),
                  const Text('Custom Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (_customCategories.isEmpty)
                    const Text('No custom categories added yet.'),
                  ..._customCategories.map((cat) => ListTile(
                        title: Text(cat),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(cat),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}