import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:ecommerce_app/models/categories_model.dart';
import 'package:ecommerce_app/models/promo_banners_model.dart';
import 'package:ecommerce_app/models/products_model.dart';
import 'package:ecommerce_app/containers/banner_container.dart';
import 'package:ecommerce_app/containers/zone_container.dart';

class HomePageMakerContainer extends StatefulWidget {
  final String searchQuery; // 🔍 search text (optional)

  const HomePageMakerContainer({
    super.key,
    this.searchQuery = "",
  });

  @override
  State<HomePageMakerContainer> createState() => _HomePageMakerContainerState();
}

class _HomePageMakerContainerState extends State<HomePageMakerContainer> {
  final DbService _db = DbService();
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  int _minLength(int a, int b) => a > b ? b : a;

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
    final connected = results.any((r) =>
    r == ConnectivityResult.mobile || r == ConnectivityResult.wifi);
    setState(() => _isConnected = connected);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return _noInternetPlaceholder();
    }

    // 👇 If user is searching, show search results
    if (widget.searchQuery.isNotEmpty) {
      return _buildSearchResults(widget.searchQuery);
    }

    // 👇 Otherwise show normal homepage (categories + banners + products)
    return StreamBuilder(
      stream: _db.readCategories(),
      builder: (context, categorySnapshot) {
        if (categorySnapshot.connectionState == ConnectionState.waiting) {
          return _loadingShimmer();
        }

        if (!categorySnapshot.hasData || categorySnapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final categories =
        CategoriesModel.fromJsonList(categorySnapshot.data!.docs);

        return StreamBuilder(
          stream: _db.readBanners(),
          builder: (context, bannerSnapshot) {
            if (!bannerSnapshot.hasData || bannerSnapshot.data!.docs.isEmpty) {
              return const SizedBox();
            }

            final banners =
            PromoBannersModel.fromJsonList(bannerSnapshot.data!.docs);
            final total = _minLength(categories.length, banners.length);

            return Column(
              children: List.generate(total, (i) {
                final category = categories[i];
                final banner = banners[i];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ZoneContainer(category: category.name),
                    BannerContainer(
                      image: banner.image,
                      category: banner.category,
                    ),
                    _buildProductsCarousel(category.name),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            );
          },
        );
      },
    );
  }

  /// 🔍 Builds the Firestore search result grid
  Widget _buildSearchResults(String query) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("shop_products")
          .where("keywords", arrayContains: query.toLowerCase())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingShimmer(height: 200);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "No products found 🛍️",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }

        final results = ProductsModel.fromJsonList(snapshot.data!.docs);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return _ProductCard(product: results[index]);
          },
        );
      },
    );
  }

  /// 🛍️ Builds horizontal product list per category
  Widget _buildProductsCarousel(String categoryName) {
    return StreamBuilder(
      stream: _db.readProducts(categoryName),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return _loadingShimmer(height: 160);
        }

        if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final products =
        ProductsModel.fromJsonList(productSnapshot.data!.docs);

        return SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductCard(product: product);
            },
          ),
        );
      },
    );
  }

  /// 💡 Shimmer loader for loading states
  Widget _loadingShimmer({double height = 400}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }

  /// 🚫 No Internet Placeholder
  Widget _noInternetPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.redAccent, size: 60),
          const SizedBox(height: 12),
          const Text(
            "No Internet Connection",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _checkConnection,
            icon: const Icon(Icons.refresh, color: Colors.blue),
            label: const Text(
              "Retry",
              style: TextStyle(color: Colors.blue),
            ),
          )
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductsModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          "/view_product",
          arguments: product,
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
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
                child: Image.network(
                  product.image,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Ksh ${product.new_price}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
