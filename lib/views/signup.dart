import 'dart:async';
import 'package:ecommerce_app/controllers/auth_service.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with TickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _slideAnimations = List.generate(
      4,
          (i) => Tween<Offset>(
        begin: const Offset(0, -0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.1, 1.0, curve: Curves.easeOut),
        ),
      ),
    );

    _fadeAnimations = List.generate(
      4,
          (i) => CurvedAnimation(
        parent: _controller,
        curve: Interval(i * 0.1, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 200));

    final result = await AuthService().createAccountWithEmail(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == "Account Created") {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Account Created Successfully")),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pushReplacementNamed(context, "/home");
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffix}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      prefixIcon: Icon(icon, color: colorScheme.primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  Widget _animatedField({
    required int index,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    required String? Function(String?) validator,
  }) {
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _fadeAnimations[index],
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              enabled: !_isLoading,
              controller: controller,
              obscureText: obscure,
              validator: validator,
              decoration: _inputDecoration(label, icon, suffix: suffix),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final blurColor = (isDark ? Colors.black : Colors.white).withOpacity(0.6);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Create Account",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _animatedField(
                        index: 0,
                        controller: _nameController,
                        label: "Full Name",
                        icon: Icons.person_outline,
                        validator: (value) =>
                        value == null || value.isEmpty ? "Enter your name" : null,
                      ),

                      _animatedField(
                        index: 1,
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter your email";
                          }
                          if (!value.contains("@")) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),

                      _animatedField(
                        index: 2,
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter your password";
                          }
                          if (value.length < 8) {
                            return "Password must be at least 8 characters";
                          }
                          return null;
                        },
                      ),

                      _animatedField(
                        index: 3,
                        controller: _confirmPasswordController,
                        label: "Confirm Password",
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Re-enter password";
                          }
                          if (value != _passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text("Sign Up"),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed:
                        _isLoading ? null : () => Navigator.pushNamed(context, "/login"),
                        child: Text(
                          "Already have an account? Log in",
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Blurred loading overlay
              if (_isLoading)
                AnimatedOpacity(
                  opacity: _isLoading ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    color: blurColor,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
