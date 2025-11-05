import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:ecommerce_app/models/products_model.dart';
import 'package:flutter/material.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  final DbService _db = DbService();
  String _query = '';
  final List<String> _recentSearches = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search on ShopEasy...',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() => _query = value.trim());
            },
            onSubmitted: (value) {
              if (value.isNotEmpty && !_recentSearches.contains(value)) {
                setState(() {
                  _recentSearches.insert(0, value);
                });
              }
            },
          ),
        ),
      ),

      body: _query.isEmpty
          ? _buildSearchHistory()
          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.searchByKeyword(_query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("No products found for '$_query'"),
            );
          }

          final products = snapshot.data!
              .map((data) => ProductsModel.fromJson(data, data['id']))
              .toList();

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: Image.network(
                  product.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
                ),
                title: Text(product.name),
                subtitle: Text(product.category),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/view_product',
                    arguments: product,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 🕓 Show recent search terms when query is empty
  Widget _buildSearchHistory() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text('Start typing to search products...'),
      );
    }

    return ListView.builder(
      itemCount: _recentSearches.length,
      itemBuilder: (context, index) {
        final term = _recentSearches[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(term),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() => _recentSearches.removeAt(index));
            },
          ),
          onTap: () {
            _controller.text = term;
            setState(() => _query = term);
          },
        );
      },
    );
  }
}
