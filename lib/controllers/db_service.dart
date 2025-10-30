import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/cart_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DbService {
  final User? user = FirebaseAuth.instance.currentUser;

  // ============================
  // 🔹 USER DATA
  // ============================

  /// Save user data when a new account is created
  Future<void> saveUserData({
    required String name,
    required String email,
  }) async {
    try {
      final data = {
        "name": name,
        "email": email,
        "address": "",
        "phone": "",
      };
      await FirebaseFirestore.instance
          .collection("shop_users")
          .doc(user!.uid)
          .set(data);
    } catch (e) {
      print("⚠️ Error saving user data: $e");
    }
  }

  /// Update user data fields (name, phone, address, etc.)
  /// Update user data across all relevant documents
  Future<void> updateUserData({required Map<String, dynamic> extraData}) async {
    final uid = user!.uid;

    // 1️⃣ Update main profile
    try {
      await FirebaseFirestore.instance
          .collection("shop_users")
          .doc(uid)
          .update(extraData);
    } catch (e) {
      print("⚠️ Error updating main user profile: $e");
    }

    // 2️⃣ Update previous orders referencing this user
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection("shop_orders")
          .where("user_id", isEqualTo: uid)
          .get();

      for (var doc in ordersSnapshot.docs) {
        await doc.reference.update({
          "name": extraData["name"] ?? doc["name"],
          "email": extraData["email"] ?? doc["email"],
          "phone": extraData["phone"] ?? doc["phone"],
          "address": extraData["address"] ?? doc["address"],
        });
      }
    } catch (e) {
      print("⚠️ Error updating user info in orders: $e");
    }

    // 3️⃣ Optionally, update other collections (cart, reviews, etc.)
    // Example: update cart documents
    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection("shop_users")
          .doc(uid)
          .collection("cart")
          .get();

      for (var doc in cartSnapshot.docs) {
        await doc.reference.update({
          "user_name": extraData["name"] ?? "",
          "user_email": extraData["email"] ?? "",
        });
      }
    } catch (e) {
      print("⚠️ Error updating user info in cart: $e");
    }
  }


  /// Read user data in real time
  Stream<DocumentSnapshot> readUserData() {
    return FirebaseFirestore.instance
        .collection("shop_users")
        .doc(user!.uid)
        .snapshots();
  }

  // ============================
  // 🔹 PROMOS & BANNERS
  // ============================

  Stream<QuerySnapshot> readPromos() {
    return FirebaseFirestore.instance.collection("shop_promos").snapshots();
  }

  Stream<QuerySnapshot> readBanners() {
    return FirebaseFirestore.instance.collection("shop_banners").snapshots();
  }

  // ============================
  // 🔹 DISCOUNTS
  // ============================

  Stream<QuerySnapshot> readDiscounts() {
    return FirebaseFirestore.instance
        .collection("shop_coupons")
        .orderBy("discount", descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> verifyDiscount({required String code}) {
    return FirebaseFirestore.instance
        .collection("shop_coupons")
        .where("code", isEqualTo: code)
        .get();
  }

  // ============================
  // 🔹 CATEGORIES & PRODUCTS
  // ============================

  Stream<QuerySnapshot> readCategories() {
    return FirebaseFirestore.instance
        .collection("shop_categories")
        .orderBy("priority", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> readProducts(String category) {
    return FirebaseFirestore.instance
        .collection("shop_products")
        .where("category", isEqualTo: category.toLowerCase())
        .snapshots();
  }

  Stream<QuerySnapshot> searchProducts(List<String> docIds) {
    return FirebaseFirestore.instance
        .collection("shop_products")
        .where(FieldPath.documentId, whereIn: docIds)
        .snapshots();
  }

  Future<void> reduceQuantity({
    required String productId,
    required int quantity,
  }) async {
    await FirebaseFirestore.instance
        .collection("shop_products")
        .doc(productId)
        .update({"quantity": FieldValue.increment(-quantity)});
  }

  // ============================
  // 🔹 CART
  // ============================

  Stream<QuerySnapshot> readUserCart() {
    return FirebaseFirestore.instance
        .collection("shop_users")
        .doc(user!.uid)
        .collection("cart")
        .snapshots();
  }

  Future<void> addToCart({required CartModel cartData}) async {
    try {
      await FirebaseFirestore.instance
          .collection("shop_users")
          .doc(user!.uid)
          .collection("cart")
          .doc(cartData.productId)
          .update({
        "product_id": cartData.productId,
        "quantity": FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      if (e.code == "not-found") {
        await FirebaseFirestore.instance
            .collection("shop_users")
            .doc(user!.uid)
            .collection("cart")
            .doc(cartData.productId)
            .set({
          "product_id": cartData.productId,
          "quantity": 1,
        });
      }
    }
  }

  Future<void> deleteItemFromCart({required String productId}) async {
    await FirebaseFirestore.instance
        .collection("shop_users")
        .doc(user!.uid)
        .collection("cart")
        .doc(productId)
        .delete();
  }

  Future<void> emptyCart() async {
    final cartRef = FirebaseFirestore.instance
        .collection("shop_users")
        .doc(user!.uid)
        .collection("cart");

    final items = await cartRef.get();
    for (var doc in items.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> decreaseCount({required String productId}) async {
    await FirebaseFirestore.instance
        .collection("shop_users")
        .doc(user!.uid)
        .collection("cart")
        .doc(productId)
        .update({"quantity": FieldValue.increment(-1)});
  }

  // ============================
  // 🔹 ORDERS
  // ============================

  /// Create a new order
  Future<void> createOrder({required Map<String, dynamic> data}) async {
    await FirebaseFirestore.instance.collection("shop_orders").add(data);
  }

  /// Update order status (used by admin)
  Future<void> updateOrderStatus({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await FirebaseFirestore.instance
        .collection("shop_orders")
        .doc(docId)
        .update(data);
  }

  /// Read all orders for the logged-in user
  Stream<QuerySnapshot> readOrders() {
    return FirebaseFirestore.instance
        .collection("shop_orders")
        .where("user_id", isEqualTo: user!.uid)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  // ============================
  // 🔹 ADMIN HELPERS (OPTIONAL)
  // ============================

  /// Read all orders (for admin dashboard)
  Stream<QuerySnapshot> readAllOrders() {
    return FirebaseFirestore.instance
        .collection("shop_orders")
        .orderBy("created_at", descending: true)
        .snapshots();
  }
}
