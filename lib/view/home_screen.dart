import 'dart:developer';
import 'package:attendence_tracker/res/components/drawer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isCheckedIn = false; // Boolean flag for check-in status
  double distance = 0.0;
  final List<Map<String, String>> _logs = [];
  DateTime? checkInTime;
  DateTime? checkOutTime;
  int? effectiveTime;

  // Dynamic office latitude and longitude
  double? officeLatitude;
  double? officeLongitude;
  final double range = 200.0; // range in meters

  StreamSubscription<Position>? positionStream;

  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference? logRef;
  DatabaseReference? logsRef; // Reference to fetch logs from Firebase

  @override
  void initState() {
    super.initState();
    _fetchOfficeCoordinates(); // Fetch office coordinates from Firestore
    _fetchLogsFromFirebase(); // Fetch existing logs from Firebase
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  // Fetch office coordinates from Firestore
  Future<void> _fetchOfficeCoordinates() async {
    try {
      // Get current user's UID
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        // Fetch office details from Firestore based on UID
        QuerySnapshot officeSnapshot = await FirebaseFirestore.instance
            .collection('offices')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();

        if (officeSnapshot.docs.isNotEmpty) {
          // Extract latitude and longitude from the fetched office data
          var officeData =
              officeSnapshot.docs.first.data() as Map<String, dynamic>;
          setState(() {
            officeLatitude = double.parse(officeData['latitude']);
            officeLongitude = double.parse(officeData['longitude']);
            log('Office coordinates fetched: $officeLatitude, $officeLongitude');
            _startTracking(); // Start tracking once coordinates are fetched
          });
        } else {
          log('No office data found for this user.');
        }
      }
    } catch (e) {
      log('Error fetching office coordinates: $e');
    }
  }

  void _startTracking() {
    if (officeLatitude == null || officeLongitude == null) {
      log('Office coordinates not available. Cannot start tracking.');
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update distance every 10 meters
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _updateLocation(position);
      },
    );
    log('Started tracking location');
  }

  void _updateLocation(Position position) {
    setState(() {
      // Keep distance in meters for consistency
      distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        officeLatitude!,
        officeLongitude!,
      );
      log('Location updated: ${position.latitude}, ${position.longitude}');
      log('Distance: $distance meters');
    });

    // Use the boolean flag for check-in/out logic
    if (distance <= range && !isCheckedIn) {
      _checkIn();
    } else if (distance > range && isCheckedIn) {
      _checkOut();
    }
  }

  void _checkIn() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isCheckedIn = true;
        checkInTime = DateTime.now();
        checkOutTime = null;
        effectiveTime = null;
        log('Checked in at $checkInTime');
        _logs.add({
          'timestamp': checkInTime!.toIso8601String(),
          'status': 'CHECK IN',
        });
      });

      final String uid = user.uid;
      final String todayDate =
          DateTime.now().toIso8601String().split('T').first;

      // Store the check-in time in Firebase Realtime Database
      database.ref('first_logs/$uid/$todayDate').set({
        'check_in_time': checkInTime!.toIso8601String(),
        'check_out_time': null,
        'effective_time': null,
      });
    }
  }

  void _checkOut() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isCheckedIn = false;
        checkOutTime = DateTime.now();
        effectiveTime = _calculateEffectiveTime();
        log('Checked out at $checkOutTime');
        _logs.add({
          'timestamp': checkOutTime!.toIso8601String(),
          'status': 'CHECK OUT',
        });
      });

      final String uid = user.uid;
      final String todayDate =
          DateTime.now().toIso8601String().split('T').first;

      // Update the check-out time and effective time in Firebase Realtime Database
      database.ref('first_logs/$uid/$todayDate').update({
        'check_out_time': checkOutTime!.toIso8601String(),
        'effective_time': effectiveTime,
      });
    }
  }

  void _fetchLogsFromFirebase() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String uid = user.uid;
      final String todayDate =
          DateTime.now().toIso8601String().split('T').first;

      database
          .ref('first_logs/$uid/$todayDate')
          .once()
          .then((DatabaseEvent event) {
        final snapshot = event.snapshot;
        final value = snapshot.value;

        if (value != null && value is Map) {
          setState(() {
            _logs.clear(); // Clear previous logs

            final Map<Object?, Object?> logEntries =
                value as Map<Object?, Object?>;

            logEntries.forEach((key, log) {
              if (log is Map) {
                final timestamp = log['timestamp']?.toString() ?? 'N/A';
                final status = log['status']?.toString() ?? 'N/A';

                _logs.add({
                  'timestamp': timestamp,
                  'status': status,
                });
              }
            });

            log('Logs fetched: $_logs');
          });
        } else {
          log('No logs found or incorrect data format.');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text('Location Tracker'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Column(
                children: [
                  // Display check-in/check-out status based on the boolean flag
                  Text('Status: ${isCheckedIn ? "Checked In" : "Checked Out"}'),
                  Text(
                      'Distance from office: ${distance.toStringAsFixed(2)} meters'),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detailed Office Time'),
                  const SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(width: 0.125),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      const TableRow(
                        children: [
                          Text('FIRST CHECK IN'),
                          Text('FIRST CHECK OUT'),
                          Text('EFFECTIVE TIME IN OFFICE (MINUTES)'),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text(checkInTime != null
                              ? _formatTime(checkInTime!)
                              : 'N/A'),
                          Text(checkOutTime != null
                              ? _formatTime(checkOutTime!)
                              : 'N/A'),
                          Text(effectiveTime != null
                              ? '$effectiveTime minutes'
                              : '00'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Office Logs'),
                  const SizedBox(height: 10),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                    },
                    border: TableBorder.all(width: 0.125),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      const TableRow(
                        children: [
                          Text('TIMESTAMP'),
                          Text('STATUS'),
                        ],
                      ),
                      ..._logs.map(
                        (log) => TableRow(
                          children: [
                            Text(log['timestamp']!),
                            Text(log['status']!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to calculate effective time in minutes
  int _calculateEffectiveTime() {
    if (checkInTime != null && checkOutTime != null) {
      final duration = checkOutTime!.difference(checkInTime!).inMinutes;
      return duration;
    }
    return 0;
  }

  // Helper function to format the time as a string
  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
