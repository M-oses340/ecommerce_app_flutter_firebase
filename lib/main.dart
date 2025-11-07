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
import 'package:ecommerce_app/views/search_view.dart';
import 'package:ecommerce_app/views/signup.dart';
import 'package:ecommerce_app/views/specific_products.dart';
import 'package:ecommerce_app/views/update_profile.dart';
import 'package:ecommerce_app/views/view_product.dart';
import 'package:ecommerce_app/widgets/no_internet_overlay.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecommerce_app/providers/connectivity_provider.dart';
import 'models/orders_model.dart';
import 'models/products_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _monitorConnection();
  }

  void _monitorConnection() {
    _connectivity.onConnectivityChanged.listen((results) {
      // You can update a global provider if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MaterialApp(
        title: 'eCommerce App',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const SplashTransition(),

        // ✅ Fixed routes
        routes: {
          "/login": (context) => const LoginPage(),
          "/home": (context) => const HomeNav(),
          "/signup": (context) => const SignupPage(),
          "/update_profile": (context) => const UpdateProfile(),
          "/discount": (context) => const DiscountPage(),
          "/specific": (context) => const SpecificProducts(),
          "/cart": (context) => const CartPage(),
          "/checkout": (context) => const CheckoutPage(),
          '/search': (_) => const SearchView(),
          "/orders": (context) => const OrdersPage(),
          "/view_order": (context) {
            final order =
                ModalRoute.of(context)!.settings.arguments as OrdersModel;
            return ViewOrder(order: order);
          },
        },

        // ✅ Properly handle view_product route with product argument
        onGenerateRoute: (settings) {
          if (settings.name == '/view_product') {
            final product = settings.arguments as ProductsModel;
            return MaterialPageRoute(
              builder: (_) => ViewProduct(product: product),
            );
          }
          return null;
        },
      ),
    );
  }
}

/// Splash screen
class SplashTransition extends StatefulWidget {
  const SplashTransition({super.key});

  @override
  State<SplashTransition> createState() => _SplashTransitionState();
}

class _SplashTransitionState extends State<SplashTransition>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _logoController;
  late AnimationController _spinnerController;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _bounceAnimation =
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _spinnerController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeController.forward();
    _logoController.forward();
    _spinnerController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const CheckUser(),
          transitionDuration: const Duration(milliseconds: 900),
          transitionsBuilder: (context, animation, _, child) {
            final fade =
                CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            final scale = Tween<double>(begin: 0.95, end: 1.0).animate(fade);
            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _logoController.dispose();
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final double logoSize = size.width * 0.35;

    final backgroundColor =
        isDark ? const Color(0xFF0A192F) : const Color(0xFF2196F3);
    final spinnerColor = isDark ? Colors.blueAccent.shade100 : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.white;
    final shimmerBase = isDark ? Colors.white54 : Colors.white70;
    final shimmerHighlight = isDark ? Colors.white : Colors.blue[50];
    final logoAsset =
        isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo.png';

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _bounceAnimation,
                child: Image.asset(
                  logoAsset,
                  width: logoSize.clamp(100, 180),
                  height: logoSize.clamp(100, 180),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Shimmer.fromColors(
              baseColor: shimmerBase!,
              highlightColor: shimmerHighlight!,
              child: Text(
                "eCommerce App",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _spinnerController,
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Check user login and biometric
class CheckUser extends StatefulWidget {
  const CheckUser({super.key});

  @override
  State<CheckUser> createState() => _CheckUserState();
}

class _CheckUserState extends State<CheckUser> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometricLogin();
  }

  Future<void> _checkBiometricLogin() async {
    await Future.delayed(const Duration(milliseconds: 400));

    final storedLogin = await storage.read(key: "logged_in");

    if (storedLogin == "true") {
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();

      if (canCheck && isSupported) {
        try {
          final authenticated = await auth.authenticate(
            localizedReason: "Use Fingerprint / Face ID to continue",
          );
          if (authenticated && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeNav()),
            );
            return;
          }
        } catch (_) {}
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
