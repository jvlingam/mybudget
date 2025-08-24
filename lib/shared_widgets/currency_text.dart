// lib/shared_widgets/currency_text.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String currencySymbol;

  const CurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.currencySymbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$currencySymbol${amount.toStringAsFixed(2)}',
      style: style,
    );
  }
}

