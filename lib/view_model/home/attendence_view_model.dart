import 'dart:async';
import 'dart:developer';
import 'package:attendence_tracker/view_model/admin/admin_view_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceViewModel extends ChangeNotifier {
  final AdminViewModel _adminViewModel = AdminViewModel();

  bool isLoading = true;
  Map<String, dynamic>? officeData;
  double? distanceFromOffice; // New variable to store the distance
  bool isCheckedIn = false; // New variable to store check-in status

  StreamSubscription<Position>? positionStream;

  Future<void> fetchOfficeCoordinates() async {
    isLoading = true;
    notifyListeners();

    try {
      // Fetch office data from AdminViewModel
      await _adminViewModel.fetchOfficeData();
      officeData = _adminViewModel.officeData;
      log('Fetched Office Data: $officeData');
    } catch (e) {
      log('Error fetching office data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
      _startTracking();
    }
  }

  void _startTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update distance every 10 meters
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        checkUserLocation();
        log('Started tracking location');
      },
    );
  }

  Future<void> checkUserLocation() async {
    if (officeData == null) {
      log('Office data is not available. Cannot check user location.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double officeLat = double.parse(officeData?['officeLat'] ?? '0');
      double officeLong = double.parse(officeData?['officeLong'] ?? '0');

      distanceFromOffice = Geolocator.distanceBetween(
          position.latitude, position.longitude, officeLat, officeLong);

      log('Distance from office: $distanceFromOffice meters');

      // Define your range (e.g., 200 meters)
      log('Office Range: ${officeData?['range']}');
      double range = double.tryParse(officeData?['range'] ?? '40') ?? 40.0;
      isCheckedIn = distanceFromOffice! <= range;

      log('User is within the office range: $isCheckedIn');
      notifyListeners();
    } catch (e) {
      log('Error checking user location: $e');
    }
  }
}
