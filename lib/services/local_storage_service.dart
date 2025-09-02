import 'package:hive/hive.dart';
import '../models/expense.dart';

class LocalStorageService {
  static const String boxName = 'expensesBox';

  static Future<void> addExpense(Expense expense) async {
    final box = Hive.box<Expense>(boxName);
    await box.add(expense);
  }

  static List<Expense> getExpenses() {
    final box = Hive.box<Expense>(boxName);
    return box.values.toList();
  }

  static Future<void> clearAllExpenses() async {
    final box = Hive.box<Expense>(boxName);
    await box.clear();
  }

}


class CategoryService {
  static const _boxName = 'categoriesBox';
  static const _key = 'categories';

  static const List<String> defaultCategories = [
    'Clothing', 'Electronics', 'Entertainment', 'Education',
    'Food', 'Fruits', 'Gift', 'Health', 'Insurance', 'Internet',
    'Investments', 'Kids', 'Phone', 'Pets', 'Repairs', 'Salary', 'Savings',
    'Snacks', 'Sports', 'Shopping', 'Transportation', 'Travel', 'Vehicles',
    'Vegetables', 'Other',
  ];

  static late Box _box;

  static Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);

    // Ensure the key exists, even if empty list
    if (!_box.containsKey(_key)) {
      await _box.put(_key, <String>[]);
    }
  }

  static List<String> getCategories() {
    final custom = _box.get(_key, defaultValue: <String>[])!.cast<String>();
    return [...defaultCategories, ...custom];
  }

  static List<String> getCustomCategories() {
    return _box.get(_key, defaultValue: <String>[])!.cast<String>();
  }

  static Future<void> addCategory(String category) async {
    final List<String> current = _box.get(_key, defaultValue: <String>[])!.cast<String>();
    if (!current.contains(category) && !defaultCategories.contains(category)) {
      current.add(category);
      await _box.put(_key, current);
    }
  }

  static Future<void> deleteCategory(String category) async {
    final List<String> current = _box.get(_key, defaultValue: <String>[])!.cast<String>();
    current.remove(category);
    await _box.put(_key, current);
  }
}