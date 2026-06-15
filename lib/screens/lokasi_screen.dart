// =============================================================================
// lokasi_screen.dart
// Menampilkan Google Maps, lokasi pengguna, dan pencarian toko sepatu.
// Menggunakan Google Maps SDK for Android + Geolocation API + Places API (New).
// API Key: AIzaSyCVBa61HvhOJ0IBUrUXbHuVW3hqaqH9xMc
// =============================================================================

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const kPrimaryColor = Color(0xFFFF6B35);
const kBgLight = Color(0xFFFFF8F5);
const kSurfaceLight = Color(0xFFFFFFFF);
const kTextPrimary = Color(0xFF1A1A1A);
const kTextMuted = Color(0xFF6B6B6B);
const kBorderColor = Color(0xFFE8E0DB);
const kGoogleApiKey = 'AIzaSyCVBa61HvhOJ0IBUrUXbHuVW3hqaqH9xMc';

// ── Model untuk hasil pencarian tempat ──────────────────────────────────────
class PlaceResult {
  final String placeId;
  final String name;
  final String address;
  final LatLng latLng;
  final double? rating;
  final bool isOpen;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latLng,
    this.rating,
    required this.isOpen,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] ?? {};
    return PlaceResult(
      placeId: json['id'] ?? '',
      name: json['displayName']?['text'] ?? 'Tanpa Nama',
      address: json['formattedAddress'] ?? '',
      latLng: LatLng(
        (loc['latitude'] as num?)?.toDouble() ?? 0.0,
        (loc['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      rating: (json['rating'] as num?)?.toDouble(),
      isOpen: json['regularOpeningHours']?['openNow'] ?? false,
    );
  }
}

// ── Buat LocationSettings sesuai platform ───────────────────────────────────
LocationSettings _buildLocationSettings() {
  if (Platform.isAndroid) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      forceLocationManager: false,
    );
  } else if (Platform.isIOS || Platform.isMacOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.other,
      pauseLocationUpdatesAutomatically: true,
    );
  } else {
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }
}

class LokasiScreen extends StatefulWidget {
  const LokasiScreen({super.key});

  @override
  State<LokasiScreen> createState() => _LokasiScreenState();
}

class _LokasiScreenState extends State<LokasiScreen> {
  GoogleMapController? _mapController;
  LatLng? _posisiSaya;
  bool _loadingLokasi = true;
  bool _loadingCari = false;
  final Set<Marker> _markers = {};
  List<PlaceResult> _hasilCari = [];
  int? _selectedIndex;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Pusat peta default: Yogyakarta
  static const LatLng _pusatDefault = LatLng(-7.7956, 110.3695);

  @override
  void initState() {
    super.initState();
    _ambilLokasi();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Ambil lokasi pengguna ────────────────────────────────────────────────
  Future<void> _ambilLokasi() async {
    setState(() => _loadingLokasi = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _tampilkanPesan('Layanan lokasi dinonaktifkan. Aktifkan GPS terlebih dahulu.');
        setState(() => _loadingLokasi = false);
        return;
      }

      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
        if (izin == LocationPermission.denied) {
          _tampilkanPesan('Izin lokasi ditolak.');
          setState(() => _loadingLokasi = false);
          return;
        }
      }
      if (izin == LocationPermission.deniedForever) {
        _tampilkanPesan('Izin lokasi ditolak permanen. Buka Pengaturan untuk mengaktifkan.');
        setState(() => _loadingLokasi = false);
        return;
      }

      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );
      final latLng = LatLng(posisi.latitude, posisi.longitude);

