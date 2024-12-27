import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize Firestore with offline persistence
  Future<void> initializeFirestore() async {
    await FirebaseFirestore.instance.enableNetwork();
    await FirebaseFirestore.instance.waitForPendingWrites();
  }

  // Create or update user data
  Future<void> setupUserData(User firebaseUser) async {
    final userDoc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (!userDoc.exists) {
      String? username;
      String? displayName = firebaseUser.displayName;

      // If user signed in with Google and has a displayName, create a username from it
      if (displayName != null &&
          firebaseUser.providerData.first.providerId == 'google.com') {
        username = await _generateUniqueUsername(displayName);
      }

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        username: username,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toMap());
    } else {
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
        'email': firebaseUser.email,
      });
    }
  }

  // Generate a unique username from display name
  Future<String> _generateUniqueUsername(String displayName) async {
    // Remove spaces and special characters, convert to lowercase
    String baseUsername = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');

    // Trim if longer than 15 chars to allow for numbers
    if (baseUsername.length > 15) {
      baseUsername = baseUsername.substring(0, 15);
    }

    String username = baseUsername;
    int counter = 1;
    bool isUnique = false;

    // Keep trying until we find a unique username
    while (!isUnique) {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (query.docs.isEmpty) {
        isUnique = true;
      } else {
        username = '$baseUsername$counter';
        counter++;
      }
    }

    return username;
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .get();
    return query.docs.isEmpty;
  }

  // Get user data with realtime updates
  Stream<UserModel?> getUserStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'preferences': preferences,
    });
  }
}
