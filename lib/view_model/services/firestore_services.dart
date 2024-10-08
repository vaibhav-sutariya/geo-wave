import 'package:attendence_tracker/res/components/generate_randomId.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getOffice() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('offices')
          .doc(_auth.currentUser?.uid)
          .get();

      if (snapshot.exists) {
        return snapshot.data();
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error fetching office: $e');
    }
  }

  // Add or Update Office Details
  Future<void> UpdateOffice(
      String officeName, String officeLat, String officeLong, String range,
      {String? officeId}) async {
    try {
      final officeData = {
        'admin': _auth.currentUser!.email,
        // 'uid': uid,
        'officeName': officeName,
        'officeLat': officeLat,
        'officeLong': officeLong,
        'range': range,
        // 'createdAt': DateTime.now(),
        // 'uniqueId': uniqueId,
      };

      // Update existing office details
      await _firestore
          .collection('offices')
          .doc(_auth.currentUser?.uid)
          .update(officeData);
    } catch (e) {
      print('Error adding/updating office data: $e');
      rethrow;
    }
  }

  Future<void> addOffice(String officeName, String officeLat, String officeLong,
      String range) async {
    try {
      // Get the current user's UID
      String uid = _auth.currentUser!.uid;

      // Generate a unique ID starting with officeName and random characters
      String uniqueId = generateRandomId('$officeName-');

      // Add office data to Firestore under the user's UID
      await _firestore.collection('offices').doc(uid).set({
        'admin': _auth.currentUser!.email,
        'uid': uid,
        'officeName': officeName,
        'officeLat': officeLat,
        'officeLong': officeLong,
        'range': range,
        'createdAt': DateTime.now(),
        'uniqueId': uniqueId,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add office: $e');
    }
  }

  Future<void> addEmployee(String name, String email, String id) async {
    try {
      final employeeData = {
        'name': name,
        'email': email,
        'id': id,
        'isAdmin': false,
        // 'officeId': uniqueId,
        'createdAt': DateTime.now(),
        // 'eId': employeeId,
        'role': 'employee',
      };
      await _firestore.collection('employees').add(employeeData);
    } catch (e) {
      print('Error adding employee: $e');
      rethrow;
    }
  }

  // Fetch Employees
  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    try {
      final snapshot = await _firestore.collection('employees').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching employees: $e');
      rethrow;
    }
  }
}
