import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Create account
  Future<String> createAccountWithEmail(String name, String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
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
      // Map Firebase error codes and messages to friendly UI messages
      if (e.code == "wrong-password" ||
          e.message?.contains("incorrect") == true ||
          e.message?.contains("malformed") == true ||
          e.message?.contains("expired") == true) {
        return "Incorrect email or password.";
      } else if (e.code == "user-not-found") {
        return "No account found with this email.";
      } else if (e.code == "network-request-failed") {
        return "Network error. Check your connection.";
      } else if (e.code == "internal-error") {
        return "Internal error occurred. Try again later.";
      } else {
        return "Login failed. Please try again.";
      }
    } catch (e) {
      return "Unexpected error. Check your internet connection.";
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

  // Update email with current password (reauthentication)
  Future<String> updateEmail({
    required String newEmail,
    required String currentPassword, // must be provided for reauth
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return "No user is currently signed in";

      // Reauthenticate user
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Update Firebase Auth email
      await user.updateEmail(newEmail);

      // Optional: send verification email
      await user.sendEmailVerification();

      // Update Firestore user profile
      await DbService().updateUserData(extraData: {"email": newEmail});

      return "Email updated successfully. Please verify your new email.";
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password") {
        return "Wrong password"; // clearly indicate wrong password
      } else if (e.code == "email-already-in-use") {
        return "This email is already in use";
      } else {
        return e.message ?? "Error updating email";
      }
    } catch (e) {
      return e.toString();
    }
  }
}
