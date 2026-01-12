class EngineerReport {
  final String id;
  final String userEmail;
  final String title;
  final String description;
  final String? notes;
  final String status;
  final DateTime createdAt;

  EngineerReport({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.description,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory EngineerReport.fromJson(Map<String, dynamic> json) {
    return EngineerReport(
      id: (json['id'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      notes: json['notes'] != null ? json['notes'].toString() : null,
      status: (json['status'] ?? 'submitted').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }
}

