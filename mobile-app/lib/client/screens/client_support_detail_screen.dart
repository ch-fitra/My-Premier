import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_service.dart';
import '../../core/api_client.dart';
import '../../core/models/support_model.dart';

class ClientSupportDetailScreen extends StatefulWidget {
  final String supportId;

  const ClientSupportDetailScreen({
    super.key,
    required this.supportId,
  });

  @override
  State<ClientSupportDetailScreen> createState() =>
      _ClientSupportDetailScreenState();
}

class _ClientSupportDetailScreenState extends State<ClientSupportDetailScreen> {
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  SupportDetail? _supportDetail;
  List<SupportMessage> _messages = [];
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSupportDetail();
    _fetchMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSupportDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response =
        await ApiClient.getClientSupportDetail(widget.supportId);

    if (!mounted) return;

    if (response == null) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final detail =
            SupportDetail.fromJson(data as Map<String, dynamic>);
        setState(() {
          _supportDetail = detail;
          // Use messages from detail response if available
          if (detail.messages.isNotEmpty) {
            _messages = detail.messages;
          }
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Failed to parse support detail';
          _isLoading = false;
        });
      }
    } else if (response.statusCode == 403) {
      setState(() {
        _error = 'This action is not allowed for your role';
        _isLoading = false;
      });
    } else {
      setState(() {
        _error =
            'Failed to load support detail (code ${response.statusCode})';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMessages() async {
    final response =
        await ApiClient.getClientSupportMessages(widget.supportId);

    if (!mounted) return;

    if (response == null) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          final messages = data
              .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
              .toList();
          setState(() {
            _messages = messages;
          });
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
        // Keep existing messages, optionally show error
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

    final response = await ApiClient.sendClientSupportMessage(
      widget.supportId,
      message,
    );

    if (!mounted) return;

    if (response == null) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      _messageController.clear();
      setState(() {
        _isSending = false;
      });
      await _fetchMessages();
    } else if (response.statusCode == 403) {
      setState(() {
        _isSending = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This action is not allowed for your role'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      setState(() {
        _isSending = false;
      });

      String errorMessage = 'Failed to send message';
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return date.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _supportDetail != null
            ? Text(
                _supportDetail!.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : const Text('Support Detail'),
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
                onPressed: () async {
                  await _fetchSupportDetail();
                  await _fetchMessages();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_supportDetail == null) {
      return const Center(
        child: Text('No support detail found'),
      );
    }

    final support = _supportDetail!;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      support.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(support.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(support.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(support.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  support.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(support.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No messages yet',
                        style: TextStyle(fontSize: 16),
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
                    final isClient = message.sender == 'client';
                    final isSales = message.sender == 'sales';
                    final isAdmin = message.sender == 'admin';

                    Color avatarColor;
                    String senderLabel;
                    if (isClient) {
                      avatarColor = Colors.orange;
                      senderLabel = 'You';
                    } else if (isSales) {
                      avatarColor = Colors.green;
                      senderLabel = 'Sales';
                    } else if (isAdmin) {
                      avatarColor = Colors.blue;
                      senderLabel = 'Admin';
                    } else {
                      avatarColor = Colors.grey;
                      senderLabel = message.sender;
                    }

                    final isMine = isClient;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: isMine
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMine) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: avatarColor,
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    senderLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? Colors.blue
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    message.message,
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(message.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: avatarColor,
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
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
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


