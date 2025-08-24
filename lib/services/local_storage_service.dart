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
