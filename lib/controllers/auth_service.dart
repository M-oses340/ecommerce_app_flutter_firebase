import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // 🟢 Create account with email + password
  Future<String> createAccountWithEmail(String name, String email, String password) async {
    try {
      debugPrint("🟩 [AuthService] Creating account for $email");

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      // Save to Firestore
      await DbService().saveUserData(
        name: name,
        email: email,
        photoUrl: user?.photoURL,
      );

      // Send verification email
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint("📨 [AuthService] Verification email sent to $email");
      }

      debugPrint("✅ [AuthService] Account created for $email");
      return "Account Created — Verify your email";
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ [AuthService] createAccount error: ${e.code} - ${e.message}");
      return e.message.toString();
    } catch (e) {
      debugPrint("⚠️ [AuthService] Unexpected createAccount error: $e");
      return "An unexpected error occurred.";
    }
  }

  // 🟦 Login with email + password
  Future<String> loginWithEmail(String email, String password) async {
    try {
      debugPrint("🟦 [AuthService] Logging in user: $email");

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return "Login failed. Please try again.";

      if (!user.emailVerified) {
        debugPrint("🚫 [AuthService] Email not verified for $email");
        await user.sendEmailVerification();
        debugPrint("📧 [AuthService] Verification email re-sent to $email");
        await FirebaseAuth.instance.signOut();
        return "Email not verified. A new verification link has been sent.";
      }

      debugPrint("✅ [AuthService] Login successful for $email");
      return "Login Successful";
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ [AuthService] login error: ${e.code} - ${e.message}");
      return e.message.toString();
    } catch (e) {
      debugPrint("❌ [AuthService] login unknown error: $e");
      return "An unexpected error occurred.";
    }
  }

  // 🟨 Logout
  Future logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // 🟧 Reset password
  Future resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return "Mail Sent";
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ [AuthService] resetPassword error: ${e.code} - ${e.message}");
      return e.message.toString();
    }
  }

  // 🟩 Check if logged in
  Future<bool> isLoggedIn() async {
    var user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  // 🟦 Update email
  Future<String> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "no-user";

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      if (user.email != newEmail) {
        await user.updateEmail(newEmail);
        await user.sendEmailVerification();
        await DbService().updateUserData(extraData: {"email": newEmail});
      }

      return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password") return "wrong-password";
      if (e.code == "invalid-credential") return "invalid-credential";
      if (e.code == "user-not-found") return "user-not-found";
      if (e.code == "email-already-in-use") return "email-already-in-use";
      if (e.code == "requires-recent-login") return "requires-recent-login";
      return "unknown";
    } catch (_) {
      return "unknown";
    }
  }

  // 🟢 Sign in with Google
  Future<String> signInWithGoogle() async {
    try {
      debugPrint("🟢 [AuthService] Starting Google sign-in...");

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return "cancelled";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await DbService().saveUserData(
          name: user.displayName ?? "User",
          email: user.email ?? "No Email",
          photoUrl: user.photoURL,
        );

        debugPrint("✅ [AuthService] Google sign-in successful: ${user.email}");
        return "Login Successful";
      } else {
        return "Login failed. Please try again.";
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ [AuthService] Google sign-in Firebase error: ${e.code} - ${e.message}");
      return "Google sign-in failed. ${e.message}";
    } catch (e) {
      debugPrint("❌ [AuthService] Google sign-in unexpected error: $e");
      return "Google sign-in failed. Please try again.";
    }
  }
}
