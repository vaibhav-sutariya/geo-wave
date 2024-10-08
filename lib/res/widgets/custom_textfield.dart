import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.labelText,
    required this.prefixIcon,
    required this.controller,
  });

  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        elevation: 3, // Adds shadow to give a floating effect
        borderRadius: BorderRadius.circular(12), // Soft rounded corners
        child: TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87, // Text color
          ),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(
              fontSize: 14,
              color: Colors.blueAccent[400], // Label text color
            ),
            filled: true,
            fillColor: Colors.white, // Background color
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // Removes the default border
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.blueAccent, // Icon color
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 10,
            ), // Adjusts spacing inside the text field
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.blueAccent, // Border color when focused
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.blueAccent, // Border color when focused
                width: 0.5,
              ),
              // borderSide: BorderSide.none, // Border when not focused
            ),
          ),
        ),
      ),
    );
  }
}
