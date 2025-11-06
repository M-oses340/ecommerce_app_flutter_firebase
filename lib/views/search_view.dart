import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:ecommerce_app/models/products_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  final DbService _db = DbService();
  String _query = '';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  void _addSearchTerm(String term) {
    if (term.isEmpty) return;
    setState(() {
      _recentSearches.remove(term); // Avoid duplicates
      _recentSearches.insert(0, term);
      if (_recentSearches.length > 8) _recentSearches.removeLast();
    });
    _saveSearchHistory();
  }

  void _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => _recentSearches.clear());
  }

  void _clearQuery() {
    setState(() {
      _controller.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, size: 22),
              const SizedBox(width: 8),
              Expanded(
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
                    _addSearchTerm(value.trim());
                  },
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: _clearQuery,
                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                )
              else
                GestureDetector(
                  onTap: () {
                    // 👇 Placeholder for future voice search
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Voice search coming soon 🎤")),
                    );
                  },
                  child: const Icon(Icons.mic_none, size: 22),
                ),
            ],
          ),
        ),
      ),

      body: _query.isEmpty
          ? _buildChipHistory(context)
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
                  _addSearchTerm(_query);
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

  /// 🧡 Horizontally scrollable chips for recent searches
  Widget _buildChipHistory(BuildContext context) {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text('Start typing to search products...'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Searches",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: _clearAllHistory,
                child: const Text("Clear all"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _recentSearches.map((term) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InputChip(
                    label: Text(term),
                    avatar: const Icon(Icons.history, size: 18),
                    onPressed: () {
                      _controller.text = term;
                      setState(() => _query = term);
                    },
                    onDeleted: () {
                      setState(() => _recentSearches.remove(term));
                      _saveSearchHistory();
                    },
                    deleteIconColor: Colors.grey,
                    backgroundColor:
                    Theme.of(context).colorScheme.surfaceVariant,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
