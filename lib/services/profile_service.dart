import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Save ASHA profile
  Future<void> saveAshaProfile({
    required String name,
    required String mobile,
    required String village,
    required String ward,
    required String experience,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw 'User not logged in';
    
    await _firestore.collection('asha_profiles').doc(userId).set({
      'name': name,
      'mobile': mobile,
      'village': village,
      'ward': ward,
      'experience': experience,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Save PHC profile
  Future<void> savePHCProfile({
    required String name,
    required String mobile,
    required String designation,
    required String department,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw 'User not logged in';
    
    await _firestore.collection('phc_profiles').doc(userId).set({
      'name': name,
      'mobile': mobile,
      'designation': designation,
      'department': department,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Get ASHA profile
  Future<Map<String, dynamic>?> getAshaProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    
    final doc = await _firestore.collection('asha_profiles').doc(userId).get();
    return doc.data();
  }
  
  // Get PHC profile
  Future<Map<String, dynamic>?> getPHCProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    
    final doc = await _firestore.collection('phc_profiles').doc(userId).get();
    return doc.data();
  }
  
  // Get profile stream (real-time updates)
  Stream<DocumentSnapshot> getProfileStream(String role) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw 'User not logged in';
    
    final collection = role == 'ASHA' ? 'asha_profiles' : 'phc_profiles';
    return _firestore.collection(collection).doc(userId).snapshots();
  }
}
