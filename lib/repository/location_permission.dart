import 'package:attendence_tracker/utils/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _dialogShown = false;

class Location {
  Future<void> checkLocationPermission(BuildContext context) async {
    var status = await Permission.location.status;

    // Check if permission is denied, restricted, or permanently denied
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      // Request location permission
      if (await Permission.location.request().isGranted) {
        // If permission is granted, check if location services are enabled
        _checkLocationServices(context);
      } else {
        // Permission is restricted or permanently denied
        _showPermissionDeniedDialog(
            context); // Show dialog if permission is denied
      }
    } else if (status.isGranted) {
      // If permission is already granted, check if location services are enabled
      _checkLocationServices(context);
    }
  }

  void _checkLocationServices(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!_dialogShown) {
        _dialogShown = true; // Set the flag to true when showing the dialog
        _showLocationServicesDialog(context);
      }
    } else {
      // Check in shared preferences if the user is logged in
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        // If logged in, navigate to the home screen
        if (context.mounted) {
          Navigator.pushReplacementNamed(context,
              RoutesName.home); // Assuming this is the route to home screen
        }
      } else {
        // If not logged in, navigate to the sign-in screen
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, RoutesName.signIn);
        }
      }
    }
  }

  void _showLocationServicesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Text(
              'Location services are required for this app. Please enable location services.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Settings'),
              onPressed: () async {
                await Geolocator.openLocationSettings();

                // Start a periodic check for location service status
                _checkLocationServicesContinuously(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to periodically check for location service status
  void _checkLocationServicesContinuously(BuildContext context) async {
    bool serviceEnabled = false;

    // Periodically check every 1 second to see if location services are enabled
    while (!serviceEnabled) {
      await Future.delayed(const Duration(seconds: 1));

      serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (serviceEnabled) {
        // If location services are enabled, check if user is logged in
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

        if (context.mounted) {
          Navigator.of(context).pop(); // Close the dialog

          if (isLoggedIn) {
            Navigator.pushReplacementNamed(context, RoutesName.home);
          } else {
            Navigator.pushReplacementNamed(context, RoutesName.signIn);
          }

          _dialogShown = false; // Reset the flag when navigating
        }
        break; // Exit the loop when services are enabled
      }
    }
  }

  // Show dialog if location permission is denied
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Denied'),
          content: const Text(
              'This app requires location access to function. Please grant location permission.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                checkLocationPermission(context); // Retry requesting permission
              },
            ),
          ],
        );
      },
    );
  }
}
