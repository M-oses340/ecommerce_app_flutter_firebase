// ... keep your imports
import 'dart:ui';
import 'package:ecommerce_app/controllers/auth_service.dart';
import 'package:ecommerce_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    _spinnerController.dispose();
    super.dispose();
  }
  void _showForgotPasswordDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ForgotPassword',
      barrierColor: Color.fromARGB(0, 0, 0, 0),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final viewInsets = MediaQuery.of(context).viewInsets; // keyboard height
          final screenHeight = MediaQuery.of(context).size.height;

          return Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                child: Container(color: Color.fromARGB(77, 0, 0, 0)), // 30% opacity
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Material(
                  color: Colors.transparent,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                            20, 80, 20, 20 + viewInsets.bottom),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: screenHeight - 100, // prevent overflow
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
                                        if (_resetEmailController
                                            .text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Email cannot be empty")));
                                          return;
                                        }
                                        setDialogState(() {
                                          _isResetLoading = true;
                                        });

                                        try {
                                          String result = await AuthService()
                                              .resetPassword(
                                              _resetEmailController.text);

                                          String friendlyMessage =
                                              "Unable to reset password.";

                                          if (result.contains("Mail Sent")) {
                                            friendlyMessage =
                                            "Password reset link sent to your email";
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                content:
                                                Text(friendlyMessage),
                                                backgroundColor:
                                                Colors.green));
                                            Navigator.pop(context);
                                          } else if (result
                                              .contains("user-not-found")) {
                                            friendlyMessage =
                                            "No account found with this email.";
                                          } else if (result
                                              .contains("network")) {
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
                                              content: Text(friendlyMessage,
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                              backgroundColor:
                                              Colors.red.shade400,
                                            ));
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: const Text(
                                                "Unexpected error. Check your internet connection."),
                                            backgroundColor: Colors.red.shade400,
                                          ));
                                          debugPrint(
                                              'Reset password error: $e');
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
        // Slide from top animation
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, -1), // start above the screen
          end: Offset.zero,            // final position
        ).animate(
          CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOut,
          ),
        );

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


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics:
              _isLoading ? const NeverScrollableScrollPhysics() : null,
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 120),
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Login",
                            style: TextStyle(
                                fontSize: 40, fontWeight: FontWeight.w700),
                          ),
                          const Text("Get started with your account"),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            validator: (value) =>
                            value!.isEmpty ? "Email cannot be empty." : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              label: Text("Email"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        enabled: !_isLoading,
                        validator: (value) => value!.length < 8
                            ? "Password should have at least 8 characters."
                            : null,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          label: const Text("Password"),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: !_isLoading
                                ? () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            }
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                          _isLoading ? null : _showForgotPasswordDialog,
                          child: const Text("Forgot Password"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 60,
                      width: screenWidth * 0.9,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });

                            final userProvider =
                            Provider.of<UserProvider>(context,
                                listen: false);

                            try {
                              String result = await AuthService()
                                  .loginWithEmail(
                                  _emailController.text,
                                  _passwordController.text);

                              if (result == "Login Successful") {
                                userProvider.loadUserData();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                    content:
                                    Text("Login Successful")));
                                Navigator.restorablePushNamedAndRemoveUntil(
                                    context, "/home", (route) => false);
                              } else {
                                // Map FirebaseAuth / Recaptcha / Wrong password messages
                                String friendlyMessage =
                                    "Login failed. Please try again.";

                                if (result
                                    .toLowerCase()
                                    .contains("wrong-password") ||
                                    result
                                        .toLowerCase()
                                        .contains("incorrect") ||
                                    result
                                        .toLowerCase()
                                        .contains("malformed") ||
                                    result.toLowerCase().contains("expired") ||
                                    result
                                        .toLowerCase()
                                        .contains("recaptcha")) {
                                  friendlyMessage =
                                  "Incorrect email or password.";
                                } else if (result
                                    .toLowerCase()
                                    .contains("user-not-found")) {
                                  friendlyMessage =
                                  "No account found with this email.";
                                } else if (result
                                    .toLowerCase()
                                    .contains("network")) {
                                  friendlyMessage =
                                  "Network error. Check your connection.";
                                } else if (result
                                    .toLowerCase()
                                    .contains("internal-error")) {
                                  friendlyMessage =
                                  "Internal error occurred. Try again later.";
                                }

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(friendlyMessage),
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
                              debugPrint('Login exception: $e');
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                          child: _isLoading
                              ? RotationTransition(
                            key: const ValueKey('spinner'),
                            turns: _spinnerController,
                            child: const Icon(Icons.autorenew,
                                color: Colors.white),
                          )
                              : const Text(
                            "Login",
                            key: ValueKey('text'),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                            child: const Text("Sign Up"))
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isLoading ? 0.3 : 0.0,
              child: IgnorePointer(
                ignoring: !_isLoading,
                child: Container(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