      final markerSaya = Marker(
        markerId: const MarkerId('lokasi_saya'),
        position: latLng,
        infoWindow: const InfoWindow(
          title: 'Lokasi Saya',
          snippet: 'Posisi Anda saat ini',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );

      setState(() {
        _posisiSaya = latLng;
        _loadingLokasi = false;
        _markers.removeWhere((m) => m.markerId.value == 'lokasi_saya');
        _markers.add(markerSaya);
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 15.0),
        ),
      );
    } catch (e) {
      _tampilkanPesan('Gagal mendapatkan lokasi: $e');
      setState(() => _loadingLokasi = false);
    }
  }

  // ── Cari toko sepatu menggunakan Places API (New) - Text Search ──────────
  Future<void> _cariTokoSepatu(String query) async {
    if (query.trim().isEmpty) return;

    _searchFocus.unfocus();
    setState(() {
      _loadingCari = true;
      _hasilCari = [];
      _selectedIndex = null;
      // Hapus marker toko sebelumnya (kecuali lokasi pengguna)
      _markers.removeWhere((m) => m.markerId.value != 'lokasi_saya');
    });

    try {
      final center = _posisiSaya ?? _pusatDefault;

      // Places API (New) - Text Search endpoint
      final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');

      final body = jsonEncode({
        'textQuery': query,
        'locationBias': {
          'circle': {
            'center': {
              'latitude': center.latitude,
              'longitude': center.longitude,
            },
            'radius': 10000.0, // 10 km radius
          },
        },
        'maxResultCount': 20,
        'languageCode': 'id',
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': kGoogleApiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.regularOpeningHours',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final places = (data['places'] as List<dynamic>? ?? []);
        final hasil = places.map((p) => PlaceResult.fromJson(p)).toList();

        // Buat marker untuk setiap toko
        final markerBaru = <Marker>{};
        for (int i = 0; i < hasil.length; i++) {
          final toko = hasil[i];
          markerBaru.add(
            Marker(
              markerId: MarkerId(toko.placeId),
              position: toko.latLng,
              infoWindow: InfoWindow(
                title: toko.name,
                snippet: toko.address,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              onTap: () {
                setState(() => _selectedIndex = i);
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(toko.latLng, 16),
                );
              },
            ),
          );
        }

        setState(() {
          _hasilCari = hasil;
          _markers.addAll(markerBaru);
          _loadingCari = false;
        });

        // Fit kamera ke semua marker hasil pencarian
        if (hasil.isNotEmpty) {
          _fitBoundsToResults(hasil);
        } else {
          _tampilkanPesan('Tidak ditemukan toko sepatu dengan kata kunci "$query"');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? 'Terjadi kesalahan API';
        _tampilkanPesan('Error ${response.statusCode}: $errorMsg');
        setState(() => _loadingCari = false);
      }
    } catch (e) {
      _tampilkanPesan('Gagal mencari toko: $e');
      setState(() => _loadingCari = false);
    }
  }

  // ── Fit kamera agar semua hasil pencarian terlihat ───────────────────────
  void _fitBoundsToResults(List<PlaceResult> results) {
    if (results.isEmpty) return;

    double minLat = results.first.latLng.latitude;
    double maxLat = results.first.latLng.latitude;
    double minLng = results.first.latLng.longitude;
    double maxLng = results.first.latLng.longitude;

    for (final r in results) {
      if (r.latLng.latitude < minLat) minLat = r.latLng.latitude;
      if (r.latLng.latitude > maxLat) maxLat = r.latLng.latitude;
      if (r.latLng.longitude < minLng) minLng = r.latLng.longitude;
      if (r.latLng.longitude > maxLng) maxLng = r.latLng.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        80,
      ),
    );
  }

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: kTextPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _kembaliKeLokasi() {
    if (_posisiSaya != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _posisiSaya!, zoom: 15.0),
        ),
      );
    } else {
      _ambilLokasi();
    }
  }

  void _pilihToko(int index) {
    final toko = _hasilCari[index];
    setState(() => _selectedIndex = index);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(toko.latLng, 16),
    );
  }

  void _hapusPencarian() {
    setState(() {
      _searchController.clear();
      _hasilCari = [];
      _selectedIndex = null;
      _markers.removeWhere((m) => m.markerId.value != 'lokasi_saya');
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: kSurfaceLight,
        foregroundColor: kTextPrimary,
        elevation: 0,
        title: const Text(
          'Lokasi Toko Sepatu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
        actions: [
          _loadingLokasi
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: kPrimaryColor),
                  ),
                )
              : IconButton(
                  onPressed: _ambilLokasi,
                  icon: const Icon(Icons.my_location_rounded),
                  color: kPrimaryColor,
                  tooltip: 'Perbarui Lokasi',
                ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorderColor),
        ),
      ),
      body: Stack(
        children: [
          // ── Google Maps ──────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_posisiSaya != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _posisiSaya!, zoom: 15.0),
                  ),
                );
              }
            },
            initialCameraPosition: const CameraPosition(
              target: _pusatDefault,
              zoom: 13.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // ── Search Bar ───────────────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                // Input pencarian
                Container(
                  decoration: BoxDecoration(
                    color: kSurfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 15,
                      color: kTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari toko sepatu...',
                      hintStyle: const TextStyle(
                        color: kTextMuted,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: kTextMuted,
                        size: 22,
                      ),
                      suffixIcon: _loadingCari
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kPrimaryColor,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: kTextMuted, size: 20),
                                  onPressed: _hapusPencarian,
                                  tooltip: 'Hapus pencarian',
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: _cariTokoSepatu,
                    onChanged: (val) => setState(() {}),
                  ),
                ),

                // Chip saran kata kunci
                if (_hasilCari.isEmpty && !_loadingCari)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildChipSaran('Toko Sepatu'),
                          _buildChipSaran('Shoe Store'),
                          _buildChipSaran('Sepatu Nike'),
                          _buildChipSaran('Sepatu Adidas'),
                          _buildChipSaran('Sneaker Store'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Daftar hasil pencarian (bottom sheet) ────────────────────
          if (_hasilCari.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildHasilPencarian(),
            ),

          // ── Info card lokasi pengguna (bila tidak ada hasil pencarian) ─
          if (_posisiSaya != null && _hasilCari.isEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSurfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.my_location_rounded, color: kPrimaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Anda Saat Ini',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${_posisiSaya!.latitude.toStringAsFixed(6)}\nLng: ${_posisiSaya!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 11, color: kTextMuted, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Tombol kembali ke lokasi saya ────────────────────────────
          Positioned(
            bottom: _hasilCari.isNotEmpty ? 250 : 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _kembaliKeLokasi,
              backgroundColor: kSurfaceLight,
              foregroundColor: kPrimaryColor,
              elevation: 4,
              mini: false,
              tooltip: 'Ke Lokasi Saya',
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // ── Loading overlay ──────────────────────────────────────────
          if (_loadingLokasi)
            Positioned(
              top: 76,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: kSurfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Mendapatkan lokasi...',
                        style: TextStyle(fontSize: 13, color: kTextPrimary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Widget chip saran kata kunci ─────────────────────────────────────────
  Widget _buildChipSaran(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _cariTokoSepatu(label);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kSurfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, size: 14, color: kPrimaryColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: kTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget daftar hasil pencarian ────────────────────────────────────────
  Widget _buildHasilPencarian() {
    return Container(
      height: 240,
      decoration: const BoxDecoration(
        color: kSurfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_hasilCari.length} toko ditemukan',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _hapusPencarian,
                  child: const Text(
                    'Hapus',
                    style: TextStyle(fontSize: 13, color: kPrimaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: kBorderColor),

          // List toko
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: _hasilCari.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final toko = _hasilCari[index];
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => _pilihToko(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPrimaryColor.withValues(alpha: 0.08)
                          : kBgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? kPrimaryColor : kBorderColor,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon + nama toko
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: kPrimaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                toko.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Alamat
                        Text(
                          toko.address,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kTextMuted,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const Spacer(),

                        // Rating + status buka
                        Row(
                          children: [
                            if (toko.rating != null) ...
                              [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  toko.rating!.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12, color: kTextPrimary, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                              ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: toko.isOpen
                                    ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                                    : const Color(0xFFE53935).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                toko.isOpen ? 'Buka' : 'Tutup',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: toko.isOpen
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
