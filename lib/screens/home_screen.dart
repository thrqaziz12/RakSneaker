// =============================================================================
// home_screen.dart
// Halaman utama setelah user berhasil login ke aplikasi RakSneaker.
//
// Fitur:
//   - Menampilkan sapaan dengan nama username yang sedang login
//   - Daftar produk sepatu dari dummyjson (mens-shoes + womens-shoes)
//   - Card menampilkan: thumbnail, title, category, price
//   - Klik card → navigasi ke ProductDetailScreen
//   - Loading skeleton saat data sedang diambil
//   - Error state dengan tombol retry
//   - FAB pojok kanan bawah → akses Sneaker Tilt Maze mini game
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
import 'product_detail_screen.dart';
import 'sneaker_maze_game_screen.dart';

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
      final products = await _productService.fetchShoeProducts();
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
      floatingActionButton: _buildGameFAB(),
      body: RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _loadProducts,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => _SkeletonCard(),
                    childCount: 6,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(child: _buildErrorState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => _ProductCard(
                      product: _products[index],
                      onTap: () => _navigateToDetail(_products[index]),
                    ),
                    childCount: _products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Floating Action Button — Akses Mini Game Sneaker Tilt Maze
  // --------------------------------------------------------------------------
  Widget _buildGameFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SneakerMazeGameScreen(),
          ),
        );
      },
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Text('\u{1F579}', style: TextStyle(fontSize: 18)),
      label: const Text(
        'Mini Game',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  void _navigateToDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
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
            child: Icon(MdiIcons.shoeSneaker, color: Colors.white, size: 18),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hei, selamat datang \u{1F45F}',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kSurfaceAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: kPrimaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: const TextStyle(
                color: kTextMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
                  borderRadius: BorderRadius.circular(12),
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
// _ProductCard — Card produk sneaker
// ---------------------------------------------------------------------------
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  String _formatCategory(String cat) {
    return cat
        .split('-')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSurfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x1AFF6B35), width: 1),
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
              aspectRatio: 1.1,
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
                ],
              ),
            ),

            // ---- Info: title, category ----
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      product.title,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kSurfaceAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatCategory(product.category),
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1.1,
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
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _bar(1.0, 11),
                    const SizedBox(height: 4),
                    _bar(0.7, 11),
                    const SizedBox(height: 6),
                    _bar(0.5, 14),
                    const SizedBox(height: 4),
                    _bar(0.4, 13),
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
