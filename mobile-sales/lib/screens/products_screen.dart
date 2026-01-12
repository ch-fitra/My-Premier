import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await ApiService.getProducts();
      if (mounted) {
        setState(() {
          _products = products ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load products';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    final query = _searchQuery.toLowerCase();
    return _products.where((product) {
      final name = (product['name'] ?? '').toLowerCase();
      final brand = (product['brand'] ?? '').toLowerCase();
      final series = (product['series'] ?? '').toLowerCase();
      
      return name.contains(query) ||
          brand.contains(query) ||
          series.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, brand, or series...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No products found'
                                      : 'No products available',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'N/A';
    final brand = product['brand'] ?? 'N/A';
    final series = product['series'] ?? 'N/A';
    final images = product['images'] as List<dynamic>? ?? [];
    final datasheetUrl = product['datasheet_url'] ?? '';
    final firstImage = images.isNotEmpty ? images[0] : null;
    final imageUrl = firstImage is String
        ? firstImage
        : (firstImage is Map ? firstImage['image_url'] : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl.startsWith('http')
                      ? imageUrl
                      : 'http://localhost:8080$imageUrl',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2),
              ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Brand: $brand',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            if (series.isNotEmpty && series != 'N/A')
              Text(
                'Series: $series',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Images:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final img = images[index];
                        final url = img is String
                            ? img
                            : (img is Map ? img['image_url'] : null);
                        if (url == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url.startsWith('http')
                                  ? url
                                  : 'http://localhost:8080$url',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (datasheetUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Datasheet:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      // Open datasheet URL
                      // You can use url_launcher package for this
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              datasheetUrl,
                              style: const TextStyle(color: Colors.blue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
                if (product['id'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Product ID: ${product['id']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

