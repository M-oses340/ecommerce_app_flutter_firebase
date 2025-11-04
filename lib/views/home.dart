import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/containers/category_container.dart';
import 'package:ecommerce_app/containers/discount_container.dart';
import 'package:ecommerce_app/containers/promo_container.dart';
import 'package:ecommerce_app/models/products_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

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

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
      setState(() {
        _showNoInternetBanner = true;
        _showBackOnlineBanner = false;
      });
      _slideController.forward();
      _pulseController.forward().then((_) => _pulseController.reverse());
    }

    if (!wasOnline && _isOnline) {
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
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search on ShopEasy...",
                  hintStyle: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                  prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.mic, color: theme.iconTheme.color),
                    onPressed: () {},
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              key: _refreshKey,
              onRefresh: _autoRefreshData,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: PromoContainer(), // your existing promo widget
                      ),
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
                      padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: CategoryContainer(),
                    ),
                  ),
                  SliverPadding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    sliver: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("products")
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SliverGrid(
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.58,
                            ),
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                              const ShimmerProductCard(),
                              childCount: 6,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: Text(
                                "No products found",
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                        }

                        final products = ProductsModel.fromJsonList(
                            snapshot.data!.docs)
                            .where((p) => _searchQuery.isEmpty
                            ? true
                            : p.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                            .toList();

                        return SliverGrid(
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.58,
                          ),
                          delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                ProductCard(product: products[index]),
                            childCount: products.length,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Connectivity Banners
          SafeArea(
            bottom: false,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: _showNoInternetBanner
                    ? Material(
                  color: theme.colorScheme.error,
                  child: InkWell(
                    onTap: _autoRefreshData,
                    splashColor:
                    Colors.white.withValues(alpha: 51.0),
                    highlightColor:
                    Colors.white.withValues(alpha: 25.0),
                    child: Container(
                      height: 60,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
          if (_showBackOnlineBanner)
            SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  height: 50,
                  color: Colors.green.shade600,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Back Online",
                        style: theme.textTheme.bodyMedium?.copyWith(
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

/// Jumia-style ProductCard
class ProductCard extends StatelessWidget {
  final ProductsModel product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final discount = product.old_price > 0
        ? ((product.old_price - product.new_price) / product.old_price * 100)
        .round()
        : 0;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, "/viewProduct", arguments: product);
      },
      child: Card(
        color: theme.cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: product.id,
                  child: ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                    child: CachedNetworkImage(
                      imageUrl: product.image.isNotEmpty
                          ? product.image
                          : 'https://via.placeholder.com/400x300?text=No+Image',
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: theme.dividerColor
                            .withValues(alpha: 0.3 * 255),
                        highlightColor: theme.dividerColor
                            .withValues(alpha: 0.1 * 255),
                        child: Container(height: 150, color: theme.cardColor),
                      ),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.error, size: 50),
                    ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.maxQuantity == 0
                          ? Colors.grey
                          : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.maxQuantity == 0
                          ? 'Out of Stock'
                          : '${product.maxQuantity} left',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  if (product.old_price > product.new_price)
                    Text(
                      'KSh ${product.old_price}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.hintColor,
                      ),
                    ),
                  if (product.old_price > product.new_price)
                    const SizedBox(width: 6),
                  Text(
                    'KSh ${product.new_price}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer ProductCard Placeholder
class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.dividerColor.withValues(alpha: 0.3 * 255),
      highlightColor: theme.dividerColor.withValues(alpha: 0.1 * 255),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(height: 250, color: theme.cardColor),
      ),
    );
  }
}
