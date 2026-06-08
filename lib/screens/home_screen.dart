// =============================================================================
// home_screen.dart
// Halaman utama setelah user berhasil login ke aplikasi RakSneaker.
//
// Fitur:
//   - Menampilkan sapaan dengan nama username yang sedang login
//   - Daftar produk sepatu dari https://dummyjson.com/products
//   - Loading skeleton saat data sedang diambil
//   - Error state dengan tombol retry
//   - Tombol logout untuk kembali ke halaman LoginScreen
//
// Tema Warna (Light Mode — Sneaker Collection Theme):
//   - Primary Accent : #FF6B35 (Oranye Sneaker)
//   - Background     : #FFF8F5 (Putih Hangat)
//   - Surface/AppBar : #FFFFFF (Putih)
//   - Text Utama     : #1A1A1A (Hampir Hitam)
//   - Text Muted     : #6B6B6B (Abu)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'login_screen.dart';

// ---------------------------------------------------------------------------
// Konstanta Warna — Light Sneaker Theme
// ---------------------------------------------------------------------------
const kPrimaryColor = Color(0xFFFF6B35);
const kPrimaryDark = Color(0xFFD94F1A);
const kBgLight = Color(0xFFFFF8F5);
const kSurfaceLight = Color(0xFFFFFFFF);
const kSurfaceAccent = Color(0xFFFFF0E8);
const kTextPrimary = Color(0xFF1A1A1A);
const kTextMuted = Color(0xFF6B6B6B);
const kTextFaint = Color(0xFFB0B0B0);
const kBorderColor = Color(0xFFE8E0DB);

// ---------------------------------------------------------------------------
// HomeScreen — StatefulWidget (butuh state untuk loading produk)
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.fetchProducts(limit: 30);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat produk. Periksa koneksi internet Anda.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _loadProducts,
        child: CustomScrollView(
          slivers: [
            // ----------------------------------------------------------------
            // Header — sapaan user
            // ----------------------------------------------------------------
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            // ----------------------------------------------------------------
            // Label seksi produk
            // ----------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Koleksi Produk',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (!_isLoading && _errorMessage == null)
                      Text(
                        '${_products.length} produk',
                        style: const TextStyle(
                          color: kTextMuted,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ----------------------------------------------------------------
            // Konten utama: loading / error / grid produk
            // ----------------------------------------------------------------
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => _SkeletonCard(),
                    childCount: 6,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: _buildErrorState(),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => _ProductCard(product: _products[index]),
                    childCount: _products.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // AppBar
  // --------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kSurfaceLight,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kBorderColor),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C5A), Color(0xFFFF6B35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(MdiIcons.shoeSneaker,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'RakSneaker',
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: kTextMuted),
          tooltip: 'Logout',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Header sapaan
  // --------------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C5A), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Teks sapaan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hei, selamat datang 👟',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            MdiIcons.shoeSneaker,
            color: Colors.white.withValues(alpha: 0.5),
            size: 36,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Error state
  // --------------------------------------------------------------------------
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: kTextFaint,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              style: const TextStyle(
                color: kTextMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProductCard — card satu produk
// ---------------------------------------------------------------------------
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceLight,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0x1AFF6B35), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0AFF6B35),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Thumbnail ----
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  product.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: kSurfaceAccent,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: kTextFaint,
                      size: 32,
                    ),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: kSurfaceAccent,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimaryColor,
                        ),
                      ),
                    );
                  },
                ),
                // Badge diskon
                if (product.discountPercentage > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${product.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---- Info ----
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  Text(
                    product.brand.toUpperCase(),
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Nama produk
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFC107),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: kTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Harga
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${product.discountedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: kPrimaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.discountPercentage > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '\$${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: kTextFaint,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SkeletonCard — shimmer placeholder saat loading
// ---------------------------------------------------------------------------
class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEDE8E3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              // Gambar placeholder
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0DAD5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                ),
              ),
              // Teks placeholder
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(0.5, 8),
                    const SizedBox(height: 6),
                    _bar(1.0, 12),
                    const SizedBox(height: 4),
                    _bar(0.7, 12),
                    const SizedBox(height: 10),
                    _bar(0.4, 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(double widthFactor, double height) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFD5CFC9),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
