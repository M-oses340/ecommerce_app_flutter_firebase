import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Create account
  Future<String> createAccountWithEmail(String name, String email,
      String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password);
      await DbService().saveUserData(name: name, email: email);
      return "Account Created";
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    }
  }

  // Login
  Future<String> loginWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      return "Login Successful";
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    }
  }

  // Logout
  Future logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // Reset password
  Future resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return "Mail Sent";
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    }
  }

  // Check login
  Future<bool> isLoggedIn() async {
    var user = FirebaseAuth.instance.currentUser;
    return user != null;
  }


  // Update email (with optional reauthentication)
  Future<String> updateEmail({
    required String newEmail,
    String? currentPassword,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return "No user is currently signed in";

      // Reauthenticate if password provided
      if (currentPassword != null && currentPassword.isNotEmpty) {
        final cred = EmailAuthProvider.credential(
            email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(cred);
      }

      // Update Firebase Auth
      await user.updateEmail(newEmail);

      // Send verification email
      await user.sendEmailVerification();

      // Update Firestore user profile
      await DbService().updateUserData(extraData: {"email": newEmail});

      // Update all past orders
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection("shop_orders")
          .where("user_id", isEqualTo: user.uid)
          .get();

      for (var doc in ordersSnapshot.docs) {
        await doc.reference.update({"email": newEmail});
      }

      return "Email updated successfully. All past orders updated. Please verify your new email.";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Error updating email";
    } catch (e) {
      return e.toString();
    }
  }
}
