import 'package:flutter/material.dart';

class SetupSummaryRow extends StatelessWidget {
  const SetupSummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE7C76F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}