import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/product_model.dart';
import 'client_product_detail_screen.dart';

class ClientProductsScreen extends StatefulWidget {
  const ClientProductsScreen({super.key});

  @override
  State<ClientProductsScreen> createState() => _ClientProductsScreenState();
}

class _ClientProductsScreenState extends State<ClientProductsScreen> {
  bool _isLoading = false;
  String? _error;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Try client-specific endpoint first, then fall back to public /products
    http.Response? response = await ApiClient.get('/client/products');

    if (response != null &&
        (response.statusCode == 404 || response.statusCode == 403)) {
      // Fallback to generic products endpoint (public)
      response = await ApiClient.get('/products');
    }

    if (!mounted) return;

    if (response == null) {
      // Token likely invalid (401 handled inside ApiClient) - force logout
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          final products = data
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
          setState(() {
            _products = products;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Unexpected response format';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Failed to parse products';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        final code = response?.statusCode;
        _error = 'Failed to load products (code ${code ?? 'unknown'})';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _fetchProducts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No products available.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProducts,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final product = _products[index];
          final hasImage = product.images.isNotEmpty;

          return Card(
            child: ListTile(
              leading: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.images.first,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported);
                        },
                      ),
                    )
                  : const CircleAvatar(
                      child: Icon(Icons.inventory_2_outlined),
                    ),
              title: Text(product.name),
              subtitle: Text(
                '${product.brand.isNotEmpty ? product.brand : 'Unknown brand'}'
                '${product.series.isNotEmpty ? ' • ${product.series}' : ''}',
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClientProductDetailScreen(product: product),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
