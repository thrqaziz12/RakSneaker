// =============================================================================
// product_service.dart
// Service untuk mengambil data produk dari https://dummyjson.com/products
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  static const String _baseUrl = 'https://dummyjson.com';

  /// Mengambil semua produk (limit default 30)
  Future<List<Product>> fetchProducts({int limit = 30, int skip = 0}) async {
    final uri = Uri.parse(
      '$_baseUrl/products?limit=$limit&skip=$skip',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> productsJson = data['products'] as List<dynamic>;
      return productsJson
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Gagal memuat produk. Status: ${response.statusCode}');
    }
  }
}
