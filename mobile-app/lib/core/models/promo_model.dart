class Promo {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final bool isActive;

  Promo({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.isActive,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['image_url'] ?? '').toString().trim();
    final normalizedUrl = _normalizeImageUrl(rawUrl);

    return Promo(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: normalizedUrl,
      isActive: json['is_active'] == true,
    );
  }

  static String _normalizeImageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Backend already attempts to send absolute URLs; keep as-is to avoid double prefix.
    return url;
  }
}
