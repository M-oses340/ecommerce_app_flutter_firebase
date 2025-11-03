import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecommerce_app/containers/category_container.dart';
import 'package:ecommerce_app/containers/discount_container.dart';
import 'package:ecommerce_app/containers/home_page_maker_container.dart';
import 'package:ecommerce_app/containers/promo_container.dart';

/// 🏠 Home Page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  String _searchQuery = "";
  bool _isOnline = true;
  bool _isLoading = true;
  bool _showNoInternetBanner = false;
  bool _showBackOnlineBanner = false;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  final GlobalKey<RefreshIndicatorState> _refreshKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    // Slide for "No Internet"
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));

    // Pulse for "No Internet"
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade for "Back Online"
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _initConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      _showNoInternetBanner = !_isOnline;
      _isLoading = false;
    });

    if (_showNoInternetBanner) {
      _slideController.forward();
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) async {
    final wasOnline = _isOnline;
    setState(() {
      _isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;
    });

    if (!wasOnline && !_isOnline) {
      // 📴 Lost Internet
      setState(() {
        _showNoInternetBanner = true;
        _showBackOnlineBanner = false;
      });
      _slideController.forward();
      _pulseController.forward().then((_) => _pulseController.reverse());
    }

    if (!wasOnline && _isOnline) {
      // ✅ Back Online
      setState(() {
        _showNoInternetBanner = false;
        _showBackOnlineBanner = true;
      });
      _slideController.reverse();
      _fadeController.forward();

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        _fadeController.reverse();
        setState(() => _showBackOnlineBanner = false);
      }

      await _autoRefreshData();
    }
  }

  Future<void> _autoRefreshData() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {});
    } catch (e) {
      debugPrint("Auto refresh failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _slideController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic, color: Colors.grey),
                    onPressed: () {},
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          /// 🌐 Main Content
          SafeArea(
            child: RefreshIndicator(
              key: _refreshKey,
              onRefresh: _autoRefreshData,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: PromoContainer(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: DiscountContainer(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: CategoryContainer(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: HomePageMakerContainer(searchQuery: _searchQuery),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 🔴 No Internet Banner (Slide + Pulse)
          SafeArea(
            bottom: false,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: _showNoInternetBanner
                    ? Material(
                  color: Colors.red.shade400,
                  child: InkWell(
                    onTap: _autoRefreshData,
                    splashColor: Colors.white.withOpacity(0.2),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.wifi_off, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "No Internet Connection",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 15),
                          Icon(Icons.refresh,
                              color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            "Tap to Retry",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          /// 🟢 Back Online Banner (Fade)
          if (_showBackOnlineBanner)
            SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  height: 50,
                  color: Colors.green.shade600,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Back Online",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
