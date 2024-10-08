import 'dart:developer';

import 'package:attendence_tracker/view_model/services/firestore_services.dart';
import 'package:flutter/foundation.dart';

class AdminViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  Map<String, dynamic>? officeData;
  List<Map<String, dynamic>> employees = [];

  Future<void> fetchOfficeData() async {
    isLoading = true;
    // notifyListeners();

    try {
      officeData = await _firestoreService.getOffice();
      log('Office data: $officeData');
    } catch (e) {
      // Handle error accordingly
    } finally {
      isLoading = false;
      // notifyListeners();
    }
  }

  // Fetch Employee Data
  Future<void> fetchEmployees() async {
    isLoading = true;
    try {
      employees = await _firestoreService.fetchEmployees();
      notifyListeners();
      log('Employees: $employees');
    } catch (e) {
      print('Error fetching employees in ViewModel: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> addOffice(
      String name, String lat, String long, String range) async {
    try {
      await _firestoreService.addOffice(name, lat, long, range);
      fetchOfficeData(); // Refresh the office data after adding
    } catch (e) {
      throw Exception('Failed to add office');
    }
  }

  Future<void> updateOffice(
      String name, String lat, String long, String range) async {
    isLoading = true;
    try {
      await _firestoreService.UpdateOffice(name, lat, long, range);
      fetchOfficeData(); // Refresh the office data after updating
    } catch (e) {
      throw Exception('Failed to update office');
    } finally {
      isLoading = false;
    }
  }

  Future<void> addEmployee(String name, String email, String position) async {
    try {
      await _firestoreService.addEmployee(name, email, position);
      fetchEmployees(); // Fetch employee data after adding
    } catch (e) {
      throw Exception('Failed to add employee');
    }
  }
}
