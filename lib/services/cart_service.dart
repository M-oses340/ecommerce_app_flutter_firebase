import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';

class CartService {
  final String userId;
  CartService({required this.userId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _cartRef =>
      _firestore.collection('users').doc(userId).collection('cart');

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    final existing = await _cartRef.where('product_id', isEqualTo: productId).get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final currentQty = doc['quantity'] ?? 1;
      await doc.reference.update({'quantity': currentQty + quantity});
    } else {
      final cartItem = CartModel(productId: productId, quantity: quantity);
      await _cartRef.add({
        'product_id': cartItem.productId,
        'quantity': cartItem.quantity,
      });
    }
  }
}
