import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';

class AdminAuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get currently signed in admin
  User? get currentUser => _auth.currentUser;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with email and password
  Future<AdminUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Login failed. User is null.');
      }
      
      // Verify user is an admin by checking Admins collection
      final adminDoc = await _firestore
          .collection('Admins')
          .doc(credential.user!.uid)
          .get();
      
      if (!adminDoc.exists) {
        // User is not an admin, sign them out
        await _auth.signOut();
        throw Exception('Access denied. You do not have admin privileges.');
      }
      
      // Update last login timestamp
      await _firestore
          .collection('Admins')
          .doc(credential.user!.uid)
          .update({
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Return admin user object
      return AdminUser.fromFirestore(adminDoc.data() ?? {}, credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password.');
      } else {
        throw Exception('Authentication failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final adminDoc = await _firestore
          .collection('Admins')
          .doc(user.uid)
          .get();
      
      return adminDoc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
  
  // Get current admin user details
  Future<AdminUser?> getCurrentAdminUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final adminDoc = await _firestore
          .collection('Admins')
          .doc(user.uid)
          .get();
      
      if (!adminDoc.exists) return null;
      
      return AdminUser.fromFirestore(adminDoc.data() ?? {}, user.uid);
    } catch (e) {
      print('Error getting admin user: $e');
      return null;
    }
  }
  
  // Create admin user (should be called only by existing admins)
  Future<void> createAdminUser(String email, String password, String name) async {
    try {
      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only existing admins can create new admin accounts.');
      }
      
      // Create user with Firebase Auth
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Failed to create user.');
      }
      
      // Add user to Admins collection
      await _firestore
          .collection('Admins')
          .doc(credential.user!.uid)
          .set({
        'email': email,
        'name': name,
        'role': 'admin',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Sign out the new admin (they should sign in themselves)
      if (_auth.currentUser?.uid == credential.user!.uid) {
        await _auth.signOut();
      }
    } catch (e) {
      throw Exception('Failed to create admin: ${e.toString()}');
    }
  }
}