import 'package:flutter/material.dart';

class EmployeeCheckScreen extends StatefulWidget {
  const EmployeeCheckScreen({super.key});

  @override
  State<EmployeeCheckScreen> createState() => _EmployeeCheckScreenState();
}

class _EmployeeCheckScreenState extends State<EmployeeCheckScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Check'),
      ),
      body: const Center(
          child: Column(
        children: [
          Text('You are not Employee'),
        ],
      )),
    );
  }
}
