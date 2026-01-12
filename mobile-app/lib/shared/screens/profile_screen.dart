import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Professional Color Scheme - Minimalist & Modern
  final Color _primaryColor = Color(0xFF0A192F); // Navy Blue - Professional
  final Color _secondaryColor = Color(0xFF1A365D); // Dark Blue
  final Color _accentColor = Color(0xFF1A237E); // Cyan Accent
  final Color _backgroundColor = Color(0xFFF7FAFC); // Light Gray Background
  final Color _surfaceColor = Color(0xFFFFFFFF); // Pure White
  final Color _textPrimary = Color(0xFF1A202C); // Charcoal
  final Color _textSecondary = Color(0xFF718096); // Gray
  final Color _borderColor = Color(0xFFE2E8F0); // Light Border
  final Color _successColor = Color(0xFF38A169); // Green
  final Color _errorColor = Color(0xFFE53E3E); // Red
  final Color _cardSurface = Color(0xFFFFFFFF); // Card White

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingProfile = true;
  String? _error;
  bool _isCardFlipped = false; // Untuk flip animation kartu

  UserModel? _profile;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _error = null;
    });

    final response = await ApiClient.getMyProfile();

    if (!mounted) return;

    if (response == null) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final profile = UserModel.fromJson(data);
        setState(() {
          _profile = profile;
          _fullNameController.text = profile.fullName ?? '';
          _phoneController.text = profile.phone ?? '';
          _isLoadingProfile = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Failed to parse profile data';
          _isLoadingProfile = false;
        });
      }
    } else {
      setState(() {
        _error = 'Failed to load profile (code ${response.statusCode})';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final response = await ApiClient.updateProfile(
      fullName: fullName,
      phone: phone,
    );

    if (!mounted) return;

    if (response == null) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (response.statusCode == 200) {
      await _fetchProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } else {
      String errorMessage = 'Failed to update profile';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['error'] != null) {
          errorMessage = data['error'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      } catch (_) {}

      setState(() {
        _error = errorMessage;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isChanging = false;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentColor.withOpacity(0.2)),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 28,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMinimalTextField(
                  controller: oldPasswordController,
                  hint: 'Current Password',
                  obscureText: true,
                  enabled: !isChanging,
                ),
                const SizedBox(height: 12),
                _buildMinimalTextField(
                  controller: newPasswordController,
                  hint: 'New Password',
                  obscureText: true,
                  enabled: !isChanging,
                ),
                const SizedBox(height: 12),
                _buildMinimalTextField(
                  controller: confirmPasswordController,
                  hint: 'Confirm New Password',
                  obscureText: true,
                  enabled: !isChanging,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isChanging
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: _textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isChanging
                            ? null
                            : () async {
                                final oldPassword =
                                    oldPasswordController.text.trim();
                                final newPassword =
                                    newPasswordController.text.trim();
                                final confirmPassword =
                                    confirmPasswordController.text.trim();

                                if (oldPassword.isEmpty ||
                                    newPassword.isEmpty ||
                                    confirmPassword.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          const Text('All fields are required'),
                                      backgroundColor: _errorColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (newPassword != confirmPassword) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          const Text('Passwords do not match'),
                                      backgroundColor: _errorColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isChanging = true;
                                });

                                final response = await ApiClient.changePassword(
                                  oldPassword: oldPassword,
                                  newPassword: newPassword,
                                );

                                if (!context.mounted) return;

                                if (response == null) {
                                  await AuthService.logout();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/login', (route) => false);
                                  return;
                                }

                                if (response.statusCode == 200) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Password changed successfully'),
                                      backgroundColor: _successColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                } else {
                                  String errorMessage =
                                      'Failed to change password';
                                  try {
                                    final data = jsonDecode(response.body);
                                    if (data is Map && data['error'] != null) {
                                      errorMessage = data['error'].toString();
                                    } else if (data is Map &&
                                        data['message'] != null) {
                                      errorMessage = data['message'].toString();
                                    }
                                  } catch (_) {}

                                  setDialogState(() {
                                    isChanging = false;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      backgroundColor: _errorColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: isChanging
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        style: TextStyle(
          fontSize: 14,
          color: _textPrimary,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: _surfaceColor,
          hintText: hint,
          hintStyle: TextStyle(
            color: _textSecondary.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          enabled: enabled,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _errorColor.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 28,
                  color: _errorColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: _textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      await AuthService.logout();

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'client':
        return 'Client';
      case 'sales':
        return 'Sales';
      case 'engineer':
        return 'Field Engineer';
      default:
        return role;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    try {
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return date.toString();
    }
  }

  String _getInitials(String? name, String email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProfile) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accentColor),
            const SizedBox(height: 16),
            Text(
              'Loading profile...',
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null && _profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: _errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final currentProfile = _profile ?? widget.user;
    final initials =
        _getInitials(currentProfile.fullName, currentProfile.email);
    final displayName =
        currentProfile.fullName ?? currentProfile.email.split('@')[0];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Card Style Header
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar with professional styling
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),

                // Name and Role
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                Text(
                  _getRoleDisplayName(currentProfile.role),
                  style: TextStyle(
                    fontSize: 14,
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  currentProfile.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (currentProfile.role.toLowerCase() == 'engineer') ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: _accentColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                      color: _accentColor.withOpacity(0.05),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 16,
                              color: _accentColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Professional ID Card',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              _showBusinessCardDialog(context, currentProfile),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('View Digital ID'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Account Information
          _buildMinimalCard(
            title: 'Account Information',
            children: [
              _buildMinimalInfoRow(
                label: 'Email Address',
                value: currentProfile.email,
                icon: Icons.email_outlined,
              ),
              const Divider(height: 20, color: Color(0xFFE2E8F0)),
              _buildMinimalInfoRow(
                label: 'Account Role',
                value: _getRoleDisplayName(currentProfile.role),
                icon: Icons.engineering_outlined,
                valueColor: _accentColor,
              ),
              if (currentProfile.createdAt != null) ...[
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                _buildMinimalInfoRow(
                  label: 'Member Since',
                  value: _formatDate(currentProfile.createdAt),
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Profile Details (Editable)
          _buildMinimalCard(
            title: 'Profile Details',
            children: [
              const SizedBox(height: 4),
              Text(
                'Full Name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              _buildMinimalTextField(
                controller: _fullNameController,
                hint: 'Enter your full name',
              ),
              const SizedBox(height: 16),
              Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              _buildMinimalTextField(
                controller: _phoneController,
                hint: 'Enter phone number',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons
          _buildMinimalCard(
            children: [
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Save Changes'),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSaving ? null : _showChangePasswordDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textPrimary,
                  side: BorderSide(color: _borderColor),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Change Password'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _errorColor,
                  side: BorderSide(color: _errorColor),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMinimalCard({
    String? title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildMinimalInfoRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: _textSecondary.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: valueColor ?? _textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBusinessCardDialog(BuildContext context, UserModel profile) {
    _isCardFlipped = false; // Reset state setiap kali dialog dibuka

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Business Card dengan Flip Animation
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCardFlipped = !_isCardFlipped;
                        });
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          final rotateAnim =
                              Tween(begin: pi, end: 0.0).animate(animation);
                          return AnimatedBuilder(
                            animation: rotateAnim,
                            child: child,
                            builder: (context, child) {
                              return Transform(
                                transform: Matrix4.rotationY(rotateAnim.value),
                                alignment: Alignment.center,
                                child: child,
                              );
                            },
                          );
                        },
                        child: _isCardFlipped
                            ? _buildCardBack(profile) // Tampak belakang
                            : _buildCardFront(profile), // Tampak depan
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: _textSecondary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _printBusinessCard(profile);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Print'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardFront(UserModel profile) {
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: _borderColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Logo/Company
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  child: Center(
                    child: Image.asset(
                      'assets/premier.png',
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(
            width: 1,
            height: 120,
            color: _borderColor,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Right side - Personal Info
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  profile.fullName?.toUpperCase() ??
                      profile.email.split('@')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),

                // Title
                Text(
                  _getRoleDisplayName(profile.role).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: 16),

                // Contact Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            profile.email,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (profile.phone != null && profile.phone!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            profile.phone!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(UserModel profile) {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: _borderColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Company Info
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  child: Center(
                    child: Image.asset(
                      'assets/premier.png',
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PT Premier Engineering Indonesia is a leading company in the field of contractors and suppliers of industrial solutions. Since its establishment in 2005, we have served various clients throughout Indonesia with a commitment to providing high-quality products and services.\n\nWe specialize in providing industrial equipment, automation systems, and innovative technical solutions for various industrial sectors including manufacturing, energy, and infrastructure.',
                  style: TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackInfoItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _printBusinessCard(UserModel profile) async {
    try {
      final pdf = await _createBusinessCardPdf(profile);
      await Printing.layoutPdf(
        onLayout: (format) async => pdf,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: $e'),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<Uint8List> _createBusinessCardPdf(UserModel profile) async {
    final pdf = pw.Document();

    // Tambahkan halaman depan
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(252, 144), // 3.5" x 2" in points
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Container(
            width: 252,
            height: 144,
            padding: const pw.EdgeInsets.all(20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Left side - Logo/Company
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 40,
                        width: 40,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#0A192F'),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'MP',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'MY PREMIER',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#718096'),
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'ENGINEERING',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.normal,
                          color: PdfColor.fromHex('#A0AEC0'),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical divider
                pw.Container(
                  width: 0.5,
                  height: 100,
                  color: PdfColor.fromHex('#E2E8F0'),
                  margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                ),

                // Right side - Personal Info
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Name
                      pw.Text(
                        profile.fullName?.toUpperCase() ??
                            profile.email.split('@')[0].toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1A202C'),
                          letterSpacing: 0.3,
                        ),
                      ),

                      // Title
                      pw.Text(
                        _getRoleDisplayName(profile.role).toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#00B5D8'),
                          letterSpacing: 0.8,
                        ),
                      ),

                      pw.SizedBox(height: 12),

                      // Contact Info
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(
                                'E:',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#718096'),
                                ),
                              ),
                              pw.SizedBox(width: 4),
                              pw.Expanded(
                                child: pw.Text(
                                  profile.email,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColor.fromHex('#4A5568'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          if (profile.phone != null &&
                              profile.phone!.isNotEmpty)
                            pw.Row(
                              children: [
                                pw.Text(
                                  'P:',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('#718096'),
                                  ),
                                ),
                                pw.SizedBox(width: 4),
                                pw.Text(
                                  profile.phone!,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColor.fromHex('#4A5568'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Tambahkan halaman belakang
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(252, 144),
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Container(
            width: 252,
            height: 144,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0A192F'),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Header bagian belakang
                pw.Text(
                  'MY PREMIER ENGINEERING',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.8,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 2),

                pw.Text(
                  'PROFESSIONAL CREDENTIALS',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.normal,
                    color: PdfColor.fromInt(0xCCFFFFFF),
                    letterSpacing: 0.6,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 16),

                // Divider
                pw.Container(
                  height: 0.5,
                  color: PdfColor.fromInt(0x4DFFFFFF),
                ),

                pw.SizedBox(height: 16),

                // Konten bagian belakang
                pw.Column(
                  children: [
                    _buildPdfBackInfoItem(
                      'HEADQUARTERS',
                      'Jakarta, Indonesia',
                    ),
                    pw.SizedBox(height: 8),
                    _buildPdfBackInfoItem(
                      'WEBSITE',
                      'www.mypremier.com',
                    ),
                    pw.SizedBox(height: 8),
                    _buildPdfBackInfoItem(
                      'SPECIALIZATION',
                      'Industrial Solutions',
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),

                // Footer
                pw.Text(
                  'Member Since ${_formatDate(profile.createdAt)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromInt(0x99FFFFFF),
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfBackInfoItem(String title, String content) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xB3FFFFFF),
                  letterSpacing: 0.6,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                content,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
