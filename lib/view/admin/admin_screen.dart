import 'dart:async';
import 'dart:developer';

import 'package:attendence_tracker/res/components/drawer.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import 'package:attendence_tracker/repository/get_current_location.dart'; // Your location service file

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Controllers for office details
  TextEditingController officeName = TextEditingController();
  TextEditingController officeLat = TextEditingController();
  TextEditingController officeLong = TextEditingController();
  TextEditingController employeeIdController = TextEditingController();
  String selectedEmployeeType = 'Employee'; // Default type is 'Employee'

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // To store and display fetched office and employee details
  String? officeKey; // Store the office key
  String? officeDetails;
  String? Name;
  var Lat;
  var Long;
  bool isEditingOffice = false;
  bool isAddingEmployee = false;
  List<Map<String, dynamic>> employees = [];

  // Function to fetch and display the current location
  Future<void> _setCurrentLocation() async {
    Position position = await getUserCurrentLocation();
    setState(() {
      officeLat.text = position.latitude.toString();
      officeLong.text = position.longitude.toString();
    });
  }

  // Function to add or update office details in Firestore
  Future<void> _addOrUpdateOfficeInFirestore() async {
    String name = officeName.text;
    String lat = officeLat.text;
    String long = officeLong.text;

    if (name.isNotEmpty && lat.isNotEmpty && long.isNotEmpty) {
      // Get the current user's UID
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        // If officeKey exists, update the existing office data
        if (officeKey != null) {
          await _firestore.collection('offices').doc(officeKey).update({
            'office_name': name,
            'latitude': lat,
            'longitude': long,
            'uid': uid, // Store office under current user's UID
          });
        } else {
          // Add a new office if none exists
          DocumentReference docRef =
              await _firestore.collection('offices').add({
            'office_name': name,
            'latitude': lat,
            'longitude': long,
            'uid': uid, // Store office under current user's UID
          });

          // Store the document ID (officeKey) for future updates
          officeKey = docRef.id;
        }
      }
    }
    _fetchOfficeFromFirestore();
  }

  @override
  void initState() {
    super.initState();
    _fetchOfficeFromFirestore();
    _fetchEmployeesFromFirestore(); // Fetch employee data
  }

  // Function to fetch and display the last added office from Firestore
  void _fetchOfficeFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('offices')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final officeData = snapshot.docs.first.data() as Map<String, dynamic>;
        officeKey = snapshot.docs.first.id;

        setState(() {
          Name = officeData['office_name'];
          Lat = officeData['latitude'];
          Long = officeData['longitude'];
          log('Office Name: $Name, Latitude: $Lat, Longitude: $Long');
          officeDetails =
              'Office Name: $Name, Latitude: $Lat, Longitude: $Long';
        });
      }
    }
  }

  // Function to add an employee to Firestore
  Future<void> _addEmployeeToFirestore() async {
    String employeeId = employeeIdController.text;
    if (employeeId.isNotEmpty) {
      await _firestore.collection('employees').add({
        'employee_id': employeeId,
        'employee_type': selectedEmployeeType, // Save employee type
      });
      employeeIdController.clear();
      setState(() {
        selectedEmployeeType = 'Employee'; // Reset to default type
      });
      _fetchEmployeesFromFirestore();
    }
  }

  // Function to fetch employees from Firestore
  void _fetchEmployeesFromFirestore() async {
    QuerySnapshot snapshot = await _firestore.collection('employees').get();
    setState(() {
      employees = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
    log('Employees: $employees');
  }

  // Widget to display employee details
  Widget _buildEmployeeList() {
    return employees.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: employees
                .map(
                  (employee) => Text(
                    'Employee ID: ${employee['employee_id']}, Type: ${employee['employee_type']}',
                  ),
                )
                .toList(),
          )
        : const Text('No employees added yet.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text('Admin'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              officeDetails == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Add Office'),
                        const SizedBox(height: 20),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Office Name',
                          ),
                          controller: officeName,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Office Latitude',
                          ),
                          controller: officeLat,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Office Longitude',
                          ),
                          controller: officeLong,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _setCurrentLocation,
                          child: const Text('Current Location'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _addOrUpdateOfficeInFirestore,
                          child: const Text('Add Office'),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              officeDetails != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Office:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text('Office Name: $Name'),
                        Text('Latitude $Lat'),
                        Text('Longitude: $Long'),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isEditingOffice = !isEditingOffice;
                                  });
                                },
                                child: const Text('Edit Office')),
                            const SizedBox(width: 10),
                            ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isAddingEmployee = !isAddingEmployee;
                                  });
                                },
                                child: const Text('Add Employee')),
                          ],
                        ),
                        if (isEditingOffice) ...[
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Edit Office Name',
                            ),
                            controller: officeName,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Edit Office Latitude',
                            ),
                            controller: officeLat,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Edit Office Longitude',
                            ),
                            controller: officeLong,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isEditingOffice = !isEditingOffice;
                                  });
                                  _addOrUpdateOfficeInFirestore();
                                },
                                child: const Text('Save Changes'),
                              ),
                              ElevatedButton(
                                onPressed: _setCurrentLocation,
                                child: const Text('Current Location'),
                              ),
                            ],
                          ),
                        ],
                        if (isAddingEmployee) ...[
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Employee ID',
                            ),
                            controller: employeeIdController,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: selectedEmployeeType,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Employee', child: Text('Employee')),
                              DropdownMenuItem(
                                  value: 'Admin', child: Text('Admin')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedEmployeeType = value!;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Select Employee Type',
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _addEmployeeToFirestore,
                            child: const Text('Add Employee'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text(
                          'Employees:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        _buildEmployeeList(),
                      ],
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
