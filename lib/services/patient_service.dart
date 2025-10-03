import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Test Firestore connection
  Future<bool> testConnection() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Try to write a test document
      await _firestore.collection('test').doc('connection_test').set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });
      return true;
    } catch (e) {
      print('Firestore test error: $e');
      return false;
    }
  }

  // Add a new patient to Firestore
  Future<void> addPatient(Map<String, dynamic> patientData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Add ASHA worker ID to patient data
      patientData['ashaWorkerId'] = user.uid;
      patientData['createdAt'] = FieldValue.serverTimestamp();
      patientData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('patients').add(patientData);
    } catch (e) {
      throw Exception('Failed to add patient: $e');
    }
  }

  // Get all patients for current ASHA worker
  Stream<QuerySnapshot> getPatientsStream() {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('patients')
          .where('ashaWorkerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      // Return an empty stream on error
      return const Stream.empty();
    }
  }

  // Get patients by category
  Stream<QuerySnapshot> getPatientsByCategory(String category) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('patients')
          .where('ashaWorkerId', isEqualTo: user.uid)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      return const Stream.empty();
    }
  }
}