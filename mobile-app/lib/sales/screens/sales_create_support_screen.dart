import 'dart:convert';

import 'package:flutter/material.dart';

import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/user_model.dart';

class SalesCreateSupportScreen extends StatefulWidget {
  const SalesCreateSupportScreen({super.key});

  @override
  State<SalesCreateSupportScreen> createState() =>
      _SalesCreateSupportScreenState();
}

class _SalesCreateSupportScreenState extends State<SalesCreateSupportScreen> {
  UserModel? _user;
  bool _checkingRole = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _checkingRole = false;
      });
      // If user is sales, show error and navigate back
      if (user != null && user.isSales) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This action is not allowed for your role'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pop();
          }
        });
      }
    }
  }
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitSupport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final response = await ApiClient.post(
      '/sales/supports',
      body: {
        'subject': _subjectController.text.trim(),
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
          content: Text('Support ticket created successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      // Wait a moment for snackbar to be visible, then navigate back
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      // Navigate back with success result
      Navigator.of(context).pop(true);
    } else {
      // Error
      setState(() {
        _isSubmitting = false;
      });

      String errorMessage = 'Failed to create support ticket';
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
    // Defensive check: If checking role or user is sales, show error screen
    if (_checkingRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user != null && _user!.isSales) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'This action is not allowed for your role',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Support Ticket'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Field
              Text(
                'Subject',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'Enter support ticket subject...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Message Field
              Text(
                'Message',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Enter your message...',
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
                  onPressed: _isSubmitting ? null : _submitSupport,
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
                          'Create Support Ticket',
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

