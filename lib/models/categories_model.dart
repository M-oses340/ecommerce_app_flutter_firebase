import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriesModel {
  final String id;
  final String name;
  final String image;
  final int priority;

  CategoriesModel({
    required this.id,
    required this.name,
    required this.image,
    required this.priority,
  });

  /// Factory: Convert Firestore document data → CategoriesModel
  factory CategoriesModel.fromJson(Map<String, dynamic> json, String id) {
    return CategoriesModel(
      id: id,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      priority: json['priority'] is int
          ? json['priority']
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
    );
  }

  /// Convert Firestore document list → List<CategoriesModel>
  static List<CategoriesModel> fromJsonList(
      List<QueryDocumentSnapshot> docs) {
    return docs
        .map((e) => CategoriesModel.fromJson(
      e.data() as Map<String, dynamic>,
      e.id,
    ))
        .toList();
  }

  /// Convert model → Map (for saving back to Firestore)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': image,
      'priority': priority,
    };
  }
}
