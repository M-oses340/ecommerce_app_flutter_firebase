import 'dart:async';
import 'package:ecommerce_app/controllers/auth_service.dart';
import 'package:ecommerce_app/firebase_options.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/providers/user_provider.dart';
import 'package:ecommerce_app/views/cart_page.dart';
import 'package:ecommerce_app/views/checkout_page.dart';
import 'package:ecommerce_app/views/discount_page.dart';
import 'package:ecommerce_app/views/home_nav.dart';
import 'package:ecommerce_app/views/login.dart';
import 'package:ecommerce_app/views/orders_page.dart';
import 'package:ecommerce_app/views/signup.dart';
import 'package:ecommerce_app/views/specific_products.dart';
import 'package:ecommerce_app/views/update_profile.dart';
import 'package:ecommerce_app/views/view_product.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  final publishableKey = dotenv.env["STRIPE_PUBLISH_KEY"];
  if (publishableKey == null || publishableKey.isEmpty) {
    debugPrint("⚠️ STRIPE_PUBLISH_KEY not found in .env file!");
  } else {
    Stripe.publishableKey = publishableKey;
    Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
    Stripe.urlScheme = 'flutterstripe';
    await Stripe.instance.applySettings();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'eCommerce App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashTransition(),
        routes: {
          "/login": (context) => const LoginPage(),
          "/home": (context) => const HomeNav(),
          "/signup": (context) => const SignupPage(),
          "/update_profile": (context) => const UpdateProfile(),
          "/discount": (context) => const DiscountPage(),
          "/specific": (context) => const SpecificProducts(),
          "/view_product": (context) => const ViewProduct(),
          "/cart": (context) => const CartPage(),
          "/checkout": (context) => const CheckoutPage(),
          "/orders": (context) => const OrdersPage(),
        },
      ),
    );
  }
}

/// 🩵 Animated Splash → Automatically goes to CheckUser
class SplashTransition extends StatefulWidget {
  const SplashTransition({super.key});

  @override
  State<SplashTransition> createState() => _SplashTransitionState();
}

class _SplashTransitionState extends State<SplashTransition>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _spinnerController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _spinnerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceAnimation =
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);

    _fadeController.forward();
    _scaleController.forward();
    _spinnerController.forward();

    // Spinner fades out before navigation
    Future.delayed(const Duration(milliseconds: 1600), () {
      _spinnerController.reverse();
    });

    // Navigate to CheckUser after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const CheckUser(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final double logoSize = size.width * 0.35;

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        color: isDarkMode
            ? const Color(0xFF0A192F)
            : const Color(0xFF2196F3),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _bounceAnimation,
              child: Image.asset(
                isDarkMode
                    ? 'assets/images/logo_dark.png'
                    : 'assets/images/logo.png',
                width: logoSize.clamp(100, 180),
                height: logoSize.clamp(100, 180),
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _spinnerController,
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.lightBlueAccent : Colors.white,
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

/// ✅ Checks if user is logged in, then navigates accordingly
class CheckUser extends StatefulWidget {
  const CheckUser({super.key});

  @override
  State<CheckUser> createState() => _CheckUserState();
}

class _CheckUserState extends State<CheckUser> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService().isLoggedIn();
    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        Navigator.pushReplacementNamed(context, "/login");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
