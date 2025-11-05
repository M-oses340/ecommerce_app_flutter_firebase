import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/contants/discount.dart';
import 'package:ecommerce_app/models/cart_model.dart';
import 'package:ecommerce_app/models/products_model.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewProduct extends StatefulWidget {
  const ViewProduct({super.key});

  @override
  State<ViewProduct> createState() => _ViewProductState();
}

class _ViewProductState extends State<ViewProduct> {
  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as ProductsModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🦋 Hero animation with CachedNetworkImage
            Hero(
              tag: product.id,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6,
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.image.isNotEmpty
                        ? product.image
                        : 'https://via.placeholder.com/400x300?text=No+Image',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                      size: 100,
                    ),
                  ),
                ),
              ),
            ),

            // 🛒 Product Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        "KSh${product.old_price}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "KSh${product.new_price}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_downward,
                          color: Colors.green, size: 18),
                      Text(
                        "${discountPercent(product.old_price, product.new_price)}%",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.maxQuantity == 0
                        ? "Out of Stock"
                        : "Only ${product.maxQuantity} left in stock",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: product.maxQuantity == 0
                          ? Colors.red
                          : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 🧾 Bottom Buttons
      bottomNavigationBar: product.maxQuantity != 0
          ? Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false)
                      .addToCart(
                    CartModel(productId: product.id, quantity: 1),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Added to cart")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text("Add to Cart"),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  final cartProvider =
                  Provider.of<CartProvider>(context, listen: false);
                  cartProvider.addToCart(
                    CartModel(productId: product.id, quantity: 1),
                  );

                  final result =
                  await Navigator.pushNamed(context, "/checkout");

                  if (!mounted) return;
                  if (result == true) {
                    cartProvider.clearCart();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade600,
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text("Buy Now"),
              ),
            ),
          ),
        ],
      )
          : const SizedBox(),
    );
  }
}
