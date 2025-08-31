import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/local_storage_service.dart';
import '../shared_widgets/confirmation_dialog.dart';
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

  final List<Map<String, String>> _currencyOptions = [
    {'symbol': '₹', 'name': 'Indian Rupee'},
    {'symbol': '\$', 'name': 'US Dollar'},
    {'symbol': '€', 'name': 'Euro'},
    {'symbol': '£', 'name': 'British Pound'},
    {'symbol': '¥', 'name': 'Japanese Yen'},
    {'symbol': '₽', 'name': 'Russian Ruble'},
  ];

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
      content: 'Are you sure you want to delete all expenses? This action is irreversible.',
      confirmText: 'Clear',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      await LocalStorageService.clearAllExpenses();
      SnackbarHelper.showSuccess(context, 'All expenses cleared');
    }
  }

  IconData _getCurrencyIcon(String symbol) {
    switch (symbol) {
      case '₹':
        return Icons.currency_rupee;
      case '\$':
        return Icons.attach_money;
      case '€':
        return Icons.euro;
      case '£':
        return Icons.currency_pound;
      case '¥':
        return Icons.currency_yen;
      case '₽':
        return Icons.currency_ruble;
      default:
        return Icons.money;
    }
  }

  void _openCurrencySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Currency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _currencyOptions.length,
              itemBuilder: (_, index) {
                final currency = _currencyOptions[index];
                final isSelected = currency['symbol'] == _selectedCurrency;

                return ListTile(
                  leading: Icon(
                    _getCurrencyIcon(currency['symbol']!),
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text('${currency['symbol']} - ${currency['name']}'),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    _saveCurrency(currency['symbol']!);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 1,
      ),
      body: ListView(
        children: [
          // Appearance section
          _buildSectionHeader("Appearance"),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text("Dark Mode"),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _saveTheme,
            ),
          ),
          const Divider(height: 1),

          // Preferences section
          _buildSectionHeader("Preferences"),
          ListTile(
            leading: Icon(_getCurrencyIcon(_selectedCurrency)),
            title: const Text("Currency"),
            subtitle: Text('Selected: $_selectedCurrency'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openCurrencySelector,
          ),
          const Divider(height: 1),

          // Danger zone section
          _buildSectionHeader("Danger Zone"),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Clear All Expenses",
              style: TextStyle(color: Colors.red),
            ),
            onTap: _clearAllData,
          ),
        ],
      ),
    );
  }
}
