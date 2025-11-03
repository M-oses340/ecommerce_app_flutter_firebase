import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  String name = "User";
  String email = "";
  String address = "";
  String phone = "";
  String profileImage = "";

  bool get isLoggedIn => email.isNotEmpty;

  UserProvider() {
    _tryLoadUserData();
  }

  void _tryLoadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) loadUserData();
  }

  /// 🔹 Listen to Firestore changes in real-time
  void loadUserData() {
    _userSubscription?.cancel();
    _userSubscription = DbService().readUserData().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
        name = data.name;
        email = data.email;
        address = data.address;
        phone = data.phone;
        profileImage = data.profileImage ?? "";
        notifyListeners();
      }
    });
  }

  /// 🔹 Update provider manually
  void updateUserData(Map<String, dynamic> updatedData) {
    if (updatedData.containsKey("name")) name = updatedData["name"];
    if (updatedData.containsKey("email")) email = updatedData["email"];
    if (updatedData.containsKey("address")) address = updatedData["address"];
    if (updatedData.containsKey("phone")) phone = updatedData["phone"];
    if (updatedData.containsKey("profileImage")) profileImage = updatedData["profileImage"];
    notifyListeners();
  }

  /// 🔹 Cancel Firestore listener & reset fields
  void cancelProvider() {
    _userSubscription?.cancel();
    name = "User";
    email = "";
    address = "";
    phone = "";
    profileImage = "";
    notifyListeners();
  }

  @override
  void dispose() {
    cancelProvider();
    super.dispose();
  }
}
