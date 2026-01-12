import 'dart:convert';

import 'package:flutter/material.dart';

import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/product_model.dart';

class SalesCreateRequestScreen extends StatefulWidget {
  final Product product;

  const SalesCreateRequestScreen({
    super.key,
    required this.product,
  });

  @override
  State<SalesCreateRequestScreen> createState() =>
      _SalesCreateRequestScreenState();
}

class _SalesCreateRequestScreenState extends State<SalesCreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final response = await ApiClient.post(
      '/sales/requests',
      body: {
        'product_name': widget.product.name,
        'message': _messageController.text.trim(),
      },
    );

    if (!mounted) return;

    if (response == null) {
      // Token likely invalid (401 handled inside ApiClient) - force logout
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Success
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request created successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      // Wait a moment for snackbar to be visible, then navigate back
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      // Navigate back to products screen (pop twice: create request -> product detail -> products)
      Navigator.of(context).pop(); // Go back to product detail
      if (!mounted) return;
      Navigator.of(context).pop(); // Go back to products list
    } else {
      // Error
      setState(() {
        _isSubmitting = false;
      });

      String errorMessage = 'Failed to create request';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['error'] != null) {
          errorMessage = data['error'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      } catch (_) {
        // Use default error message
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.product.brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.product.brand,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (widget.product.series.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.product.series,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Message Field
              Text(
                'Message / Notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Enter your message or notes about this request...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Request',
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
      ),
    );
  }
}

