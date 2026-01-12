import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/product_model.dart';
import 'sales_create_request_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  Future<void> _openDatasheet(BuildContext context) async {
    final url = product.datasheetUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid datasheet URL')),
      );
      return;
    }

    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open datasheet')),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    product.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 40),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.inventory_2_outlined, size: 48),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              product.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.brand.isNotEmpty ? product.brand : 'Unknown brand',
              style: theme.textTheme.titleMedium,
            ),
            if (product.series.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                product.series,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (product.datasheetUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datasheet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openDatasheet(context),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open datasheet'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            // Create Request Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SalesCreateRequestScreen(product: product),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Create Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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


