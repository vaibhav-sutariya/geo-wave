import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget {
  const MyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Location Tracker'),
      // automaticallyImplyLeading: false,
      centerTitle: true,
    );
  }
}
