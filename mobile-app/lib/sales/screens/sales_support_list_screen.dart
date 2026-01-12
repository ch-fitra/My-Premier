import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/support_model.dart';
import 'sales_support_detail_screen.dart';

class SalesSupportListScreen extends StatefulWidget {
  const SalesSupportListScreen({super.key});

  @override
  State<SalesSupportListScreen> createState() =>
      _SalesSupportListScreenState();
}

class _SalesSupportListScreenState extends State<SalesSupportListScreen> {
  bool _isLoading = false;
  String? _error;
  List<Support> _supports = [];

  @override
  void initState() {
    super.initState();
    _fetchSupports();
  }

  Future<void> _fetchSupports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiClient.get('/sales/supports');

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
          final supports = data
              .map((e) => Support.fromJson(e as Map<String, dynamic>))
              .toList();
          setState(() {
            _supports = supports;
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
          _error = 'Failed to parse supports';
          _isLoading = false;
        });
      }
    } else if (response.statusCode == 403) {
      setState(() {
        _error = 'This action is not allowed for your role';
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Failed to load supports (code ${response.statusCode})';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
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
                onPressed: _fetchSupports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_supports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No support tickets found.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Support tickets will appear here when clients create them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSupports,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _supports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final support = _supports[index];

          return Card(
            child: ListTile(
              title: Text(
                support.subject,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(_formatDate(support.createdAt)),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(support.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(support.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  support.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(support.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SalesSupportDetailScreen(
                      supportId: support.id,
                    ),
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

