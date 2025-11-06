// views/login_page.dart
import 'dart:ui';
import 'package:ecommerce_app/controllers/auth_service.dart';
import 'package:ecommerce_app/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();

  bool _isLoading = false;
  bool _isResetLoading = false;
  bool _obscureText = true;

  late AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    _spinnerController.dispose();
    super.dispose();
  }

  // --- Forgot Password Dialog (kept as-is) ---
  void _showForgotPasswordDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ForgotPassword',
      barrierColor: const Color.fromARGB(0, 0, 0, 0),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final viewInsets = MediaQuery.of(context).viewInsets;
          final screenHeight = MediaQuery.of(context).size.height;

          return Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                child: Container(color: const Color.fromARGB(77, 0, 0, 0)),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Material(
                  color: Colors.transparent,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20, 80, 20, 20 + viewInsets.bottom),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: screenHeight - 100,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Forgot Password",
                                  style: TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                const Text("Enter your email"),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _resetEmailController,
                                  enabled: !_isResetLoading,
                                  decoration: const InputDecoration(
                                    label: Text("Email"),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: _isResetLoading
                                          ? null
                                          : () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: _isResetLoading
                                          ? null
                                          : () async {
                                        if (_resetEmailController.text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                              content:
                                              Text("Email cannot be empty")));
                                          return;
                                        }
                                        setDialogState(() {
                                          _isResetLoading = true;
                                        });

                                        try {
                                          String result = await AuthService()
                                              .resetPassword(_resetEmailController.text);

                                          String friendlyMessage =
                                              "Unable to reset password.";

                                          if (result.contains("Mail Sent")) {
                                            friendlyMessage =
                                            "Password reset link sent to your email";
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(friendlyMessage),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            Navigator.pop(context);
                                          } else if (result
                                              .contains("user-not-found")) {
                                            friendlyMessage =
                                            "No account found with this email.";
                                          } else if (result.contains("network")) {
                                            friendlyMessage =
                                            "Network error. Check your connection.";
                                          } else if (result
                                              .contains("internal-error")) {
                                            friendlyMessage =
                                            "Internal error occurred. Try again later.";
                                          }

                                          if (!result.contains("Mail Sent")) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                friendlyMessage,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              backgroundColor: Colors.red.shade400,
                                            ));
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: const Text(
                                                "Unexpected error. Check your internet connection."),
                                            backgroundColor: Colors.red.shade400,
                                          ));
                                          debugPrint('Reset password error: $e');
                                        } finally {
                                          setDialogState(() {
                                            _isResetLoading = false;
                                          });
                                        }
                                      },
                                      child: _isResetLoading
                                          ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                          : const Text("Submit"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        });
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOut,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  // ----------------- Main Build -----------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final logoPath = brightness == Brightness.dark
        ? 'assets/images/logo_dark.png'
        : 'assets/images/logo.png';
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: _isLoading ? const NeverScrollableScrollPhysics() : null,
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    // ---------- Logo ----------
                    Center(
                      child: Image.asset(
                        logoPath,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---------- Welcome Text ----------
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Login to continue",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                    const SizedBox(height: 30),

                    // ---------- Email / Mobile ----------
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                      child: TextFormField(
                        controller: _emailOrPhoneController,
                        enabled: !_isLoading,
                        validator: (value) =>
                        value!.isEmpty ? "Email or Mobile Number cannot be empty." : null,
                        decoration: InputDecoration(
                          labelText: "Email or Mobile Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ---------- Password ----------
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        enabled: !_isLoading,
                        validator: (value) => value!.length < 8
                            ? "Password should have at least 8 characters."
                            : null,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: !_isLoading
                                ? () => setState(() {
                              _obscureText = !_obscureText;
                            })
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ---------- Forgot Password ----------
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.06),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _showForgotPasswordDialog,
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---------- Login Button ----------
                    SizedBox(
                      height: 55,
                      width: screenWidth * 0.88,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);

                            final userProvider =
                            Provider.of<UserProvider>(context, listen: false);

                            try {
                              String result = await AuthService().loginWithEmail(
                                _emailOrPhoneController.text.trim(),
                                _passwordController.text.trim(),
                              );

                              // --- Handle login outcomes ---
                              if (result == "Login Successful") {
                                userProvider.loadUserData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Login Successful"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.restorablePushNamedAndRemoveUntil(
                                  context,
                                  "/home",
                                      (route) => false,
                                );
                              }
                              else if (result.contains("Email not verified")) {
                                // --- Handle email not verified case ---
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "Email not verified. Please check your inbox for the link.",
                                    ),
                                    backgroundColor: Colors.orange.shade700,
                                    action: SnackBarAction(
                                      label: "Resend",
                                      textColor: Colors.white,
                                      onPressed: () async {
                                        try {
                                          final user = FirebaseAuth.instance.currentUser;
                                          if (user != null && !user.emailVerified) {
                                            await user.sendEmailVerification();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content:
                                                Text("Verification link re-sent successfully."),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                "Failed to resend verification link. Try again later.",
                                              ),
                                              backgroundColor: Colors.red.shade400,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }
                              else {
                                // --- Other login errors ---
                                String friendlyMessage = "Login failed. Please try again.";

                                if (result.toLowerCase().contains("wrong-password") ||
                                    result.toLowerCase().contains("incorrect") ||
                                    result.toLowerCase().contains("malformed")) {
                                  friendlyMessage = "Incorrect email or password.";
                                } else if (result.toLowerCase().contains("user-not-found")) {
                                  friendlyMessage = "No account found with this email.";
                                } else if (result.toLowerCase().contains("network")) {
                                  friendlyMessage =
                                  "Network error. Check your internet connection.";
                                } else if (result.toLowerCase().contains("internal-error")) {
                                  friendlyMessage =
                                  "Internal error occurred. Please try again later.";
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(friendlyMessage),
                                    backgroundColor: Colors.red.shade400,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "Unexpected error. Check your internet connection.",
                                  ),
                                  backgroundColor: Colors.red.shade400,
                                ),
                              );
                              debugPrint('Login exception: $e');
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: _isLoading
                              ? RotationTransition(
                            key: const ValueKey('spinner'),
                            turns: _spinnerController,
                            child: const Icon(Icons.autorenew, color: Colors.white),
                          )
                              : const Text(
                            "Login",
                            key: ValueKey('text'),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),


                    const SizedBox(height: 20),

                    // --- OR divider ---
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                      child: const Row(
                        children: [
                          Expanded(child: Divider(thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text("OR ", style: TextStyle(fontSize: 12)),
                          ),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // --- Google Sign-In button ---
                    SizedBox(
                      height: 55,
                      width: screenWidth * 0.88,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Image.asset('assets/images/google_logo.png', height: 22, width: 22),
                        label: const Text("Continue with Google", style: TextStyle(fontSize: 16)),
                        onPressed: _isLoading
                            ? null
                            : () async {
                          setState(() => _isLoading = true);
                          try {
                            String result = await AuthService().signInWithGoogle();
                            if (result == "Login Successful") {
                              if (!mounted) return;
                              Provider.of<UserProvider>(context, listen: false).loadUserData();
                              Navigator.restorablePushNamedAndRemoveUntil(context, "/home", (route) => false);
                            } else if (result == "cancelled") {
                              // user cancelled - do nothing
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(result),
                                backgroundColor: Colors.red.shade400,
                              ));
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text("Google sign-in failed. Try again."),
                                backgroundColor: Colors.red.shade400,
                              ));
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ---------- Sign Up ----------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            Navigator.pushNamed(context, "/signup");
                          },
                          child: const Text("Sign Up"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ---------- Blur Overlay ----------
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isLoading ? 0.3 : 0.0,
              child: IgnorePointer(
                ignoring: !_isLoading,
                child: Container(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
