import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Create account
  Future<String> createAccountWithEmail(String name, String email, String password) async {
    try {
      debugPrint("🟩 [AuthService] Creating account for $email");
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await DbService().saveUserData(name: name, email: email);
      debugPrint("✅ [AuthService] Account created for $email");
      return "Account Created";
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ [AuthService] createAccount error: ${e.code} - ${e.message}");
      return e.message.toString();
    }
  }

  // Login
  Future<String> loginWithEmail(String email, String password) async {
    try {
      debugPrint("🔹 [AuthService] Attempting login for $email");
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      debugPrint("✅ [AuthService] Login successful");
      return "Login Successful";
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ [AuthService] login error: ${e.code} - ${e.message}");
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
      debugPrint("⚠️ [AuthService] login unknown error: $e");
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
      debugPrint("❌ [AuthService] resetPassword error: ${e.code} - ${e.message}");
      return e.message.toString();
    }
  }

  // Check login
  Future<bool> isLoggedIn() async {
    var user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  Future<String> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ [AuthService] No signed-in user found");
      return "no-user";
    }

    try {
      print("🟦 [AuthService] Starting password verification...");
      print("   ┣━ Current email: ${user.email}");
      print("   ┣━ Provided password: $currentPassword");
      print("   ┗━ Intended new email: $newEmail");

      // Step 1: Build credentials for reauthentication
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      print("🟣 [AuthService] Attempting reauthenticateWithCredential...");
      final result = await user.reauthenticateWithCredential(credential);
      print("🟢 [AuthService] Reauthenticate result: ${result.credential?.providerId}");

      // Step 2: Only update email if changed
      if (user.email != newEmail) {
        print("🟢 [AuthService] Proceeding to update email...");
        await user.updateEmail(newEmail);
        await user.sendEmailVerification();
        await DbService().updateUserData(extraData: {"email": newEmail});
        print("✅ [AuthService] Email updated successfully!");
      } else {
        print("ℹ️ [AuthService] Email unchanged — skipping update.");
      }

      return "success";
    } on FirebaseAuthException catch (e, st) {
      print("❌ [AuthService] FirebaseAuthException caught!");
      print("   ┣━ Code: ${e.code}");
      print("   ┣━ Message: ${e.message}");
      print("   ┗━ StackTrace: $st");
      if (e.code == "wrong-password") return "wrong-password";
      if (e.code == "invalid-credential") return "invalid-credential";
      if (e.code == "user-not-found") return "user-not-found";
      if (e.code == "email-already-in-use") return "email-already-in-use";
      if (e.code == "requires-recent-login") return "requires-recent-login";
      return "unknown";
    } catch (e, st) {
      print("❌ [AuthService] Non-Firebase Exception: $e");
      if (kDebugMode) {
        print("   ┗━ StackTrace: $st");
      }
      return "unknown";
    }
  }

}
