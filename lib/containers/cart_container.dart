import 'package:ecommerce_app/contants/discount.dart';
import 'package:ecommerce_app/models/cart_model.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartContainer extends StatefulWidget {
  final String image, name, productId;
  final int new_price, old_price, maxQuantity, selectedQuantity;

  const CartContainer({
    super.key,
    required this.image,
    required this.name,
    required this.productId,
    required this.new_price,
    required this.old_price,
    required this.maxQuantity,
    required this.selectedQuantity,
  });

  @override
  State<CartContainer> createState() => _CartContainerState();
}

class _CartContainerState extends State<CartContainer> {
  int count = 1;

  @override
  void initState() {
    count = widget.selectedQuantity;
    super.initState();
  }

  // ✅ Increase quantity
  increaseCount(int max) async {
    if (count >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum quantity reached")),
      );
      return;
    } else {
      Provider.of<CartProvider>(context, listen: false).addToCart(
        CartModel(productId: widget.productId, quantity: count),
      );
      setState(() {
        count++;
      });
    }
  }

  // ✅ Decrease quantity
  decreaseCount() async {
    if (count > 1) {
      Provider.of<CartProvider>(context, listen: false)
          .decreaseCount(widget.productId);
      setState(() {
        count--;
      });
    }
  }

  // ✅ Confirm remove dialog
  Future<void> _confirmRemove(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Item"),
        content: Text(
          "Are you sure you want to remove '${widget.name}' from your cart?",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false)
                  .deleteItem(widget.productId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("'${widget.name}' removed from cart"),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // 🛒 Product row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Image.network(widget.image, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                // 🏷️ Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            "KSh${widget.old_price}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "KSh${widget.new_price}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_downward,
                              color: Colors.green, size: 20),
                          Text(
                            "${discountPercent(widget.old_price, widget.new_price)}%",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 🗑️ Delete icon with confirmation
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  onPressed: () => _confirmRemove(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🔢 Quantity controls
            Row(
              children: [
                const Text(
                  "Quantity:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                _buildQuantityButton(Icons.add, () {
                  increaseCount(widget.maxQuantity);
                }),
                const SizedBox(width: 8),
                Text(
                  "$count",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                _buildQuantityButton(Icons.remove, () {
                  decreaseCount();
                }),
                const Spacer(),
                const Text("Total:"),
                const SizedBox(width: 8),
                Text(
                  "KSh${widget.new_price * count}",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build rounded quantity buttons
  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade300,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}
