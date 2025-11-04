import 'dart:async';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:ecommerce_app/models/promo_banners_model.dart';
import 'package:flutter/material.dart';

class PromoContainer extends StatefulWidget {
  const PromoContainer({super.key});

  @override
  State<PromoContainer> createState() => _PromoContainerState();
}

class _PromoContainerState extends State<PromoContainer> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;
  Color _currentBadgeColor = Colors.orange;

  final List<PromoBannersModel> dummyPromos = [
    PromoBannersModel(
      id: "1",
      title: "Phones & Accessories Sale",
      image:
      "https://images.pexels.com/photos/404280/pexels-photo-404280.jpeg?auto=compress&cs=tinysrgb&w=1200",
      category: "Phones",
    ),
    PromoBannersModel(
      id: "2",
      title: "Fashion Week - 50% OFF",
      image:
      "https://images.pexels.com/photos/2983464/pexels-photo-2983464.jpeg?auto=compress&cs=tinysrgb&w=1200",
      category: "Fashion",
    ),
    PromoBannersModel(
      id: "3",
      title: "Supermarket Deals",
      image:
      "https://images.pexels.com/photos/5632401/pexels-photo-5632401.jpeg?auto=compress&cs=tinysrgb&w=1200",
      category: "Groceries",
    ),
    PromoBannersModel(
      id: "4",
      title: "Home & Living Essentials",
      image:
      "https://images.pexels.com/photos/271816/pexels-photo-271816.jpeg?auto=compress&cs=tinysrgb&w=1200",
      category: "Home & Living",
    ),
    PromoBannersModel(
      id: "5",
      title: "Laptop & Tech Mega Sale",
      image:
      "https://images.pexels.com/photos/18105/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=1200",
      category: "Electronics",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentBadgeColor = _getCategoryColor(dummyPromos.first.category);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageController.hasClients) {
        final nextPage = (_currentIndex + 1) % dummyPromos.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case "fashion":
        return Colors.pinkAccent.shade400;
      case "phones":
        return Colors.blueAccent.shade400;
      case "groceries":
        return Colors.green.shade600;
      case "electronics":
        return Colors.deepPurple.shade400;
      case "home & living":
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double bannerHeight = MediaQuery.of(context).size.width * 0.58;

    return StreamBuilder(
      stream: DbService().readPromos(),
      builder: (context, snapshot) {
        List<PromoBannersModel> promos = [];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          promos = PromoBannersModel.fromJsonList(snapshot.data!.docs);
        } else {
          promos = dummyPromos;
        }

        if (promos.isEmpty) return const SizedBox();

        return Column(
          children: [
            SizedBox(
              height: bannerHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: promos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _currentBadgeColor =
                        _getCategoryColor(promos[index].category);
                  });
                  _startAutoSlide();
                },
                itemBuilder: (context, index) {
                  final promo = promos[index];
                  final isActive = index == _currentIndex;

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: isActive ? 1.0 : 0.7,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      margin: EdgeInsets.symmetric(
                        horizontal: isActive ? 0 : 6,
                        vertical: isActive ? 0 : 10,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.grey.shade200,
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "/specific",
                            arguments: {"name": promo.category},
                          );
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 📸 Banner image
                            Image.network(
                              promo.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: Colors.grey.shade300),
                            ),
                            // 🌈 Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.center,
                                  colors: [
                                    Colors.black.withOpacity(0.65),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // 🟨 Animated category badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentBadgeColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  promo.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            // 🏷️ Title & CTA
                            Positioned(
                              left: 16,
                              bottom: 20,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promo.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // 🛒 Shop Now button
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 500),
                                    opacity: isActive ? 1.0 : 0.0,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black87,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(24),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          "/specific",
                                          arguments: {"name": promo.category},
                                        );
                                      },
                                      child: const Text(
                                        "Shop Now",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // ⚪ Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: promos.asMap().entries.map((entry) {
                final isActive = entry.key == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 8,
                  width: isActive ? 22 : 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
