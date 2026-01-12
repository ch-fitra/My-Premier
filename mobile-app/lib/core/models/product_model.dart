class Product {
  final String id;
  final String name;
  final String brand;
  final String series;
  final List<String> images;
  final String? datasheetUrl;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.series,
    required this.images,
    this.datasheetUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages
          .where((e) => e != null)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Try a few common keys for datasheet link
    String? datasheet;
    if (json['datasheetUrl'] != null) {
      datasheet = json['datasheetUrl'].toString();
    } else if (json['datasheet'] != null) {
      datasheet = json['datasheet'].toString();
    } else if (json['datasheet_link'] != null) {
      datasheet = json['datasheet_link'].toString();
    }

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      series: (json['series'] ?? '').toString(),
      images: parsedImages,
      datasheetUrl: datasheet?.isNotEmpty == true ? datasheet : null,
    );
  }
}


