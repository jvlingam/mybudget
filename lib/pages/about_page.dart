import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80),
            const SizedBox(height: 16),
            Text(
              'MyBudget Tracker',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Text(
              'A simple and powerful budgeting app to track your expenses and manage your finances.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Text(
              '© 2025 MyBudget Team. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
