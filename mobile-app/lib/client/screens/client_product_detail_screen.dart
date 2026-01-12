import 'package:flutter/material.dart';

import '../../core/models/product_model.dart';
import 'client_create_request_screen.dart';

class ClientProductDetailScreen extends StatelessWidget {
  final Product product;

  const ClientProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = product.images.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.images.first,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 150,
                      child: Center(
                        child: Icon(Icons.image_not_supported, size: 48),
                      ),
                    );
                  },
                ),
              )
            else
              const SizedBox(
                height: 150,
                child: Center(
                  child: Icon(Icons.inventory_2_outlined, size: 48),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (product.brand.isNotEmpty) product.brand,
                if (product.series.isNotEmpty) product.series,
              ].join(' • '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Request Information Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ClientCreateRequestScreen(product: product),
                    ),
                  );
                },
                icon: const Icon(Icons.mail_outline),
                label: const Text(
                  'Request Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

