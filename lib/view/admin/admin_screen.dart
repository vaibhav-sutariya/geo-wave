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

  void _deleteEmployee(String employeeId) async {
    // Reference to the Firestore collection (replace with your actual collection name)
    CollectionReference employeesCollection =
        FirebaseFirestore.instance.collection('employees');

    try {
      // Delete the employee document from Firestore using the employeeId
      await employeesCollection.doc(employeeId).delete();

      // Update the local employees list and the UI
      setState(() {
        employees
            .removeWhere((employee) => employee['employee_id'] == employeeId);
      });

      // Optionally, show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Employee with ID $employeeId deleted successfully')),
      );
    } catch (e) {
      // Handle any errors that occur during deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete employee: $e')),
      );
    }
  }

  // Widget to display employee details
  Widget _buildEmployeeList() {
    return employees.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: employees.map((employee) {
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.badge, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'ID: ${employee['employee_id']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                '${employee['employee_type']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black54),
                        onPressed: () {
                          // Call function to delete the employee from the list
                          _deleteEmployee(employee['employee_id']);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        : const Center(
            child: Text(
              'No employees added yet.',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Admin', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              officeDetails == null
                  ? Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Add Office',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Office Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.business),
                              ),
                              controller: officeName,
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Office Latitude',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.location_on),
                              ),
                              controller: officeLat,
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Office Longitude',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.location_on),
                              ),
                              controller: officeLong,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _setCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Use Current Location'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _addOrUpdateOfficeInFirestore,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Add Office'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              if (officeDetails != null) ...[
                const SizedBox(height: 20),
                Card(
                  elevation:
                      6, // Increased elevation for a more prominent shadow effect
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16), // Smooth, rounded corners
                  ),
                  shadowColor:
                      Colors.blueAccent.withOpacity(0.4), // Softer shadow color
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Office header with improved font and color
                        const Row(
                          children: [
                            Icon(Icons.business,
                                color: Colors.blueAccent), // Icon for office
                            SizedBox(width: 8),
                            Text(
                              'Your Office:',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .blueAccent, // Accent color for better visuals
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                            height: 12), // Increased spacing for aesthetics

                        // Office Name section with icon
                        Row(
                          children: [
                            const Icon(Icons.location_city, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Office Name: $Name',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors
                                      .black87, // Softer black for readability
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // Spacing between details

                        // Latitude section with icon
                        Row(
                          children: [
                            const Icon(Icons.my_location, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Latitude: $Lat',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Longitude section with icon
                        Row(
                          children: [
                            const Icon(Icons.place, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Longitude: $Long',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                            height: 24), // Spacing before the buttons
                        // Row for action buttons with icons and padding
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween, // Equal spacing between buttons
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  isEditingOffice = !isEditingOffice;
                                });
                              },
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text(
                                'Edit Office',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 18,
                                ),
                                backgroundColor: Colors
                                    .greenAccent[700], // Vibrant green color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  isAddingEmployee = !isAddingEmployee;
                                });
                              },
                              icon: const Icon(Icons.person_add,
                                  color: Colors.white),
                              label: const Text(
                                'Add Employee',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 18,
                                ),
                                backgroundColor:
                                    Colors.blueAccent, // Matching blue accent
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ],
                        ),

                        if (isEditingOffice) ...[
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Edit Office Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.business),
                            ),
                            controller: officeName,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Edit Office Latitude',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.location_on),
                            ),
                            controller: officeLat,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Edit Office Longitude',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.location_on),
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
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 18,
                                  ),
                                  backgroundColor: Colors.greenAccent[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _setCurrentLocation,
                                icon: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Use Current Location',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (isAddingEmployee) ...[
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Employee ID',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.badge),
                            ),
                            controller: employeeIdController,
                          ),
                          const SizedBox(height: 15),
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
                            decoration: InputDecoration(
                              labelText: 'Select Employee Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _addEmployeeToFirestore,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 18,
                              ),
                              backgroundColor: Colors.greenAccent[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Add Employee',
                                style: TextStyle(
                                  color: Colors.white,
                                )),
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
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
