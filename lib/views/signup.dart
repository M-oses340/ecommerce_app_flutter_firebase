import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/controllers/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Fade-in animation states
  double _headerOpacity = 0.0;
  double _nameOpacity = 0.0;
  double _emailOpacity = 0.0;
  double _passwordOpacity = 0.0;
  double _confirmOpacity = 0.0;
  double _buttonOpacity = 0.0;

  // Shake controllers
  late AnimationController _shakeController;
  late Animation<double> _nameShake;
  late Animation<double> _emailShake;
  late Animation<double> _passwordShake;
  late Animation<double> _confirmShake;

  // Button width animation
  late AnimationController _buttonController;
  late Animation<double> _buttonWidthAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _buttonWidthAnimation = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOutCubic),
    );

    final shakeTween = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 10.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 10.0, end: -10.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -10.0, end: 6.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 6.0, end: -4.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -4.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ]);

    _nameShake = shakeTween.animate(_shakeController);
    _emailShake = shakeTween.animate(_shakeController);
    _passwordShake = shakeTween.animate(_shakeController);
    _confirmShake = shakeTween.animate(_shakeController);

    // Sequential fade-in animations
    Future.delayed(const Duration(milliseconds: 200), () => setState(() => _headerOpacity = 1.0));
    Future.delayed(const Duration(milliseconds: 400), () => setState(() => _nameOpacity = 1.0));
    Future.delayed(const Duration(milliseconds: 600), () => setState(() => _emailOpacity = 1.0));
    Future.delayed(const Duration(milliseconds: 800), () => setState(() => _passwordOpacity = 1.0));
    Future.delayed(const Duration(milliseconds: 1000), () => setState(() => _confirmOpacity = 1.0));
    Future.delayed(const Duration(milliseconds: 1200), () => setState(() => _buttonOpacity = 1.0));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _buttonController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _triggerShake(String field) {
    _shakeController.forward(from: 0);
  }

  Widget _animatedField({
    required double opacity,
    required Widget child,
    Animation<double>? shake,
    FocusNode? focusNode,
    double offset = 30,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, translateY, _) {
        return AnimatedBuilder(
          animation: shake ?? const AlwaysStoppedAnimation(0),
          builder: (context, childWidget) {
            return Transform.translate(
              offset: Offset(shake?.value ?? 0, translateY),
              child: AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 500),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: focusNode?.hasFocus == true
                        ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),

                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ]
                        : [],
                  ),
                  child: childWidget,
                ),
              ),
            );
          },
          child: child,
        );
      },
    );
  }

  Future<void> _handleSignup(BuildContext context, double screenWidth) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      if (_nameController.text.isEmpty) {
        _triggerShake('name');
      }
      if (_emailController.text.isEmpty) {
        _triggerShake('email');
      }
      if (_passwordController.text.length < 8) {
        _triggerShake('password');
      }
      if (_confirmPasswordController.text != _passwordController.text ||
          _confirmPasswordController.text.isEmpty) {
        _triggerShake('confirm');
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _buttonController.forward();

    final result = await AuthService().createAccountWithEmail(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    // Safe context re-check
    if (!mounted) return;

    await _buttonController.reverse();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // ✅ No more direct context after async calls
    if (result == "Account Created") {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Account Created")),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      navigator.restorablePushNamedAndRemoveUntil("/home", (route) => false);
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(result, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardHeight + 20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: AbsorbPointer(
                    absorbing: _isLoading,
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          _animatedField(
                            opacity: _headerOpacity,
                            offset: 50,
                            child: const Column(
                              children: [
                                Text(
                                  "Sign Up",
                                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 10),
                                Text("Create a new account and get started"),
                                SizedBox(height: 30),
                              ],
                            ),
                          ),

                          // Name Field
                          _animatedField(
                            opacity: _nameOpacity,
                            shake: _nameShake,
                            focusNode: _nameFocus,
                            child: SizedBox(
                              width: screenWidth * 0.9,
                              child: TextFormField(
                                focusNode: _nameFocus,
                                controller: _nameController,
                                validator: (value) => value!.isEmpty ? "Name cannot be empty." : null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: "Name",
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Email Field
                          _animatedField(
                            opacity: _emailOpacity,
                            shake: _emailShake,
                            focusNode: _emailFocus,
                            child: SizedBox(
                              width: screenWidth * 0.9,
                              child: TextFormField(
                                focusNode: _emailFocus,
                                controller: _emailController,
                                validator: (value) =>
                                value!.isEmpty ? "Email cannot be empty." : null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: "Email",
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Password Field
                          _animatedField(
                            opacity: _passwordOpacity,
                            shake: _passwordShake,
                            focusNode: _passwordFocus,
                            child: SizedBox(
                              width: screenWidth * 0.9,
                              child: TextFormField(
                                focusNode: _passwordFocus,
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: (value) => value!.length < 8
                                    ? "Password should have at least 8 characters."
                                    : null,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: "Password",
                                  filled: true,
                                  fillColor: Colors.white,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _obscurePassword ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Confirm Password Field
                          _animatedField(
                            opacity: _confirmOpacity,
                            shake: _confirmShake,
                            focusNode: _confirmFocus,
                            child: SizedBox(
                              width: screenWidth * 0.9,
                              child: TextFormField(
                                focusNode: _confirmFocus,
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                validator: (value) {
                                  if (value!.isEmpty) return "Please confirm your password.";
                                  if (value != _passwordController.text) return "Passwords do not match.";
                                  return null;
                                },
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: "Confirm Password",
                                  filled: true,
                                  fillColor: Colors.white,
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => setState(
                                            () => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Sign Up Button
                          _animatedField(
                            opacity: _buttonOpacity,
                            child: AnimatedBuilder(
                              animation: _buttonController,
                              builder: (context, child) {
                                final width = screenWidth * _buttonWidthAnimation.value;
                                final scale = 1.0 - 0.05 * _buttonWidthAnimation.value;
                                return Transform.scale(
                                  scale: scale,
                                  child: SizedBox(
                                    height: 60,
                                    width: width,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _handleSignup(context, screenWidth),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 3),
                                      )
                                          : const Text("Sign Up", style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account?"),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Login"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _isLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),

                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
