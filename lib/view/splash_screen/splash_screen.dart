import 'package:attendence_tracker/repository/location_permission.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Location location = Location();

  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds and then request location permission
    location.checkLocationPermission(context);
    // Future.delayed(const Duration(seconds: 3), () {});
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
      child: Text('Splash Screen'),
    ));
  }
}
