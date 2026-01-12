import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'requests_screen.dart';
import 'supports_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<dynamic> _requests = [];
  List<dynamic> _supports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final requests = await ApiService.getRequests();
    final supports = await ApiService.getSupports();

    setState(() {
      _requests = requests ?? [];
      _supports = supports ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Premier Sales'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_outlined),
            selectedIcon: Icon(Icons.support),
            label: 'Supports',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const RequestsScreen();
      case 2:
        return const SupportsScreen();
      case 3:
        return const ProductsScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final totalRequests = _requests.length;
    final totalSupports = _supports.length;
    final openSupports = _supports
        .where((s) => s['status'] == 'open' || s['status'] == 'pending')
        .length;

    // Get latest requests (last 5, sorted by created_at descending)
    final sortedRequests = List.from(_requests);
    sortedRequests.sort((a, b) {
      final dateA = a['created_at'] ?? '';
      final dateB = b['created_at'] ?? '';
      try {
        return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
      } catch (e) {
        return 0;
      }
    });
    final latestRequests = sortedRequests.length > 5
        ? sortedRequests.sublist(0, 5)
        : sortedRequests;

    // Get latest supports (last 5, sorted by created_at descending)
    final sortedSupports = List.from(_supports);
    sortedSupports.sort((a, b) {
      final dateA = a['created_at'] ?? '';
      final dateB = b['created_at'] ?? '';
      try {
        return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
      } catch (e) {
        return 0;
      }
    });
    final latestSupports = sortedSupports.length > 5
        ? sortedSupports.sublist(0, 5)
        : sortedSupports;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Requests',
                    totalRequests.toString(),
                    Icons.request_quote,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Supports',
                    totalSupports.toString(),
                    Icons.support,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Open Supports',
                    openSupports.toString(),
                    Icons.chat_bubble_outline,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Closed Supports',
                    (totalSupports - openSupports).toString(),
                    Icons.check_circle_outline,
                    Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Latest Requests
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (latestRequests.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No requests yet'),
                  ),
                ),
              )
            else
              ...latestRequests.map((request) => _buildRequestCard(request)),
            const SizedBox(height: 24),

            // Latest Supports
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Supports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (latestSupports.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No supports yet'),
                  ),
                ),
              )
            else
              ...latestSupports.map((support) => _buildSupportCard(support)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final data = request['data'] as Map<String, dynamic>? ?? {};
    final productName = data['product_name'] ?? 'N/A';
    final userEmail = request['user_email'] ?? 'N/A';
    final createdAt = request['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.request_quote, color: Colors.white),
        ),
        title: Text(
          productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: $userEmail'),
            if (createdAt.isNotEmpty)
              Text(
                _formatDate(createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
    );
  }

  Widget _buildSupportCard(Map<String, dynamic> support) {
    final id = support['id'] ?? 'N/A';
    final status = support['status'] ?? 'unknown';
    final createdAt = support['created_at'] ?? '';
    final data = support['data'] as Map<String, dynamic>? ?? {};
    final issueType = data['issue_type'] ?? 'General';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'open':
        statusColor = Colors.orange;
        break;
      case 'closed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
          status.toLowerCase() == 'closed' ? Icons.check_circle : Icons.chat,
          color: statusColor,
        ),
        ),
        title: Text(
          'Ticket #$id',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: $issueType'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

