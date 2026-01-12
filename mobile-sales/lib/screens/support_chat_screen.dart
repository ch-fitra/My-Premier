import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SupportChatScreen extends StatefulWidget {
  final String supportId;

  const SupportChatScreen({
    super.key,
    required this.supportId,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  List<dynamic> _messages = [];
  Map<String, dynamic>? _supportInfo;
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load support info
    final supports = await ApiService.getSupports();
    if (supports != null) {
      final support = supports.firstWhere(
        (s) => s['id'].toString() == widget.supportId,
        orElse: () => null,
      );
      if (support != null) {
        setState(() {
          _supportInfo = support;
        });
      }
    }

    // Load messages
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ApiService.getSupportMessages(widget.supportId);
      if (mounted) {
        // Sort messages by created_at (oldest first for chat display)
        final sortedMessages = List.from(messages ?? []);
        sortedMessages.sort((a, b) {
          final dateA = a['created_at'] ?? '';
          final dateB = b['created_at'] ?? '';
          try {
            return DateTime.parse(dateA).compareTo(DateTime.parse(dateB));
          } catch (e) {
            return 0;
          }
        });
        
        setState(() {
          _messages = sortedMessages;
          _isLoading = false;
        });
        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final result = await ApiService.replyToSupport(
        widget.supportId,
        message,
      );

      if (result != null && mounted) {
        _messageController.clear();
        await _loadMessages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${widget.supportId}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Support info card
          if (_supportInfo != null) _buildSupportInfoCard(),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet. Start the conversation!',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          // Message input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      color: Colors.blue,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportInfoCard() {
    final status = _supportInfo!['status'] ?? 'unknown';
    final data = _supportInfo!['data'] as Map<String, dynamic>? ?? {};
    final issueType = data['issue_type'] ?? 'General';
    final description = data['description'] ?? 'No description';
    final createdAt = _supportInfo!['created_at'] ?? '';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'open':
        statusColor = Colors.orange;
        break;
      case 'pending':
        statusColor = Colors.blue;
        break;
      case 'closed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Issue Type: $issueType',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final senderType = message['sender_type'] ?? 'client';
    final messageText = message['message'] ?? '';
    final createdAt = message['created_at'] ?? '';
    // Sales messages should appear on the right (same as admin)
    final isSales = senderType == 'sales' || senderType == 'admin';

    return Align(
      alignment: isSales ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSales ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              messageText,
              style: TextStyle(
                color: isSales ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(createdAt),
                style: TextStyle(
                  color: isSales
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
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

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

