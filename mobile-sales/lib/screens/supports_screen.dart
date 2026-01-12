import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'support_chat_screen.dart';

class SupportsScreen extends StatefulWidget {
  const SupportsScreen({super.key});

  @override
  State<SupportsScreen> createState() => _SupportsScreenState();
}

class _SupportsScreenState extends State<SupportsScreen> {
  List<dynamic> _supports = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSupports();
  }

  Future<void> _loadSupports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supports = await ApiService.getSupports();
      if (mounted) {
        setState(() {
          _supports = supports ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load supports';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredSupports {
    var filtered = _supports;

    // Apply status filter
    if (_statusFilter != 'all') {
      filtered = filtered.where((support) {
        final status = (support['status'] ?? '').toLowerCase();
        return status == _statusFilter.toLowerCase();
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((support) {
        final id = (support['id'] ?? '').toString().toLowerCase();
        final data = support['data'] as Map<String, dynamic>? ?? {};
        final issueType = (data['issue_type'] ?? '').toLowerCase();
        final description = (data['description'] ?? '').toLowerCase();
        
        return id.contains(query) ||
            issueType.contains(query) ||
            description.contains(query);
      }).toList();
    }

    // Sort by created_at (newest first)
    filtered.sort((a, b) {
      final dateA = a['created_at'] ?? '';
      final dateB = b['created_at'] ?? '';
      try {
        return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
      } catch (e) {
        return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by ticket ID, issue type...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('open', 'Open'),
                      const SizedBox(width: 8),
                      _buildFilterChip('pending', 'Pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('closed', 'Closed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSupports,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredSupports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.support_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty ||
                                          _statusFilter != 'all'
                                      ? 'No supports found'
                                      : 'No supports yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSupports,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredSupports.length,
                              itemBuilder: (context, index) {
                                final support = _filteredSupports[index];
                                return _buildSupportCard(support);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildSupportCard(Map<String, dynamic> support) {
    final id = support['id'] ?? 'N/A';
    final status = support['status'] ?? 'unknown';
    final createdAt = support['created_at'] ?? '';
    final data = support['data'] as Map<String, dynamic>? ?? {};
    final issueType = data['issue_type'] ?? 'General';
    final description = data['description'] ?? 'No description';

    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'open':
        statusColor = Colors.orange;
        statusIcon = Icons.chat_bubble_outline;
        break;
      case 'pending':
        statusColor = Colors.blue;
        statusIcon = Icons.access_time;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          'Ticket #$id',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Type: $issueType',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              description.length > 50
                  ? '${description.substring(0, 50)}...'
                  : description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SupportChatScreen(supportId: id.toString()),
            ),
          );
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

