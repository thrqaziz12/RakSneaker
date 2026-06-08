// =============================================================================
// product_detail_screen.dart
// Halaman detail produk — ditampilkan saat user mengetuk card di HomeScreen.
//
// Data di-fetch ulang dari API berdasarkan productId agar mendapat
// data lengkap termasuk reviews.
//
// Menampilkan:
//   - Galeri gambar (swipeable PageView)
//   - Title, brand, category
//   - Rating bintang + nilai
//   - Harga (dengan coret jika ada diskon)
//   - Deskripsi produk
//   - Daftar reviews
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

// ---------------------------------------------------------------------------
// Konstanta Warna (sama dengan home_screen)
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFFFF6B35);
const _kPrimaryDark = Color(0xFFD94F1A);
const _kBg = Color(0xFFFFF8F5);
const _kSurface = Color(0xFFFFFFFF);
const _kSurfaceAccent = Color(0xFFFFF0E8);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextMuted = Color(0xFF6B6B6B);
const _kTextFaint = Color(0xFFB0B0B0);
const _kBorder = Color(0xFFE8E0DB);
const _kStar = Color(0xFFFFC107);

// ---------------------------------------------------------------------------
// ProductDetailScreen
// ---------------------------------------------------------------------------
class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final uri = Uri.parse(
          'https://dummyjson.com/products/${widget.productId}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _product = Product.fromJson(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat detail produk.';
        _isLoading = false;
      });
    }
  }

  String _formatCategory(String cat) {
    return cat
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
              ? _buildError()
              : _buildContent(),
    );
  }

  // --------------------------------------------------------------------------
  // Loading
  // --------------------------------------------------------------------------
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: _kPrimary),
    );
  }

  // --------------------------------------------------------------------------
  // Error
  // --------------------------------------------------------------------------
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: _kTextFaint, size: 56),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              style: const TextStyle(color: _kTextMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchProduct,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali',
                  style: TextStyle(color: _kTextMuted)),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Konten utama
  // --------------------------------------------------------------------------
  Widget _buildContent() {
    final p = _product!;
    return CustomScrollView(
      slivers: [
        // ----------------------------------------------------------------
        // SliverAppBar dengan galeri gambar
        // ----------------------------------------------------------------
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          backgroundColor: _kSurface,
          surfaceTintColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kTextPrimary, size: 18),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(p.images),
          ),
        ),

        // ----------------------------------------------------------------
        // Body detail produk
        // ----------------------------------------------------------------
        SliverToBoxAdapter(
          child: Container(
            color: _kBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dots indikator gambar
                if (p.images.length > 1)
                  _buildImageDots(p.images.length),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand + Category row
                      Row(
                        children: [
                          if (p.brand.isNotEmpty && p.brand != '-') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _kPrimary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.brand.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kSurfaceAccent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _kPrimary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _formatCategory(p.category),
                              style: const TextStyle(
                                color: _kPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        p.title,
                        style: const TextStyle(
                          color: _kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Rating
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final full = i < p.rating.floor();
                            final half = !full &&
                                i < p.rating &&
                                (p.rating - p.rating.floor()) >= 0.5;
                            return Icon(
                              full
                                  ? Icons.star_rounded
                                  : half
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded,
                              color: _kStar,
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: _kTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${p.reviews.length} ulasan)',
                            style: const TextStyle(
                              color: _kTextMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Harga
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _kSurfaceAccent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _kPrimary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '\$${p.discountedPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: _kPrimaryDark,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (p.discountPercentage > 0) ...[
                              const SizedBox(width: 10),
                              Text(
                                '\$${p.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: _kTextFaint,
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _kPrimary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${p.discountPercentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Container(height: 1, color: _kBorder),
                      const SizedBox(height: 20),

                      // Deskripsi
                      const Text(
                        'Deskripsi',
                        style: TextStyle(
                          color: _kTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.description,
                        style: const TextStyle(
                          color: _kTextMuted,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reviews
                      if (p.reviews.isNotEmpty) ...[
                        Container(height: 1, color: _kBorder),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text(
                              'Ulasan',
                              style: TextStyle(
                                color: _kTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kSurfaceAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${p.reviews.length}',
                                style: const TextStyle(
                                  color: _kPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...p.reviews.map((r) => _ReviewCard(
                              review: r,
                              formatDate: _formatDate,
                            )),
                        const SizedBox(height: 32),
                      ] else ...[
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Galeri gambar dengan PageView
  // --------------------------------------------------------------------------
  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: _kSurfaceAccent,
        child: const Icon(Icons.image_not_supported_outlined,
            color: _kTextFaint, size: 64),
      );
    }
    return PageView.builder(
      itemCount: images.length,
      onPageChanged: (i) => setState(() => _currentImageIndex = i),
      itemBuilder: (_, i) {
        return Image.network(
          images[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: _kSurfaceAccent,
            child: const Icon(Icons.image_not_supported_outlined,
                color: _kTextFaint, size: 64),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: _kSurfaceAccent,
              child: const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Dots indikator halaman gambar
  // --------------------------------------------------------------------------
  Widget _buildImageDots(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == _currentImageIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? _kPrimary : _kTextFaint,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ReviewCard — satu card ulasan
// ---------------------------------------------------------------------------
class _ReviewCard extends StatelessWidget {
  final ProductReview review;
  final String Function(String) formatDate;

  const _ReviewCard({required this.review, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar inisial
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kSurfaceAccent,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    review.reviewerName.isNotEmpty
                        ? review.reviewerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        color: _kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (review.date.isNotEmpty)
                      Text(
                        formatDate(review.date),
                        style: const TextStyle(
                          color: _kTextFaint,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // Bintang rating
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFC107),
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: const TextStyle(
              color: _kTextMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
