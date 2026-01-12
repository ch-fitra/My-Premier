import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/user_model.dart';
import '../../core/models/engineer_report_model.dart';
import '../../shared/screens/profile_screen.dart';
import 'engineer_reports_list_screen.dart';
import 'engineer_create_report_screen.dart';
import 'engineer_report_detail_screen.dart';

class EngineerDashboardScreen extends StatefulWidget {
  const EngineerDashboardScreen({super.key});

  @override
  State<EngineerDashboardScreen> createState() =>
      _EngineerDashboardScreenState();
}

class _EngineerDashboardScreenState extends State<EngineerDashboardScreen> {
  // Minimalist Color Palette
  final Color _primaryColor = Color(0xFF1A237E); // Clean blue
  final Color _backgroundColor = Color(0xFFF8FAFC); // Light gray background
  final Color _surfaceColor = Colors.white;
  final Color _successColor = Color(0xFF10B981); // Green
  final Color _warningColor = Color(0xFFF59E0B); // Orange
  final Color _textPrimary = Color(0xFF111827); // Dark gray
  final Color _textSecondary = Color(0xFF6B7280); // Medium gray
  final Color _borderColor = Color(0xFFE5E7EB); // Light border

  bool _isLoading = true;
  String? _error;
  UserModel? _user;
  List<EngineerReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        AuthService.getCurrentUser(),
        ApiClient.getEngineerReports(),
      ]);

      final user = results[0] as UserModel?;
      final reportsResponse = results[1] as http.Response?;

      if (!mounted) return;

      if (user == null || reportsResponse == null) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }

      if (reportsResponse.statusCode == 200) {
        try {
          final data = jsonDecode(reportsResponse.body);
          List<EngineerReport> reports = [];
          if (data is List) {
            reports = data
                .map((e) => EngineerReport.fromJson(e as Map<String, dynamic>))
                .toList();
          }

          setState(() {
            _user = user;
            _reports = reports;
            _isLoading = false;
          });
        } catch (e) {
          setState(() {
            _user = user;
            _reports = [];
            _error = 'Failed to parse reports';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _user = user;
          _reports = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load dashboard data';
        _isLoading = false;
      });
    }
  }

  int _getMonthlyReports() {
    final now = DateTime.now();
    return _reports.where((report) {
      return report.createdAt.year == now.year &&
          report.createdAt.month == now.month;
    }).length;
  }

  int _getUniqueReportDaysThisMonth() {
    final now = DateTime.now();
    final reportDates = <String>{};

    for (var report in _reports) {
      if (report.createdAt.year == now.year &&
          report.createdAt.month == now.month) {
        final dateKey =
            '${report.createdAt.year}-${report.createdAt.month}-${report.createdAt.day}';
        reportDates.add(dateKey);
      }
    }

    return reportDates.length;
  }

  Map<String, dynamic> _getReportRanking() {
    final uniqueReportDays = _getUniqueReportDaysThisMonth();
    final totalWorkingDays = 24; // Standard working days per month

    // Calculate percentage based on total working days (24)
    final percentage = (uniqueReportDays / totalWorkingDays * 100).round();

    String rank;
    Color rankColor;
    IconData rankIcon;
    String description;
    String feedback;

    if (percentage >= 85) {
      // Very Good - above 85% (20+ days)
      rank = 'Very Good';
      rankColor = Color(0xFF10B981); // Green
      rankIcon = Icons.emoji_events_rounded;
      description = '$percentage% completion';
      feedback =
          'Excellent work! Your consistent daily reporting shows great dedication and professionalism. Keep up this outstanding performance!';
    } else if (percentage >= 55) {
      // Good - 55% to 85% (13-20 days)
      rank = 'Good';
      rankColor = Color(0xFF3B82F6); // Blue
      rankIcon = Icons.trending_up_rounded;
      description = '$percentage% completion';
      feedback =
          'You\'re doing well! To reach Very Good status, aim for more consistent daily reports. Every report counts towards better performance tracking.';
    } else {
      // Bad - below 55% (less than 13 days)
      rank = 'Needs Improvement';
      rankColor = Color(0xFFEF4444); // Red
      rankIcon = Icons.warning_rounded;
      description = '$percentage% completion';
      feedback =
          'Your reporting frequency needs attention. Please ensure daily reports are submitted regularly. Consistent reporting helps track progress and maintains accountability.';
    }

    return {
      'rank': rank,
      'color': rankColor,
      'icon': rankIcon,
      'description': description,
      'feedback': feedback,
      'days': uniqueReportDays,
      'total': totalWorkingDays,
      'percentage': percentage,
    };
  }

  int _getApprovedReports() {
    return _reports
        .where((report) => report.status.toLowerCase() == 'approved')
        .length;
  }

  String _getUserName() {
    if (_user == null) return 'Engineer';
    final name = _user!.fullName ?? _user!.email.split('@')[0];
    return name.isEmpty ? 'Engineer' : name;
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

  Future<bool> _hasReportToday() async {
    try {
      final now = DateTime.now();
      final response = await ApiClient.getEngineerReportsByDate(now);
      if (response == null || response.statusCode != 200) {
        return false;
      }
      final body = response.body.trim();
      if (body.isEmpty || body == '[]') {
        return false;
      }
      return body.contains('{');
    } catch (_) {
      return false;
    }
  }

  bool _isWeekday() {
    final now = DateTime.now();
    return now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
  }

  Future<void> _showNotificationDialog() async {
    final now = DateTime.now();
    final isWeekday = _isWeekday();
    final hasReport = await _hasReportToday();

    if (!isWeekday) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.weekend, color: _primaryColor),
                const SizedBox(width: 12),
                const Text('Weekend'),
              ],
            ),
            content: const Text(
              'Daily reports are only required on weekdays (Monday-Friday).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (hasReport) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: _successColor),
                const SizedBox(width: 12),
                const Text('Report Submitted'),
              ],
            ),
            content: Text(
              'You have already submitted your daily report for ${DateFormat('EEEE, MMMM d').format(now)}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Show reminder to create report
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.notifications_active, color: _warningColor),
              const SizedBox(width: 12),
              const Text('Daily Report Reminder'),
            ],
          ),
          content: Text(
            'You haven\'t submitted your daily report for ${DateFormat('EEEE, MMMM d').format(now)} yet.\n\nWould you like to create it now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) => const EngineerCreateReportScreen(),
                  ),
                )
                    .then((result) {
                  if (result == true) {
                    _loadDashboardData();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Report'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    color: _primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Elegant Header with Gradient
                          _buildHeaderSection(),

                          // Stats Cards Grid
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: _buildStatsGrid(),
                          ),

                          // Quick Actions Section
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildQuickActionsSection(),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: _textSecondary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    final roleLabel = _getRoleLabel();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E), // Dark blue
            Color(0xFF283593), // Slightly lighter blue
            Color(0xFF1A237E), // Back to dark blue
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative shape for visual depth
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row with Logo and Notifications
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo Container with modern design
                      Container(
                        width: 80,
                        child: Center(
                          child: Image.asset(
                            'assets/premier.png',
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),

                      // Right side icons
                      Row(
                        children: [
                          // Notification icon
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showNotificationDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: FutureBuilder<bool>(
                                future: _hasReportToday(),
                                builder: (context, snapshot) {
                                  final hasReport = snapshot.data ?? false;
                                  final isWeekday = _isWeekday();
                                  final showBadge = isWeekday && !hasReport;

                                  return Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        if (showBadge)
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFFF6B6B),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // User profile/avatar
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (_user != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProfileScreen(user: _user!),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          const Text('User data not available'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _user != null
                                    ? Center(
                                        child: Text(
                                          _getInitials(
                                              _user!.fullName, _user!.email),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_outline,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Welcome Text and User Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Welcome back,\n',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            TextSpan(
                              text: _getUserName(),
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel() {
    if (_user == null) return 'Engineer';
    switch (_user!.role.toLowerCase()) {
      case 'engineer':
        return 'Engineer';
      case 'sales':
        return 'Sales Representative';
      case 'client':
        return 'Client';
      default:
        return 'Engineer';
    }
  }

  Widget _buildStatsGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        _buildMonthlyReportCard(),
        _buildRankingCard(),
      ],
    );
  }

  Widget _buildMonthlyReportCard() {
    final monthlyReports = _getMonthlyReports();
    final uniqueDays = _getUniqueReportDaysThisMonth();
    final now = DateTime.now();
    final reportProgress = (uniqueDays / 24.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('MMM').format(now).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$monthlyReports',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'reports',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$uniqueDays of 24 days',
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: reportProgress,
                backgroundColor: _borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(reportProgress * 100).toInt()}% completed',
              style: TextStyle(
                fontSize: 10,
                color: _textSecondary.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trend != null) ...[
              const SizedBox(height: 2),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRankingCard() {
    final ranking = _getReportRanking();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRankingDialog(context, ranking),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: ranking['color'].withOpacity(0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ranking['color'].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        ranking['icon'],
                        color: ranking['color'],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ranking['rank'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ranking['color'],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ranking['days']}/${ranking['total']} days',
                            style: TextStyle(
                              fontSize: 11,
                              color: _textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: _textSecondary.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ranking['color'].withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ranking['color'].withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 14,
                        color: ranking['color'],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ranking['feedback'],
                          style: TextStyle(
                            fontSize: 10,
                            color: _textPrimary,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRankingDialog(BuildContext context, Map<String, dynamic> ranking) {
    final emoji = ranking['rank'] == 'Very Good'
        ? '🎉'
        : ranking['rank'] == 'Good'
            ? '👍'
            : '⚠️';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _surfaceColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji/Expression
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ranking['color'].withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Ranking Title
                Text(
                  ranking['rank'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ranking['color'],
                  ),
                ),
                const SizedBox(height: 8),

                // Days info
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: ranking['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${ranking['days']} of ${ranking['total']} working days (${ranking['percentage']}%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ranking['color'],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Feedback message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ranking['color'].withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ranking['color'].withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: ranking['color'],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ranking['feedback'],
                          style: TextStyle(
                            fontSize: 14,
                            color: _textPrimary,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ranking['color'],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            _buildQuickActionCard(
              title: 'New Report',
              subtitle: 'Create report',
              icon: Icons.add_circle_outline,
              iconColor: Colors.white,
              backgroundColor: _primaryColor,
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EngineerCreateReportScreen(),
                  ),
                );
                if (result == true) {
                  _loadDashboardData();
                }
              },
            ),
            _buildQuickActionCard(
              title: 'View All',
              subtitle: 'All reports',
              icon: Icons.list_alt_outlined,
              iconColor: Colors.white,
              backgroundColor: _successColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EngineerReportsListScreen(),
                  ),
                );
              },
            ),
            _buildQuickActionCard(
              title: 'Analytics',
              subtitle: '${_getMonthlyReports()} this month',
              icon: Icons.insights_outlined,
              iconColor: Colors.white,
              backgroundColor: _warningColor,
              onTap: () {
                _showAnalyticsDialog(context);
              },
            ),
            _buildQuickActionCard(
              title: 'Settings',
              subtitle: 'Profile & Settings',
              icon: Icons.settings_outlined,
              iconColor: _textPrimary,
              backgroundColor: _surfaceColor,
              border: Border.all(color: _borderColor),
              onTap: () {
                if (_user != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: _user!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('User data not available'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    Border? border,
    VoidCallback? onTap,
  }) {
    final isColored = border == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: backgroundColor,
            border: border,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isColored ? Colors.white : _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isColored
                            ? Colors.white.withOpacity(0.9)
                            : _textSecondary,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: _textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No reports yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first report to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EngineerCreateReportScreen(),
                ),
              );
              if (result == true) {
                _loadDashboardData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Create Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(EngineerReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EngineerReportDetailScreen(
                  reportId: report.id,
                ),
              ),
            );
            if (result == true) {
              _loadDashboardData();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(report.status),
                    color: _getStatusColor(report.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(report.createdAt),
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatStatus(report.status),
                    style: TextStyle(
                      color: _getStatusColor(report.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: _textSecondary.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAnalyticsDialog(BuildContext context) {
    final totalReports = _reports.length;
    final monthlyReports = _getMonthlyReports();
    final approvedReports = _getApprovedReports();

    // Calculate status breakdown for pie chart
    final statusCounts = <String, int>{
      'approved': 0,
      'submitted': 0,
      'pending': 0,
      'draft': 0,
    };

    for (var report in _reports) {
      final status = report.status.toLowerCase();
      if (statusCounts.containsKey(status)) {
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
    }

    // Calculate monthly trend (last 6 months)
    final now = DateTime.now();
    final monthlyTrend = <int>[];
    final monthLabels = <String>[];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final count = _reports.where((report) {
        return report.createdAt.year == date.year &&
            report.createdAt.month == date.month;
      }).length;
      monthlyTrend.add(count);
      monthLabels.add(DateFormat('MMM').format(date));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _surfaceColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Report Analytics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line Chart - Monthly Trend
                        Text(
                          'Monthly Trend (Last 6 Months)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor, width: 1),
                          ),
                          child: _buildLineChart(monthlyTrend, monthLabels),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: _borderColor, width: 1),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieChart(Map<String, int> statusCounts, int total) {
    final colors = [
      _successColor, // approved
      _primaryColor, // submitted
      _warningColor, // pending
      _textSecondary, // draft
    ];
    final labels = ['Approved', 'Submitted', 'Pending', 'Draft'];
    final statusKeys = ['approved', 'submitted', 'pending', 'draft'];

    final data = statusKeys.map((key) => statusCounts[key] ?? 0).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: CustomPaint(
            painter: PieChartPainter(data, colors, total),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    'Total Reports',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(4, (index) {
            if (data[index] == 0) return const SizedBox.shrink();
            final percentage =
                total > 0 ? ((data[index] / total) * 100).round() : 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${labels[index]}: $percentage%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<int> data, List<String> labels) {
    if (data.isEmpty || data.every((e) => e == 0)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No data available',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final chartHeight = 180.0;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          width: double.infinity,
          child: CustomPaint(
            painter: LineChartPainter(data, labels, maxValue, _primaryColor),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: labels.map((label) {
            return Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnalyticsStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdownRow(
    String status,
    int count,
    Color color,
    IconData icon,
    int total,
  ) {
    final percentage = total > 0 ? ((count / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count reports ($percentage%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Use UTC to get date components to avoid timezone issues
    final dateUtc = date.toUtc();
    final now = DateTime.now().toUtc();
    final today = DateTime(now.year, now.month, now.day);
    final reportDate = DateTime(dateUtc.year, dateUtc.month, dateUtc.day);

    if (reportDate == today) {
      return 'Today';
    } else if (reportDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      // Format using the original date (which is already in local time after toLocal())
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  String _formatStatus(String status) {
    return status.substring(0, 1).toUpperCase() +
        status.substring(1).toLowerCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return _successColor;
      case 'submitted':
        return _primaryColor;
      case 'draft':
        return _textSecondary;
      case 'pending':
        return _warningColor;
      default:
        return _textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'submitted':
        return Icons.send_outlined;
      case 'draft':
        return Icons.drafts_outlined;
      case 'pending':
        return Icons.pending_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}

// Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<int> data;
  final List<Color> colors;
  final int total;

  PieChartPainter(this.data, this.colors, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 2 - 20;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (int i = 0; i < data.length; i++) {
      if (data[i] == 0) continue;

      final sweepAngle = (data[i] / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Line Chart Painter
class LineChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> labels;
  final int maxValue;
  final Color lineColor;

  LineChartPainter(this.data, this.labels, this.maxValue, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (maxValue == 0) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final pointCount = data.length;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw line and points
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < pointCount; i++) {
      final x = padding + (chartWidth / (pointCount - 1)) * i;
      final normalizedValue = maxValue > 0 ? data[i] / maxValue : 0.0;
      final y = padding + chartHeight - (chartHeight * normalizedValue);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw filled area
    final fillPath = Path.from(path);
    fillPath.lineTo(padding + chartWidth, padding + chartHeight);
    fillPath.lineTo(padding, padding + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..color = lineColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, linePaint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(
          point,
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // Draw values
    for (int i = 0; i < pointCount; i++) {
      if (data[i] > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${data[i]}',
            style: TextStyle(
              fontSize: 10,
              color: lineColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        final x = padding + (chartWidth / (pointCount - 1)) * i;
        final normalizedValue = maxValue > 0 ? data[i] / maxValue : 0.0;
        final y = padding + chartHeight - (chartHeight * normalizedValue);
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - 20),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
