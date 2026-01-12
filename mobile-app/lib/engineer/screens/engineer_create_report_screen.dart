import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../auth/auth_service.dart';
import '../../core/api_client.dart';

class EngineerCreateReportScreen extends StatefulWidget {
  const EngineerCreateReportScreen({super.key});

  @override
  State<EngineerCreateReportScreen> createState() =>
      _EngineerCreateReportScreenState();
}

class _EngineerCreateReportScreenState
    extends State<EngineerCreateReportScreen> {
  // Color Scheme
  final Color _primaryColor = Color(0xFF1A237E);
  final Color _secondaryColor = Color(0xFF3949AB);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = Color(0xFF111827);
  final Color _textSecondary = Color(0xFF6B7280);
  final Color _borderColor = Color(0xFFE5E7EB);
  final Color _successColor = Color(0xFF10B981);
  final Color _errorColor = Color(0xFFEF4444);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final response = await ApiClient.createEngineerReport(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      _selectedDate,
    );

    if (!mounted) return;

    if (response == null) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report created successfully'),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } else if (response.statusCode == 403) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This action is not allowed for your role'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      String errorMessage = 'Failed to create report';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['error'] != null) {
          errorMessage = data['error'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      } catch (_) {
        // keep default
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        title: Text(
          'Create Daily Report',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: _textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_primaryColor, _secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Daily Report',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in the details of your daily work activities',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Title Field
                _buildSectionHeader(
                  'Report Title',
                  required: true,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 16,
                      color: _textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _surfaceColor,
                      hintText: 'e.g., Installation at Client A',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: _textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _borderColor,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _borderColor,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _errorColor,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _errorColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.title_rounded,
                        color: _textSecondary.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Date Field
                _buildSectionHeader(
                  'Report Date',
                  required: false,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: _primaryColor,
                                onPrimary: Colors.white,
                                onSurface: _textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: _textSecondary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Select date (optional)'
                                  : DateFormat('EEEE, MMMM d, yyyy')
                                      .format(_selectedDate!),
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate == null
                                    ? _textSecondary.withOpacity(0.7)
                                    : _textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_selectedDate != null)
                            IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: _textSecondary.withOpacity(0.7),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description Field
                _buildSectionHeader(
                  'Work Description',
                  required: true,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(
                      fontSize: 16,
                      color: _textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 8,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _surfaceColor,
                      hintText:
                          'Describe the work performed, challenges faced, and solutions implemented...',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: _textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _borderColor,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _borderColor,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _errorColor,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _errorColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Icon(
                          Icons.description_rounded,
                          color: _textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Please provide more detailed description';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Notes Field (Optional)
                _buildSectionHeader(
                  'Additional Notes',
                  required: false,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _notesController,
                    style: TextStyle(
                      fontSize: 16,
                      color: _textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 6,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _surfaceColor,
                      hintText:
                          'Any additional notes, follow-up items, or special considerations...',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: _textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _borderColor,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _borderColor,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Icon(
                          Icons.note_add_rounded,
                          color: _textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSubmitting)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          const Icon(
                            Icons.send_rounded,
                            size: 20,
                          ),
                        const SizedBox(width: 12),
                        Text(
                          _isSubmitting
                              ? 'Creating Report...'
                              : 'Submit Report',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Info text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '* Required fields',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required bool required}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _errorColor,
            ),
          ),
        ],
      ],
    );
  }
}
