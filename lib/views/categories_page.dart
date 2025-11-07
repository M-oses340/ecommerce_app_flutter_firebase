import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/products_model.dart';
import 'package:ecommerce_app/views/view_product.dart';
import 'package:flutter/material.dart';

class CategoriesPage extends StatefulWidget {
  final String categoryName;

  const CategoriesPage({super.key, required this.categoryName});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 🔙 Back + Search Bar Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: textColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search in ${widget.categoryName}",
                        hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.6)),
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),

            // 🔽 Category and Products Panels
            Expanded(
              child: Row(
                children: [
                  // 🧭 Left panel - categories
                  Container(
                    width: 100,
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('shop_categories')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final categories = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final data = categories[index].data() as Map<String, dynamic>;
                            final name = data["name"] ?? "";
                            final image = data["image"] ?? "";
                            final selected = name == widget.categoryName;

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CategoriesPage(categoryName: name),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? (isDark ? Colors.white12 : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: image.isNotEmpty
                                          ? Image.network(
                                        image,
                                        height: 60,
                                        width: 60,
                                        fit: BoxFit.cover,
                                      )
                                          : const Icon(Icons.image_not_supported, size: 40),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                        selected ? FontWeight.bold : FontWeight.normal,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 🛍️ Right panel - products grid
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('shop_products')
                          .where('category', isEqualTo: widget.categoryName)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final allProducts = ProductsModel.fromJsonList(snapshot.data!.docs);
                        final filtered = allProducts
                            .where((p) =>
                        p.name.toLowerCase().contains(searchQuery) ||
                            p.description.toLowerCase().contains(searchQuery))
                            .toList();

                        if (filtered.isEmpty) {
                          return const Center(child: Text("No products found"));
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewProduct(product: product),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[900] : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    if (!isDark)
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Image.network(
                                        product.image,
                                        height: 130,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "KSh ${product.new_price}",
                                            style: TextStyle(
                                              color: Colors.greenAccent[400],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Was ${product.old_price}",
                                            style: TextStyle(
                                              color: textColor.withOpacity(0.6),
                                              fontSize: 12,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
