import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/local_storage_service.dart';
import '../shared_widgets/confirmation_dialog.dart';
import '../shared_widgets/primary_button.dart';
import '../shared_widgets/snackbar_helper.dart';

class SettingsPage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<String> currencyNotifier;

  const SettingsPage({
    super.key,
    required this.themeNotifier,
    required this.currencyNotifier,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  String _selectedCurrency = '₹';

  final List<String> _currencies = ['₹', '\$', '€', '£', '¥', '₩', '₽'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _selectedCurrency = prefs.getString('currency') ?? '₹';
    });
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    widget.themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    setState(() => _isDarkMode = isDark);
  }

  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    widget.currencyNotifier.value = currency;
    setState(() => _selectedCurrency = currency);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Clear All Data',
      content:
          'Are you sure you want to clear all expenses? This action cannot be undone.',
      confirmText: 'Clear',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      await LocalStorageService.clearAllExpenses();
      SnackbarHelper.showSuccess(context, 'All expenses cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Mode', style: TextStyle(fontSize: 18)),
                Switch(
                  value: _isDarkMode,
                  onChanged: _saveTheme,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Currency selector
            const Text('Select Currency', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _currencies.map((currency) {
                final isSelected = currency == _selectedCurrency;
                return ChoiceChip(
                  label: Text(currency, style: const TextStyle(fontSize: 20)),
                  selected: isSelected,
                  onSelected: (_) => _saveCurrency(currency),
                );
              }).toList(),
            ),

            const Spacer(),

            // Clear data button (using shared widget)
            Center(
              child: PrimaryButton(
                icon: Icons.delete_forever,
                text: 'Clear All Expenses',
                color: Colors.red,
                onPressed: _clearAllData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}