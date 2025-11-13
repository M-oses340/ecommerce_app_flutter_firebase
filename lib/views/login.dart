// views/login_page.dart
import 'dart:ui';
import 'package:ecommerce_app/controllers/auth_service.dart';
import 'package:ecommerce_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final FlutterSecureStorage storage = const FlutterSecureStorage();

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
    if (_spinnerController.isAnimating) _spinnerController.stop();
    _spinnerController.dispose();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  /// Show Forgot Password Dialog
  void _showForgotPasswordDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ForgotPassword',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final viewInsets = MediaQuery.of(context).viewInsets;
          return Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                child: Container(color: Colors.black26),
              ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(20, 0, 20, viewInsets.bottom),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Forgot Password",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                                    Text("Email cannot be empty"),
                                  ));
                                  return;
                                }
                                setDialogState(
                                        () => _isResetLoading = true);
                                try {
                                  String result = await AuthService()
                                      .resetPassword(
                                      _resetEmailController.text);

                                  if (result.contains("Mail Sent")) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          "Password reset link sent to your email"),
                                      backgroundColor: Colors.green,
                                    ));
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                      Text(result.toString()),
                                      backgroundColor: Colors.redAccent,
                                    ));
                                  }
                                } finally {
                                  setDialogState(
                                          () => _isResetLoading = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
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
              ),
            ],
          );
        });
      },
    );
  }

  /// Handle Email/Password login
  void _handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      String result = await AuthService().loginWithEmail(
        _emailOrPhoneController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result == "Login Successful") {
        userProvider.loadUserData();
        await storage.write(key: "logged_in", value: "true");

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Login Successful"),
          backgroundColor: Colors.green,
        ));

        Navigator.restorablePushNamedAndRemoveUntil(
            context, "/home", (_) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result),
          backgroundColor: Colors.red.shade400,
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Handle Google login
  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      String result = await AuthService().signInWithGoogle();
      if (result == "Login Successful") {
        await storage.write(key: "logged_in", value: "true");
        Provider.of<UserProvider>(context, listen: false).loadUserData();
        Navigator.restorablePushNamedAndRemoveUntil(
            context, "/home", (_) => false);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final logoPath = brightness == Brightness.dark
        ? 'assets/images/logo_dark.png'
        : 'assets/images/logo.png';
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  Center(child: Image.asset(logoPath, width: 120, height: 120)),
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Login to continue",
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                  const SizedBox(height: 30),

                  // Email/Phone
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: TextFormField(
                      controller: _emailOrPhoneController,
                      validator: (value) => value!.isEmpty
                          ? "Email or Mobile Number cannot be empty."
                          : null,
                      decoration: InputDecoration(
                        labelText: "Email or Mobile Number",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      validator: (value) => value!.length < 8
                          ? "Password should have at least 8 characters."
                          : null,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text("Forgot Password?"),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Button
                  SizedBox(
                    height: 55,
                    width: screenWidth * 0.88,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isLoading
                            ? RotationTransition(
                          turns: _spinnerController,
                          child: const Icon(Icons.autorenew,
                              color: Colors.white),
                        )
                            : const Text("Login",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // OR Divider
                  const Row(
                    children: [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("OR", style: TextStyle(fontSize: 12)),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Google Login
                  SizedBox(
                    height: 55,
                    width: screenWidth * 0.88,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        side: BorderSide(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                        ),

                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Image.asset('assets/images/google_logo.png',
                          height: 22, width: 22),
                      label: const Text("Continue with Google",
                          style: TextStyle(fontSize: 16)),
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushNamed(context, "/signup"),
                        child: const Text("Sign Up"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Loading overlay
          IgnorePointer(
            ignoring: !_isLoading,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isLoading ? 0.45 : 0.0,
              child: Container(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
