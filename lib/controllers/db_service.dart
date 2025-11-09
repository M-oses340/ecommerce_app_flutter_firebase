import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/cart_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DbService {
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // ============================
  // 🔹 USER DATA
  // ============================

  Future<void> saveUserData({
    required String name,
    required String email,
    String? photoUrl, // added
  }) async {
    final userId = uid;
    if (userId == null) throw Exception("No user logged in");

    final data = {
      "name": name,
      "email": email,
      "address": "",
      "phone": "",
      "profileImage": photoUrl ?? "", // use Google photo if available
      "createdAt": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection("shop_users")
        .doc(userId)
        .set(data, SetOptions(merge: true)); // merge = safe for existing users
  }


  Future<void> updateUserData({required Map<String, dynamic> extraData}) async {
    final userId = uid;
    if (userId == null) throw Exception("No user logged in");

    await FirebaseFirestore.instance
        .collection("shop_users")
        .doc(userId)
        .update(extraData);
  }

  Stream<DocumentSnapshot> readUserData() {
    final userId = uid;
    if (userId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection("shop_users")
        .doc(userId)
        .snapshots();
  }

  Future<String> uploadProfileImage(File imageFile) async {
    final userId = uid;
    if (userId == null) throw Exception("No user logged in");

    final ref = FirebaseStorage.instance
        .ref()
        .child("profile_images")
        .child("$userId.jpg");

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // ============================
  // 🔹 CART
  // ============================

  Stream<QuerySnapshot> readUserCart() {
    final userId = uid;
    if (userId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection("shop_users")
        .doc(userId)
        .collection("cart")
        .snapshots();
  }

  Future<void> addToCart({required CartModel cartData}) async {
    final userId = uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("shop_users")
          .doc(userId)
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
            .doc(userId)
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
    final userId = uid;
    if (userId == null) return;
    await FirebaseFirestore.instance
        .collection("shop_users")
        .doc(userId)
        .collection("cart")
        .doc(productId)
        .delete();
  }

  Future<void> reduceQuantity({
    required String productId,
    required int quantity,
  }) async {
    final productRef =
    FirebaseFirestore.instance.collection("shop_products").doc(productId);
    final doc = await productRef.get();
    if (doc.exists) {
      int currentStock = doc["maxQuantity"] ?? 0;
      int newStock = currentStock - quantity;
      if (newStock < 0) newStock = 0;
      await productRef.update({"maxQuantity": newStock});
    }
  }

  Future<void> decreaseCount({required String productId}) async {
    final userId = uid;
    if (userId == null) return;
    await FirebaseFirestore.instance
        .collection("shop_users")
        .doc(userId)
        .collection("cart")
        .doc(productId)
        .update({"quantity": FieldValue.increment(-1)});
  }

  Future<void> emptyCart() async {
    final userId = uid;
    if (userId == null) return;
    final cartRef = FirebaseFirestore.instance
        .collection("shop_users")
        .doc(userId)
        .collection("cart");
    final snapshot = await cartRef.get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ============================
  // 🔹 ORDERS
  // ============================

  Stream<QuerySnapshot> readOrders() {
    final userId = uid;
    if (userId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection("shop_orders")
        .where("user_id", isEqualTo: userId)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  Future<DocumentReference> createOrder({
    required Map<String, dynamic> data,
  }) async {
    return await FirebaseFirestore.instance.collection("shop_orders").add(data);
  }

  Future<void> updateOrderStatus({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await FirebaseFirestore.instance
        .collection("shop_orders")
        .doc(docId)
        .update(data);
  }

  // ============================
  // 🔹 OTHER STREAMS
  // ============================

  Stream<QuerySnapshot> readPromos() =>
      FirebaseFirestore.instance.collection("shop_promos").snapshots();

  Stream<QuerySnapshot> readBanners() =>
      FirebaseFirestore.instance.collection("shop_banners").snapshots();

  Stream<QuerySnapshot> readDiscounts() => FirebaseFirestore.instance
      .collection("shop_coupons")
      .orderBy("discount", descending: true)
      .snapshots();

  Future<QuerySnapshot> verifyDiscount({required String code}) =>
      FirebaseFirestore.instance
          .collection("shop_coupons")
          .where("code", isEqualTo: code)
          .get();

  Stream<QuerySnapshot> readCategories() => FirebaseFirestore.instance
      .collection("shop_categories")
      .orderBy("priority", descending: true)
      .snapshots();

  Stream<QuerySnapshot> readProducts(String category) => FirebaseFirestore
      .instance
      .collection("shop_products")
      .where("category", isEqualTo: category.toLowerCase())
      .snapshots();

  Stream<QuerySnapshot> searchProducts(List<String> docIds) =>
      FirebaseFirestore.instance
          .collection("shop_products")
          .where(FieldPath.documentId, whereIn: docIds)
          .snapshots();

  Stream<List<Map<String, dynamic>>> searchByKeyword(String query) async* {
    print("🟢 [DbService] Listening for search: '$query'");

    final collection = FirebaseFirestore.instance.collection("shop_products");

    await for (final snapshot in collection.snapshots()) {
      // ✅ Include document ID inside each map
      final allProducts = snapshot.docs
          .map((doc) => {
        "id": doc.id,
        ...doc.data(),
      })
          .toList();

      if (query.isEmpty) {
        print("📡 [DbService] Returning all ${allProducts.length} products (empty query)");
        yield allProducts;
      } else {
        final q = query.toLowerCase();
        final filtered = allProducts.where((p) {
          final name = (p["name"] ?? "").toString().toLowerCase();
          final category = (p["category"] ?? "").toString().toLowerCase();
          final desc = (p["desc"] ?? "").toString().toLowerCase();
          return name.contains(q) || category.contains(q) || desc.contains(q);
        }).toList();

        print("📡 [DbService] Found ${filtered.length} matches for '$query'");
        yield filtered;
      }
    }
  }
  // ============================
  // 🔹 WALLET
  // ============================

  /// Stream the current wallet balance in real-time
  Stream<DocumentSnapshot> walletStream() {
    final userId = uid;
    if (userId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection("wallets")
        .doc(userId)
        .snapshots();
  }

  /// Create or update wallet document
  Future<void> updateWalletBalance(double newBalance) async {
    final userId = uid;
    if (userId == null) throw Exception("No user logged in");

    final walletRef =
    FirebaseFirestore.instance.collection("wallets").doc(userId);

    await walletRef.set({
      "balance": newBalance,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Add a transaction record
  Future<void> addWalletTransaction({
    required String type, // deposit, purchase, etc.
    required double amount,
    required String description,
  }) async {
    final userId = uid;
    if (userId == null) throw Exception("No user logged in");

    final txRef = FirebaseFirestore.instance
        .collection("wallets")
        .doc(userId)
        .collection("transactions")
        .doc();

    await txRef.set({
      "type": type,
      "amount": amount,
      "description": description,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// Fetch current balance
  Future<double> getCurrentBalance() async {
    final userId = uid;
    if (userId == null) return 0.0;

    final doc = await FirebaseFirestore.instance
        .collection("wallets")
        .doc(userId)
        .get();

    return (doc.data()?["balance"] ?? 0).toDouble();
  }


}
