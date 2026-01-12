class SalesRequest {
  final String id;
  final String userEmail;
  final String productName;
  final String message;
  final String status;
  final String createdAt;

  SalesRequest({
    required this.id,
    required this.userEmail,
    required this.productName,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory SalesRequest.fromJson(Map<String, dynamic> json) {
    return SalesRequest(
      id: (json['id'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

