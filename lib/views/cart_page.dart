import 'package:ecommerce_app/containers/cart_container.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keeps scroll and UI state alive

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required when using keep-alive mixin

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Cart",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
      ),

      // Main Cart Body
      body: Consumer<CartProvider>(
        builder: (context, value, child) {
          if (value.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (value.carts.isEmpty || value.products.isEmpty) {
            return const Center(child: Text("No items in cart"));
          }

          // ✅ Uses your existing refreshCart() method
          return RefreshIndicator(
            onRefresh: () async => await value.refreshCart(),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: value.carts.length,
              itemBuilder: (context, index) {
                final product = value.products[index];
                final cartItem = value.carts[index];

                return CartContainer(
                  image: product.image,
                  name: product.name,
                  new_price: product.new_price,
                  old_price: product.old_price,
                  maxQuantity: product.maxQuantity,
                  selectedQuantity: cartItem.quantity,
                  productId: product.id,
                );
              },
            ),
          );
        },
      ),

      // Bottom Cart Summary
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, value, child) {
          if (value.carts.isEmpty) {
            return const SizedBox();
          }

          // ✅ Convert int → double to match CartSummaryBar
          return CartSummaryBar(totalCost: value.totalCost.toDouble());
        },
      ),
    );
  }
}

// ✅ Clean, reusable bottom summary bar widget
class CartSummaryBar extends StatelessWidget {
  final double totalCost;
  const CartSummaryBar({super.key, required this.totalCost});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Total : ₹${totalCost.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, "/checkout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Proceed to Checkout"),
          ),
        ],
      ),
    );
  }
}
