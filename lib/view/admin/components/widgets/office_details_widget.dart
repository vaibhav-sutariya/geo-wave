import 'package:flutter/material.dart';

class OfficeDetailsWidget extends StatelessWidget {
  OfficeDetailsWidget({
    super.key,
    required this.text,
    required this.icon,
  });
  String text;
  IconData icon;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87, // Softer black for readability
            ),
          ),
        ),
      ],
    );
  }
}
