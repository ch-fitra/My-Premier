import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/engineer_report_model.dart';
import 'engineer_create_report_screen.dart';
import 'engineer_report_detail_screen.dart';

enum FilterType { today, week, month }

class EngineerReportsListScreen extends StatefulWidget {
  const EngineerReportsListScreen({super.key});

  @override
  State<EngineerReportsListScreen> createState() =>
      _EngineerReportsListScreenState();
}

class _EngineerReportsListScreenState extends State<EngineerReportsListScreen> {
  // Color Scheme
  final Color _primaryColor = Color(0xFF1A237E);
  final Color _secondaryColor = Color(0xFF3949AB);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = Color(0xFF111827);
  final Color _textSecondary = Color(0xFF6B7280);
  final Color _borderColor = Color(0xFFE5E7EB);
  final Color _successColor = Color(0xFF10B981);
  final Color _warningColor = Color(0xFFF59E0B);
  final Color _infoColor = Color(0xFF3B82F6);

  bool _isLoading = false;
  String? _error;
  List<EngineerReport> _reports = [];
  FilterType _selectedFilter = FilterType.month;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiClient.getEngineerReports();

    if (!mounted) return;

    if (response == null) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (response.statusCode == 200) {
      try {
        // Handle empty response body
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          setState(() {
            _reports = [];
            _isLoading = false;
            _error = null;
          });
          return;
        }

        final data = jsonDecode(response.body);

        // Handle null or empty data
        if (data == null) {
          setState(() {
            _reports = [];
            _isLoading = false;
            _error = null;
          });
          return;
        }

        // Handle List response (expected format)
        if (data is List) {
          final reports = data
              .map((e) {
                try {
                  return EngineerReport.fromJson(e as Map<String, dynamic>);
                } catch (e) {
                  return null;
                }
              })
              .where((report) => report != null)
              .cast<EngineerReport>()
              .toList();
          setState(() {
            _reports = reports;
            _isLoading = false;
            _error = null;
          });
          return;
        }

        // If data is not a List but response is 200, treat as empty
        // This handles cases where backend returns empty object {} or other formats
        setState(() {
          _reports = [];
          _isLoading = false;
          _error = null;
        });
      } catch (e) {
        // If JSON parsing fails but status is 200, treat as empty rather than error
        setState(() {
          _reports = [];
          _isLoading = false;
          _error = null;
        });
      }
    } else if (response.statusCode == 403) {
      setState(() {
        _error = 'This action is not allowed for your role';
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Failed to load reports (code ${response.statusCode})';
        _isLoading = false;
      });
    }
  }

  Map<String, EngineerReport> _getReportsByDate() {
    final map = <String, EngineerReport>{};
    for (final report in _reports) {
      try {
        final dateOnly = DateTime(report.createdAt.year, report.createdAt.month,
            report.createdAt.day);
        final dateKey = DateFormat('yyyy-MM-dd').format(dateOnly);
        map[dateKey] = report;
      } catch (e) {}
    }
    return map;
  }

  List<EngineerReport> _getFilteredReports() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<EngineerReport> filtered;

    switch (_selectedFilter) {
      case FilterType.today:
        filtered = _reports.where((report) {
          final reportDateOnly = DateTime(
            report.createdAt.year,
            report.createdAt.month,
            report.createdAt.day,
          );
          return reportDateOnly.isAtSameMomentAs(today);
        }).toList();
        break;

      case FilterType.week:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weekStartOnly =
            DateTime(weekStart.year, weekStart.month, weekStart.day);
        final weekEndOnly = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

        filtered = _reports.where((report) {
          final reportDateOnly = DateTime(
            report.createdAt.year,
            report.createdAt.month,
            report.createdAt.day,
          );
          return !reportDateOnly.isBefore(weekStartOnly) &&
              !reportDateOnly.isAfter(weekEndOnly);
        }).toList();
        break;

      case FilterType.month:
        filtered = _reports.where((report) {
          return report.createdAt.year == now.year &&
              report.createdAt.month == now.month;
        }).toList();
        break;
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;
    final reportsByDate = _getReportsByDate();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday headers with modern design
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Calendar grid with modern styling
          ...List.generate(
            ((firstWeekday + daysInMonth - 1) / 7).ceil(),
            (weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final dayNumber =
                        weekIndex * 7 + dayIndex - firstWeekday + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const Expanded(child: SizedBox());
                    }

                    final date = DateTime(now.year, now.month, dayNumber);
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    final hasReport = reportsByDate.containsKey(dateKey);
                    final isToday = date.isAtSameMomentAs(today);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 40,
                        decoration: BoxDecoration(
                          color: isToday
                              ? _primaryColor
                              : hasReport
                                  ? _successColor.withOpacity(0.1)
                                  : null,
                          borderRadius: BorderRadius.circular(10),
                          border: hasReport && !isToday
                              ? Border.all(
                                  color: _successColor.withOpacity(0.3),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayNumber.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isToday
                                    ? Colors.white
                                    : hasReport
                                        ? _successColor
                                        : _textPrimary,
                              ),
                            ),
                            if (hasReport && !isToday)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _successColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Reports',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  'Today',
                  FilterType.today,
                  Icons.today_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  'Week',
                  FilterType.week,
                  Icons.view_week_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  'Month',
                  FilterType.month,
                  Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, FilterType filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _primaryColor : _borderColor,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : _textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    try {
      // Use UTC to get date components to avoid timezone issues
      final dateUtc = date.toUtc();
      final now = DateTime.now().toUtc();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateOnly = DateTime(dateUtc.year, dateUtc.month, dateUtc.day);

      if (dateOnly == today) return 'Today';
      if (dateOnly == yesterday) return 'Yesterday';

      return DateFormat('MMM dd').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getStatusColorValue(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return _warningColor;
      case 'submitted':
        return _infoColor;
      case 'approved':
        return _successColor;
      default:
        return _textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.drafts_outlined;
      case 'submitted':
        return Icons.send_outlined;
      case 'approved':
        return Icons.check_circle_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Future<void> _deleteReport(EngineerReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 32,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Report?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone. Are you sure you want to delete "${report.title}"?',
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
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: _borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Deleting report...',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    final response = await ApiClient.deleteEngineerReport(report.id);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (response == null) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        _reports.removeWhere((r) => r.id == report.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report deleted successfully'),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (response.statusCode == 401) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      String errorMessage = 'Failed to delete report';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['error'] != null) {
          errorMessage = data['error'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
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
          'Daily Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      body: _buildBody(),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EngineerCreateReportScreen(),
              ),
            );
            if (result == true) {
              _fetchReports();
            }
          },
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: const Icon(Icons.add_rounded, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading reports...',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Error Loading Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchReports,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredReports = _getFilteredReports();

    return RefreshIndicator(
      onRefresh: _fetchReports,
      color: _primaryColor,
      backgroundColor: _surfaceColor,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildCalendar(),
                  _buildFilters(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (filteredReports.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: _textSecondary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No reports found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _selectedFilter == FilterType.today
                                ? 'Create your first report for today'
                                : _selectedFilter == FilterType.week
                                    ? 'No reports created this week'
                                    : 'No reports created this month',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EngineerCreateReportScreen(),
                              ),
                            );
                            if (result == true) {
                              _fetchReports();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Create New Report'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final report = filteredReports[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _buildReportCard(report),
                    );
                  },
                  childCount: filteredReports.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportCard(EngineerReport report) {
    final statusColor = _getStatusColorValue(report.status);

    return Material(
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
            _fetchReports();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with status and date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(report.status),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            report.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(report.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  report.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  report.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Footer with actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteReport(report),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Colors.red,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
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
}
