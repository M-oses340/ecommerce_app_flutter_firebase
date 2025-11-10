import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/products_model.dart';
import 'package:ecommerce_app/views/view_product.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesPage extends StatefulWidget {
  final String categoryName;

  const CategoriesPage({super.key, required this.categoryName});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String searchQuery = "";
  late String currentCategory;
  final ScrollController _scrollController = ScrollController();

  // Values driven by scroll to animate the blur/tint
  double _blurSigma = 0.0;
  double _overlayOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    currentCategory = widget.categoryName;

    // Listen to scroll to control blur/tint on category bar
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;

    // Adjust these divisors to tune the speed/amount of blur & opacity
    final targetBlur = (offset / 40).clamp(0.0, 8.0);
    final targetOpacity = (offset / 160).clamp(0.0, 0.85);

    // Update state only when values meaningfully change to avoid rebuild noise
    if ((targetBlur - _blurSigma).abs() > 0.1 || (targetOpacity - _overlayOpacity).abs() > 0.02) {
      setState(() {
        _blurSigma = targetBlur;
        _overlayOpacity = targetOpacity;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔙 Back + Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: textColor,
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search in $currentCategory",
                        hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                        prefixIcon:
                        Icon(Icons.search, color: textColor.withOpacity(0.6)),
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => searchQuery = val.toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),

            // 🧭 Horizontal Categories Bar with translucent blur overlay
            // We use a Stack so we can place BackdropFilter + Animated overlay on top of the ListView
            SizedBox(
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The horizontal categories list (underneath)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('shop_categories')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text("Error loading categories"));
                      }
                      if (!snapshot.hasData) {
                        return _buildCategoryShimmer(isDark);
                      }

                      final categories = snapshot.data!.docs;

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final data =
                          categories[index].data() as Map<String, dynamic>;
                          final name = (data["name"] ?? "").toString();
                          final image = (data["image"] ?? "").toString();
                          final selected = name == currentCategory;

                          return GestureDetector(
                            onTap: () {
                              if (name != currentCategory) {
                                setState(() {
                                  currentCategory = name;
                                  searchQuery = "";
                                });
                              }
                            },
                            child: Container(
                              width: 90,
                              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? (isDark ? Colors.white12 : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? (isDark
                                      ? Colors.white70
                                      : Colors.black54)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                                boxShadow: [
                                  if (!isDark)
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: image.isNotEmpty
                                        ? Image.network(
                                      image,
                                      height: 45,
                                      width: 45,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_not_supported,
                                          size: 40),
                                    )
                                        : const Icon(Icons.image_not_supported,
                                        size: 40),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: textColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // The blur + tint overlay that animates with scroll
                  // Using BackdropFilter to blur underlying content, plus an AnimatedContainer for tint opacity
                  // We also make the overlay ignore pointer events so it doesn't interfere with category taps
                  IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _overlayOpacity,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _blurSigma,
                          sigmaY: _blurSigma,
                        ),
                        child: Container(
                          // Tint color slightly adapts to theme
                          color: isDark
                              ? Colors.black.withOpacity(0.12 * _overlayOpacity)
                              : Colors.white.withOpacity(0.6 * _overlayOpacity),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🛒 Product Grid (scrolls using _scrollController so we can detect offset)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('shop_products')
                    .where('category', isEqualTo: currentCategory)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading products"));
                  }
                  if (!snapshot.hasData) return _buildProductShimmer();

                  final allProducts =
                  ProductsModel.fromJsonList(snapshot.data!.docs);
                  final filtered = allProducts
                      .where((p) =>
                  p.name.toLowerCase().contains(searchQuery) ||
                      p.description.toLowerCase().contains(searchQuery))
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        "No products found in \"$currentCategory\"",
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController, // << important: we listen to this
                    padding: const EdgeInsets.all(10),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ProductCard(
                        product: product,
                        isDark: isDark,
                        index: index,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Category shimmer
  Widget _buildCategoryShimmer(bool isDark) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[500]! : Colors.grey[100]!,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Product shimmer
  Widget _buildProductShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ----------------- Animated ProductCard -----------------
class ProductCard extends StatefulWidget {
  final dynamic product;
  final bool isDark;
  final int index; // For staggered animation

  const ProductCard({super.key, required this.product, required this.isDark, required this.index});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Staggered delay
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ViewProduct(product: product),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!widget.isDark)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    product.image,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 40),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "KSh ${product.new_price}",
                        style: TextStyle(
                          color: Colors.greenAccent[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Was ${product.old_price}",
                        style: TextStyle(
                          color:
                          (widget.isDark ? Colors.white70 : Colors.black)
                              .withOpacity(0.6),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
