import 'dart:developer';
import 'package:attendence_tracker/res/components/drawer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isCheckedIn = false; // Boolean flag for check-in status
  double distance = 0.0;
  final List<Map<String, dynamic>> _logs = [];
  DateTime? checkInTime;
  DateTime? checkOutTime;
  int? effectiveTime;

  // Dynamic office latitude and longitude
  double? officeLatitude;
  double? officeLongitude;
  final double range = 40.0; // range in meters

  StreamSubscription<Position>? positionStream;

  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference? logRef;
  // DatabaseReference? logsRef; // Reference to fetch logs from Firebase

  @override
  void initState() {
    super.initState();
    _fetchOfficeCoordinates(); // Fetch office coordinates from Firestore
    // _fetchLogsFromFirebase(); // Fetch existing logs from Firebase
    _loadPreferences();
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

// Method to store logs in Shared Preferences
  Future<void> _storeLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final String todayDate = DateTime.now().toIso8601String().split('T').first;

    final checkInLog = {
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'effective_time': effectiveTime,
    };

    final logs = prefs.getStringList('$uid/$todayDate') ?? [];
    logs.add(checkInLog.toString());
    await prefs.setStringList('$uid/$todayDate', logs);
  }

// Updated check-in method
  void _checkIn() async {
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

      // Store the check-in time in Firebase Realtime Database
      final String uid = user.uid;
      final String todayDate =
          DateTime.now().toIso8601String().split('T').first;

      database.ref('logs/$uid/$todayDate').set({
        'check_in_time': checkInTime!.toIso8601String(),
        'check_out_time': null,
        'effective_time': null,
      });

      await _storeLogs(); // Store logs in shared preferences
    }
  }

// Updated check-out method
  void _checkOut() async {
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

      // Update the check-out time and effective time in Firebase Realtime Database
      final String uid = user.uid;
      final String todayDate =
          DateTime.now().toIso8601String().split('T').first;

      database.ref('logs/$uid/$todayDate').update({
        'check_out_time': checkOutTime!.toIso8601String(),
        'effective_time': effectiveTime,
      });

      await _storeLogs(); // Store logs in shared preferences
    }
  }

  // void _fetchLogsFromFirebase() {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     final String uid = user.uid;
  //     final String todayDate =
  //         DateTime.now().toIso8601String().split('T').first;

  //     database.ref('logs/$uid/$todayDate').once().then((DatabaseEvent event) {
  //       final snapshot = event.snapshot;
  //       final value = snapshot.value;

  //       if (value != null && value is Map) {
  //         setState(() {
  //           // _logs.clear(); // Clear previous logs

  //           final Map<Object?, Object?> logEntries =
  //               value as Map<Object?, Object?>;

  //           logEntries.forEach((key, log) {
  //             if (log is Map) {
  //               final timestamp = log['chek_in_time']?.toString() ?? 'N/A';
  //               const status = 'status';

  //               _logs.add({
  //                 'timestamp': timestamp,
  //                 'status': status,
  //               });
  //             }
  //           });

  //           log('Logs fetched: $logEntries');
  //         });
  //       } else {
  //         log('No logs found or incorrect data format.');
  //       }
  //     });
  //   }
  // }

  Future<void> _loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedCheckInTime = prefs.getString('check_in_time');
    final String? storedCheckOutTime = prefs.getString('check_out_time');
    final double? storedEffectiveTime = prefs.getDouble('effective_time');

    setState(() {
      if (storedCheckInTime != null) {
        checkInTime = DateTime.parse(storedCheckInTime);
        isCheckedIn = true;
      } else {
        checkInTime = null;
        isCheckedIn = false;
      }

      if (storedCheckOutTime != null) {
        checkOutTime = DateTime.parse(storedCheckOutTime);
      } else {
        checkOutTime = null;
      }

      effectiveTime = storedEffectiveTime as int?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Location Tracker',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Column(
                  children: [
                    // Display check-in/check-out status based on the boolean flag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 30,
                            color: isCheckedIn ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${isCheckedIn ? "Checked In" : "Checked Out"}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isCheckedIn ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 16), // Increased spacing for better layout

                    // Display distance from office
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Distance from office: ${distance.toStringAsFixed(2)} meters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCheckedIn
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 30,
                          color: isCheckedIn ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Detailed Office Time',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8.0,
                            spreadRadius: 1.0,
                          ),
                        ],
                      ),
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              color: Colors.grey.shade300, width: 0.5),
                          verticalInside: BorderSide(
                              color: Colors.grey.shade300, width: 0.5),
                          left: BorderSide(
                              color: Colors.grey.shade300, width: 0.5),
                          right: BorderSide(
                              color: Colors.grey.shade300, width: 0.5),
                          top: BorderSide.none,
                          bottom: BorderSide.none,
                        ),
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(
                                  'FIRST CHECK IN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(
                                  'FIRST CHECK OUT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(
                                  'EFFECTIVE TIME IN OFFICE (MINUTES)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(12)),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(
                                  checkInTime != null
                                      ? _formatTime(checkInTime!)
                                      : 'N/A',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(
                                  checkOutTime != null
                                      ? _formatTime(checkOutTime!)
                                      : 'N/A',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(
                                  effectiveTime != null
                                      ? '$effectiveTime minutes'
                                      : '00',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 28, // Slightly larger for better visibility
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(
                            width: 8), // Increased spacing for better alignment
                        Text(
                          'Office Logs',
                          style: TextStyle(
                            fontSize:
                                20, // Increased font size for better readability
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                        height: 12), // Increased spacing for better aesthetics
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              color: Colors.grey.shade300, width: 0.5),
                          verticalInside: BorderSide(
                              color: Colors.grey.shade300, width: 0.5),
                          left: BorderSide(
                              color: Colors.grey.shade300, width: 0.5),
                          right: BorderSide(
                              color: Colors.grey.shade300, width: 0.5),
                          top: BorderSide.none,
                          bottom: BorderSide.none,
                        ),
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(
                                  'TIMESTAMP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(
                                  'STATUS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ..._logs.map(
                            (log) => TableRow(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(12)),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 16.0),
                                  child: Text(
                                    log['timestamp']!,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 16.0),
                                  child: Text(
                                    log['status']!,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
