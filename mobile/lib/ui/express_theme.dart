import 'package:flutter/material.dart';

const Color forest = Color(0xFF123F31);
const Color muted = Color(0xFF7A8A83);
const Color lime = Color(0xFFEAF6A6);
const Color orange = Color(0xFFE65520);

class Brand extends StatelessWidget {
  const Brand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: lime,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'E',
            style: TextStyle(
              color: forest,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'express.',
          style: TextStyle(
            color: forest,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error.toString().replaceFirst('Exception: ', ''),
      ),
      backgroundColor: Colors.red.shade700,
    ),
  );
}