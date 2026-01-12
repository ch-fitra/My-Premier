import 'package:flutter/material.dart';
import 'sales_products_screen.dart';
import 'sales_requests_list_screen.dart';
import 'sales_support_list_screen.dart';

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Sales Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SalesProductsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('View Products'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SalesRequestsListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.description_outlined),
              label: const Text('My Requests'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SalesSupportListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent),
              label: const Text('Support'),
            ),
          ],
        ),
      ),
    );
  }
}

