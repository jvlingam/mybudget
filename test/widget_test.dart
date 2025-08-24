import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart'; // Use the public API

import 'package:mybudget/main.dart'; // Replace with your actual package name
import 'package:mybudget/models/expense.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive with test directory
    await Hive.initFlutter(); // initializes with default path
    Hive.registerAdapter(ExpenseAdapter());
    await Hive.openBox<Expense>('expensesBox');
  });

  tearDownAll(() async {
    await Hive.box<Expense>('expensesBox').clear();
    await Hive.close();
  });

  testWidgets('Add expense and verify it appears in list', (WidgetTester tester) async {
    // Launch the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Enter title
    final titleField = find.byType(TextField).at(0);
    await tester.enterText(titleField, 'Test Expense');

    // Enter amount
    final amountField = find.byType(TextField).at(1);
    await tester.enterText(amountField, '42.5');

    // Tap Add Expense button
    final addButton = find.widgetWithText(ElevatedButton, 'Add Expense');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify the expense is shown
    expect(find.text('Test Expense'), findsOneWidget);
    expect(find.textContaining('42.50'), findsOneWidget);
  });
}
