import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
enum ExpenseType {
  @HiveField(0)
  income,

  @HiveField(1)
  expense,
}

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String category;

  @HiveField(4)
  ExpenseType type;

  @HiveField(5)
  String notes = ''; // Optional notes

  @HiveField(6)
  String? attachmentPath; // Optional attachment path

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.notes = '',
    this.attachmentPath,
  });
}
