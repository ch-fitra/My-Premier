import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/promo_model.dart';
import '../../core/models/user_model.dart';
import 'client_about_screen.dart';
import 'client_products_screen.dart';
import 'client_requests_list_screen.dart';
import 'client_support_list_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  final UserModel user;

  const ClientHomeScreen({super.key, required this.user});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  bool _isLoading = true;
  String? _error;

  List<Promo> _promos = [];
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();

    if (!widget.user.isClient) {
      _error = 'This dashboard is only available for client accounts.';
      _isLoading = false;
      return;
    }

    _startAutoScroll();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_promos.isEmpty) return;
      if (_currentPage < _promos.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiClient.getClientPromos(),
        ApiClient.getClientRequests(),
        ApiClient.getClientSupports(),
      ]);

      final promosResponse = results[0];
      final requestsResponse = results[1];
      final supportsResponse = results[2];

      if (promosResponse == null ||
          requestsResponse == null ||
          supportsResponse == null) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }

      if (promosResponse.statusCode == 200) {
        final data = jsonDecode(promosResponse.body);
        if (data is List) {
          _promos = data
              .map((e) => Promo.fromJson(e as Map<String, dynamic>))
              .where((p) => p.isActive)
              .toList();
        }
      }

      final List<Map<String, dynamic>> activities = [];

      if (requestsResponse.statusCode == 200) {
        final data = jsonDecode(requestsResponse.body);
        if (data is List) {
          for (final item in data) {
            final map = item as Map<String, dynamic>;
            activities.add({
              'type': 'request',
              'title': map['product_name'] ?? 'Request',
              'status': map['status'] ?? '',
              'created_at': map['created_at'] ?? '',
            });
          }
        }
      }

      if (supportsResponse.statusCode == 200) {
        final data = jsonDecode(supportsResponse.body);
        if (data is List) {
          for (final item in data) {
            final map = item as Map<String, dynamic>;
            activities.add({
              'type': 'support',
              'title': map['subject'] ?? 'Support Ticket',
              'status': map['status'] ?? '',
              'created_at': map['created_at'] ?? '',
            });
          }
        }
      }

      activities.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['created_at'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _recentActivities = activities.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/premier.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Premier',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Client Portal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.white70 : Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: isDarkMode ? Colors.white : Color(0xFF475569)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Color(0xFFEFF6FF),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Color(0xFFCBD5E1),
                ),
              ),
              child: Icon(
                Icons.person_outline,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDashboardData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPromotionCarousel(theme, isDarkMode),
                      const SizedBox(height: 24),
                      _buildQuickActionsSection(theme, isDarkMode),
                      const SizedBox(height: 24),
                      _buildRecentActivitySection(theme, isDarkMode),
                      const SizedBox(height: 24),
                      _buildCompanyInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPromotionCarousel(ThemeData theme, bool isDarkMode) {
    if (_promos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promotions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No promotions are available at the moment. Please check again later.',
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _promos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (promo.imageUrl.isNotEmpty)
                      Image.network(
                        promo.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDarkMode
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade200,
                          );
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(promo.title),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (promo.imageUrl.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              promo.imageUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return SizedBox(
                                                  height: 150,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  height: 150,
                                                  color: Colors.grey.shade200,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      Text(promo.description),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promos.length,
            (index) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Color(0xFF3B82F6)
                    : Color(0xFFCBD5E1).withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: isDarkMode ? Colors.white : Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildQuickAccessCard(
                icon: Icons.inventory_2_outlined,
                title: 'Products',
                subtitle: 'Browse catalog',
                color: Color(0xFF10B981),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ClientProductsScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
              _buildQuickAccessCard(
                icon: Icons.list_alt_outlined,
                title: 'Create Request',
                subtitle: 'New product inquiry',
                color: Color(0xFF3B82F6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ClientRequestsListScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
              _buildQuickAccessCard(
                icon: Icons.headset_mic_outlined,
                title: 'Create Ticket',
                subtitle: 'Contact our team',
                color: Color(0xFFF59E0B),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ClientSupportListScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
              _buildQuickAccessCard(
                icon: Icons.business_outlined,
                title: 'About Us',
                subtitle: 'Company profile',
                color: Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ClientAboutScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF334155) : Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
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
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Color(0xFF94A3B8) : Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_recentActivities.isEmpty)
            const Text(
              'You have no recent activity yet. Create a request or support ticket to get started.',
            )
          else
            Column(
              children: _recentActivities
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityItem(
                        icon: a['type'] == 'request'
                            ? Icons.list_alt_outlined
                            : Icons.headset_mic_outlined,
                        title: a['title'] ?? '',
                        subtitle: a['status'] ?? '',
                        time: a['created_at'] ?? '',
                        color: a['type'] == 'request'
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFF59E0B),
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDarkMode ? Color(0xFF94A3B8) : Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            color: isDarkMode ? Color(0xFF94A3B8) : Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyInfoCard() {
    return InkWell(
      onTap: () => _showCompanyCardDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D1B48),
              Color(0xFF1A237E),
              Color(0xFF283593),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF1A237E).withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 90,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/premier.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PT Premier Engineering Indonesia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Since 2005',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Leading Contractor & Supplier in Industrial Solutions',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 0,
              children: [
                _buildContactChip(
                  icon: Icons.phone_outlined,
                  text: '+62 21 1234 5678',
                ),
                _buildContactChip(
                  icon: Icons.email_outlined,
                  text: 'info@premier-engineering.co.id',
                ),
                _buildContactChip(
                  icon: Icons.location_on_outlined,
                  text: 'Jakarta, Indonesia',
                ),
                _buildContactChip(
                  icon: Icons.language_outlined,
                  text: 'www.premier-engineering.co.id',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompanyCardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CompanyCardDialog(),
    );
  }

  Widget _buildContactChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyCardDialog extends StatefulWidget {
  @override
  State<_CompanyCardDialog> createState() => _CompanyCardDialogState();
}

class _CompanyCardDialogState extends State<_CompanyCardDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _printCard() async {
    try {
      final pdf = await _createPdf();
      await Printing.layoutPdf(
        onLayout: (format) async => pdf,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e')),
        );
      }
    }
  }

  Future<Uint8List> _createPdf() async {
    final pdf = pw.Document();

    // Front side
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(85.6 * 72 / 25.4,
            53.98 * 72 / 25.4), // Credit card size in mm (converted to points)
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromHex('#0D1B48'),
                  PdfColor.fromHex('#1A237E'),
                  PdfColor.fromHex('#283593'),
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'PT Premier Engineering Indonesia',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Since 2005',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Leading Contractor & Supplier in Industrial Solutions',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Back side
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(85.6 * 72 / 25.4,
            53.98 * 72 / 25.4), // Credit card size in mm (converted to points)
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Contact Information',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Phone: +62 21 1234 5678',
                    style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 6),
                pw.Text('Email: info@premier-engineering.co.id',
                    style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 6),
                pw.Text('Address: Jakarta, Indonesia',
                    style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 6),
                pw.Text('Website: www.premier-engineering.co.id',
                    style: pw.TextStyle(fontSize: 9)),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        height: 500,
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Company Card',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Card pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildCardFront(),
                  _buildCardBack(),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(0),
                SizedBox(width: 8),
                _buildPageIndicator(1),
              ],
            ),
            SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_currentPage == 0) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  icon: Icon(_currentPage == 0
                      ? Icons.arrow_forward
                      : Icons.arrow_back),
                  label: Text(_currentPage == 0 ? 'Back Side' : 'Front Side'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _printCard,
                  icon: Icon(Icons.print),
                  label: Text('Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.blue : Colors.grey,
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D1B48),
            Color(0xFF1A237E),
            Color(0xFF283593),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 90,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/premier.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PT Premier Engineering Indonesia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Since 2005',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Leading Contractor & Supplier in Industrial Solutions',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 0,
            children: [
              _buildContactChip(
                icon: Icons.phone_outlined,
                text: '+62 21 1234 5678',
              ),
              _buildContactChip(
                icon: Icons.email_outlined,
                text: 'info@premier-engineering.co.id',
              ),
              _buildContactChip(
                icon: Icons.location_on_outlined,
                text: 'Jakarta, Indonesia',
              ),
              _buildContactChip(
                icon: Icons.language_outlined,
                text: 'www.premier-engineering.co.id',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return AspectRatio(
      aspectRatio: 85.6 / 53.98, // Standard business card ratio
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D1B48),
              Color(0xFF1A237E),
              Color(0xFF283593),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF1A237E).withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo di tengah
            Container(
              width: 80,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/premier.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'PT Premier Engineering Indonesia is a leading contractor and supplier specializing in industrial solutions. With over 18 years of experience since 2005, we provide comprehensive engineering services and high-quality industrial products to meet your business needs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 9,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business_outlined,
                    color: Colors.white.withOpacity(0.9),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Committed to Excellence in Industrial Solutions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
