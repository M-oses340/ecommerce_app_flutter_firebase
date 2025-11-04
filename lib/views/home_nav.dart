import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/providers/user_provider.dart';
import 'package:ecommerce_app/views/cart_page.dart';
import 'package:ecommerce_app/views/home.dart';
import 'package:ecommerce_app/views/orders_page.dart';
import 'package:ecommerce_app/views/profile.dart';
import 'package:ecommerce_app/views/categories_page.dart'; // ✅ Add this import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/connectivity_wrapper.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int selectedIndex = 0;

  // ✅ Now includes 5 pages: Home, Categories, Orders, Cart, Profile
  final List<Widget?> _pages = [const HomePage(), null, null, null, null];

  Widget _getPage(int index) {
    if (_pages[index] == null) {
      switch (index) {
        case 1:
          _pages[index] = const CategoriesPage(); // ✅ Added
          break;
        case 2:
          _pages[index] = const OrdersPage();
          break;
        case 3:
          _pages[index] = const CartPage();
          break;
        case 4:
          _pages[index] = const ProfilePage();
          break;
      }
    }
    return _pages[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: List.generate(5, (index) => _getPage(index)),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 8,
          currentIndex: selectedIndex,
          onTap: (value) => setState(() => selectedIndex = value),
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              label: 'Categories',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Consumer<CartProvider>(
                builder: (context, value, child) {
                  if (value.carts.isNotEmpty) {
                    return Badge(
                      label: Text(value.carts.length.toString()),
                      backgroundColor: Colors.green.shade400,
                      child: const Icon(Icons.shopping_cart_outlined),
                    );
                  }
                  return const Icon(Icons.shopping_cart_outlined);
                },
              ),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Consumer<UserProvider>(
                builder: (context, user, child) {
                  final isLoggedIn = user.isLoggedIn;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.account_circle_outlined),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: isLoggedIn
                              ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                            key: ValueKey('tick'),
                          )
                              : const SizedBox(key: ValueKey('empty')),
                        ),
                      ),
                    ],
                  );
                },
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

}
