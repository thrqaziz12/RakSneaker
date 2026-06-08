// =============================================================================
// product_model.dart
// Model data produk dari API https://dummyjson.com/products
// =============================================================================

class ProductReview {
  final String reviewerName;
  final double rating;
  final String comment;
  final String date;

  const ProductReview({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      reviewerName: json['reviewerName'] as String? ?? 'Anonymous',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }
}

class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String category;
  final String thumbnail;
  final List<String> images;
  final List<ProductReview> reviews;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.category,
    required this.thumbnail,
    required this.images,
    this.reviews = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      brand: json['brand'] as String? ?? '-',
      category: json['category'] as String? ?? '-',
      thumbnail: json['thumbnail'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((e) => ProductReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Harga setelah diskon
  double get discountedPrice =>
      price * (1 - discountPercentage / 100);
}
