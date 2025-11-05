import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:ecommerce_app/models/products_model.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomePageMakerContainer extends StatefulWidget {
  final String searchQuery;

  const HomePageMakerContainer({super.key, this.searchQuery = ""});

  @override
  State<HomePageMakerContainer> createState() => _HomePageMakerContainerState();
}

class _HomePageMakerContainerState extends State<HomePageMakerContainer> {
  final DbService _db = DbService();
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final connected = results.any((r) =>
      r == ConnectivityResult.mobile || r == ConnectivityResult.wifi);
      setState(() => _isConnected = connected);
    });
  }

  Future<void> _checkConnection() async {
    final results = await Connectivity().checkConnectivity();
    final connected = results.any(
            (r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi);
    setState(() => _isConnected = connected);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isConnected) return _noInternetWidget(theme, isDark);

    // 🔍 Show search results if user is searching
    if (widget.searchQuery.isNotEmpty) {
      return _buildSearchResults(widget.searchQuery, theme, isDark);
    }

    // 🛍️ Show all products (Firestore stream)
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("shop_products")
          .orderBy("created_at", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingShimmer(isDark);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No products available 🛒",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          );
        }

        final products = ProductsModel.fromJsonList(snapshot.data!.docs);

        return RefreshIndicator(
          onRefresh: _checkConnection,
          child: _buildProductGrid(products, theme, isDark),
        );
      },
    );
  }

  /// 🔍 Search results
  Widget _buildSearchResults(String query, ThemeData theme, bool isDark) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("shop_products")
          .where("keywords", arrayContains: query.toLowerCase())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingShimmer(isDark);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No products found 🛍️",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          );
        }

        final results = ProductsModel.fromJsonList(snapshot.data!.docs);

        return _buildProductGrid(results, theme, isDark);
      },
    );
  }

  /// 🧱 Build product grid
  Widget _buildProductGrid(
      List<ProductsModel> products, ThemeData theme, bool isDark) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600 ? 2 : 3;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _ProductCard(product: products[index], isDark: isDark);
      },
    );
  }

  /// ✨ Shimmer loader
  Widget _loadingShimmer(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  /// 🚫 No internet placeholder
  Widget _noInternetWidget(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text(
            "No Internet Connection",
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _checkConnection,
            icon: const Icon(Icons.refresh, color: Colors.blue),
            label: const Text("Retry", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

/// 🏷 Product Card
class _ProductCard extends StatelessWidget {
  final ProductsModel product;
  final bool isDark;

  const _ProductCard({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, "/view_product", arguments: product),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: "product_${product.id}",
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.image.isNotEmpty
                    ? Image.network(
                  product.image,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
                    : _placeholder(),
              ),
            ),

            // 🏷 Product name
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),

            // 💵 Product price
            Padding(
              padding:
              const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: Text(
                "Ksh ${product.new_price}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 130,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported_outlined, size: 40),
  );
}
