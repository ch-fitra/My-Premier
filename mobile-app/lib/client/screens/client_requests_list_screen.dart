import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/sales_request_model.dart';
import 'client_request_detail_screen.dart';

class ClientRequestsListScreen extends StatefulWidget {
  const ClientRequestsListScreen({super.key});

  @override
  State<ClientRequestsListScreen> createState() =>
      _ClientRequestsListScreenState();
}

class _ClientRequestsListScreenState extends State<ClientRequestsListScreen> {
  bool _isLoading = false;
  String? _error;
  List<SalesRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiClient.get('/client/requests');

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
          final requests = data
              .map(
                (e) => SalesRequest.fromJson(e as Map<String, dynamic>),
              )
              .toList();
          setState(() {
            _requests = requests;
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
          _error = 'Failed to parse requests';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = 'Failed to load requests (code ${response.statusCode})';
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
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
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
                onPressed: _fetchRequests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No requests found.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final request = _requests[index];

          return Card(
            child: ListTile(
              title: Text(
                request.productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(_formatDate(request.createdAt)),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(request.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(request.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ClientRequestDetailScreen(request: request),
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


