class Support {
  final String id;
  final String userEmail;
  final String subject;
  final String status;
  final String createdAt;

  Support({
    required this.id,
    required this.userEmail,
    required this.subject,
    required this.status,
    required this.createdAt,
  });

  factory Support.fromJson(Map<String, dynamic> json) {
    return Support(
      id: (json['id'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(), // Default to 'pending' if not provided
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class SupportDetail {
  final String id;
  final String subject;
  final String status;
  final DateTime createdAt;
  final List<SupportMessage> messages;

  SupportDetail({
    required this.id,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.messages,
  });

  factory SupportDetail.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];

    return SupportDetail(
      id: (json['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      messages: messagesJson
          .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SupportMessage {
  final String id;
  final String sender; // 'client', 'sales', or 'admin'
  final String message;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: (json['id'] ?? '').toString(),
      sender: (json['sender'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

