// =============================================================================
// lokasi_screen.dart
// Menampilkan Google Maps, pencarian toko sepatu, detail toko, dan rute.
// API: Maps SDK Android + Geolocation API + Places API (New) + Directions API.
// API Key: AIzaSyCVBa61HvhOJ0IBUrUXbHuVW3hqaqH9xMc
// =============================================================================

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;
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

// Warna 3 opsi rute
const kRouteColors = [
  Color(0xFF1A73E8), // biru  – rute utama
  Color(0xFF34A853), // hijau – alternatif 1
  Color(0xFF9C27B0), // ungu  – alternatif 2
];

// ── Model PlaceResult ────────────────────────────────────────────────────────
class PlaceResult {
  final String placeId;
  final String name;
  final String address;
  final LatLng latLng;
  final double? rating;
  final int? userRatingCount;
  final bool isOpen;
  final String? phoneNumber;
  final String? websiteUri;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latLng,
    this.rating,
    this.userRatingCount,
    required this.isOpen,
    this.phoneNumber,
    this.websiteUri,
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
      userRatingCount: (json['userRatingCount'] as num?)?.toInt(),
      isOpen: json['regularOpeningHours']?['openNow'] ?? false,
      phoneNumber: json['nationalPhoneNumber'],
      websiteUri: json['websiteUri'],
    );
  }
}

// ── Model RouteOption ────────────────────────────────────────────────────────
class RouteOption {
  final int index;
  final String durasi;
  final String jarak;
  final List<LatLng> polylinePoints;
  bool isSelected;

  RouteOption({
    required this.index,
    required this.durasi,
    required this.jarak,
    required this.polylinePoints,
    this.isSelected = false,
  });
}

// ── Decode encoded polyline Google ──────────────────────────────────────────
List<LatLng> _decodePolyline(String encoded) {
  final List<LatLng> points = [];
  int index = 0;
  final int len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

// ── LocationSettings ─────────────────────────────────────────────────────────
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
  }
  return const LocationSettings(accuracy: LocationAccuracy.high);
}

// ════════════════════════════════════════════════════════════════════════════
class LokasiScreen extends StatefulWidget {
  const LokasiScreen({super.key});
  @override
  State<LokasiScreen> createState() => _LokasiScreenState();
}

class _LokasiScreenState extends State<LokasiScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _posisiSaya;
  bool _loadingLokasi = true;
  bool _loadingCari = false;
  bool _loadingRute = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<PlaceResult> _hasilCari = [];
  int? _selectedIndex;

  // State detail & rute
  PlaceResult? _tokoDetail;
  List<RouteOption> _opsiRute = [];
  int _selectedRoute = 0;
  bool _tampilkanRute = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Panel mode: 'list' | 'detail' | 'rute'
  String _panelMode = 'list';

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

  // ── Ambil lokasi pengguna ─────────────────────────────────────────────────
  Future<void> _ambilLokasi() async {
    setState(() => _loadingLokasi = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _tampilkanPesan(
          'Layanan lokasi dinonaktifkan. Aktifkan GPS terlebih dahulu.',
        );
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
        _tampilkanPesan(
          'Izin lokasi ditolak permanen. Buka Pengaturan untuk mengaktifkan.',
        );
        setState(() => _loadingLokasi = false);
        return;
      }
      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );
      final latLng = LatLng(posisi.latitude, posisi.longitude);
      setState(() {
        _posisiSaya = latLng;
        _loadingLokasi = false;
        _markers.removeWhere((m) => m.markerId.value == 'lokasi_saya');
        _markers.add(
          Marker(
            markerId: const MarkerId('lokasi_saya'),
            position: latLng,
            infoWindow: const InfoWindow(
              title: 'Lokasi Saya',
              snippet: 'Posisi Anda saat ini',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
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

  // ── Cari toko (Places API New) ────────────────────────────────────────────
  Future<void> _cariTokoSepatu(String query) async {
    if (query.trim().isEmpty) return;
    _searchFocus.unfocus();
    setState(() {
      _loadingCari = true;
      _hasilCari = [];
      _selectedIndex = null;
      _tokoDetail = null;
      _opsiRute = [];
      _tampilkanRute = false;
      _panelMode = 'list';
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId.value != 'lokasi_saya');
    });

    try {
      final center = _posisiSaya ?? _pusatDefault;
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': kGoogleApiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.regularOpeningHours,places.nationalPhoneNumber,places.websiteUri',
        },
        body: jsonEncode({
          'textQuery': query,
          'locationBias': {
            'circle': {
              'center': {
                'latitude': center.latitude,
                'longitude': center.longitude,
              },
              'radius': 10000.0,
            },
          },
          'maxResultCount': 20,
          'languageCode': 'id',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final places = (data['places'] as List<dynamic>? ?? []);
        final hasil = places.map((p) => PlaceResult.fromJson(p)).toList();

        final markerBaru = <Marker>{};
        for (int i = 0; i < hasil.length; i++) {
          final toko = hasil[i];
          final idx = i;
          markerBaru.add(
            Marker(
              markerId: MarkerId(toko.placeId),
              position: toko.latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              onTap: () => _bukaDetailToko(hasil[idx]),
            ),
          );
        }

        setState(() {
          _hasilCari = hasil;
          _markers.addAll(markerBaru);
          _loadingCari = false;
          _panelMode = 'list';
        });

        if (hasil.isNotEmpty) {
          _fitBoundsToResults(hasil);
        } else {
          _tampilkanPesan('Tidak ditemukan toko dengan kata kunci "$query"');
        }
      } else {
        final err = jsonDecode(response.body);
        _tampilkanPesan(
          'Error ${response.statusCode}: ${err['error']?['message'] ?? 'Kesalahan API'}',
        );
        setState(() => _loadingCari = false);
      }
    } catch (e) {
      _tampilkanPesan('Gagal mencari toko: $e');
      setState(() => _loadingCari = false);
    }
  }

  // ── Buka panel detail toko ────────────────────────────────────────────────
  void _bukaDetailToko(PlaceResult toko) {
    // Tutup rute sebelumnya
    setState(() {
      _tokoDetail = toko;
      _opsiRute = [];
      _tampilkanRute = false;
      _polylines.clear();
      _panelMode = 'detail';
      _selectedIndex = _hasilCari.indexWhere((t) => t.placeId == toko.placeId);

      // Highlight marker terpilih jadi merah
      _markers.removeWhere((m) => m.markerId.value == toko.placeId);
      _markers.add(
        Marker(
          markerId: MarkerId(toko.placeId),
          position: toko.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _bukaDetailToko(toko),
        ),
      );
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(toko.latLng, 16));
  }

  // ── Muat 3 opsi rute (Directions API) ────────────────────────────────────
  Future<void> _muatRute(PlaceResult tujuan) async {
    if (_posisiSaya == null) {
      _tampilkanPesan('Lokasi Anda belum tersedia. Aktifkan GPS.');
      return;
    }
    setState(() {
      _loadingRute = true;
      _polylines.clear();
      _opsiRute = [];
      _panelMode = 'rute';
    });

    try {
      final ori = _posisiSaya!;
      final dst = tujuan.latLng;
      // Directions API dengan alternatives=true akan menghasilkan sampai 3 rute
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${ori.latitude},${ori.longitude}'
        '&destination=${dst.latitude},${dst.longitude}'
        '&alternatives=true'
        '&mode=driving'
        '&language=id'
        '&key=$kGoogleApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';

        if (status != 'OK') {
          _tampilkanPesan('Rute tidak tersedia: $status');
          setState(() => _loadingRute = false);
          return;
        }

        final routes = data['routes'] as List<dynamic>;
        final opsi = <RouteOption>[];
        final polylinesBaru = <Polyline>{};

        for (int i = 0; i < routes.length && i < 3; i++) {
          final route = routes[i] as Map<String, dynamic>;
          final leg = (route['legs'] as List).first as Map<String, dynamic>;
          final durasi = leg['duration']?['text'] ?? '-';
          final jarak = leg['distance']?['text'] ?? '-';
          final encodedPoly =
              route['overview_polyline']?['points'] as String? ?? '';
          final points = _decodePolyline(encodedPoly);

          final opsiRute = RouteOption(
            index: i,
            durasi: durasi,
            jarak: jarak,
            polylinePoints: points,
            isSelected: i == 0,
          );
          opsi.add(opsiRute);

          // Polyline: rute utama (i==0) lebih tebal & di depan
          polylinesBaru.add(
            Polyline(
              polylineId: PolylineId('rute_$i'),
              points: points,
              color: kRouteColors[i % kRouteColors.length].withValues(
                alpha: i == 0 ? 1.0 : 0.55,
              ),
              width: i == 0 ? 6 : 4,
              zIndex: i == 0 ? 2 : 1,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              patterns: i == 0
                  ? []
                  : [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        }

        setState(() {
          _opsiRute = opsi;
          _polylines.addAll(polylinesBaru);
          _selectedRoute = 0;
          _tampilkanRute = true;
          _loadingRute = false;
        });

        // Fit kamera agar semua rute terlihat
        _fitBoundsRute(ori, dst);
      } else {
        _tampilkanPesan('Gagal memuat rute: ${response.statusCode}');
        setState(() => _loadingRute = false);
      }
    } catch (e) {
      _tampilkanPesan('Error rute: $e');
      setState(() => _loadingRute = false);
    }
  }

  // ── Pilih opsi rute – highlight polyline terpilih ─────────────────────────
  void _pilihOpsiRute(int index) {
    setState(() {
      _selectedRoute = index;
      for (final r in _opsiRute) {
        r.isSelected = r.index == index;
      }

      final polylinesBaru = <Polyline>{};
      for (final r in _opsiRute) {
        polylinesBaru.add(
          Polyline(
            polylineId: PolylineId('rute_${r.index}'),
            points: r.polylinePoints,
            color: kRouteColors[r.index % kRouteColors.length].withValues(
              alpha: r.isSelected ? 1.0 : 0.45,
            ),
            width: r.isSelected ? 6 : 4,
            zIndex: r.isSelected ? 2 : 1,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            patterns: r.isSelected
                ? []
                : [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
      _polylines
        ..clear()
        ..addAll(polylinesBaru);
    });
  }

  void _fitBoundsRute(LatLng ori, LatLng dst) {
    final minLat = math.min(ori.latitude, dst.latitude);
    final maxLat = math.max(ori.latitude, dst.latitude);
    final minLng = math.min(ori.longitude, dst.longitude);
    final maxLng = math.max(ori.longitude, dst.longitude);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        80,
      ),
    );
  }

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

  void _tutupPanel() {
    setState(() {
      _tokoDetail = null;
      _opsiRute = [];
      _tampilkanRute = false;
      _polylines.clear();
      _panelMode = _hasilCari.isNotEmpty ? 'list' : 'none';
      // Kembalikan warna marker
      if (_selectedIndex != null && _selectedIndex! < _hasilCari.length) {
        final toko = _hasilCari[_selectedIndex!];
        _markers.removeWhere((m) => m.markerId.value == toko.placeId);
        _markers.add(
          Marker(
            markerId: MarkerId(toko.placeId),
            position: toko.latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            onTap: () => _bukaDetailToko(toko),
          ),
        );
      }
    });
  }

  void _hapusPencarian() {
    setState(() {
      _searchController.clear();
      _hasilCari = [];
      _selectedIndex = null;
      _tokoDetail = null;
      _opsiRute = [];
      _tampilkanRute = false;
      _polylines.clear();
      _panelMode = 'none';
      _markers.removeWhere((m) => m.markerId.value != 'lokasi_saya');
    });
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

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final bool adaPanel =
        _panelMode == 'list' || _panelMode == 'detail' || _panelMode == 'rute';

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
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: kPrimaryColor,
                    ),
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
          // ── Google Maps ────────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              if (_posisiSaya != null) {
                c.animateCamera(
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
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // ── Search Bar ─────────────────────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    style: const TextStyle(fontSize: 15, color: kTextPrimary),
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
                              icon: const Icon(
                                Icons.close_rounded,
                                color: kTextMuted,
                                size: 20,
                              ),
                              onPressed: _hapusPencarian,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: _cariTokoSepatu,
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                // Chip saran (hanya saat belum ada hasil & tidak loading)
                if (_hasilCari.isEmpty && !_loadingCari)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chipSaran('Toko Sepatu'),
                          _chipSaran('Shoe Store'),
                          _chipSaran('Sepatu Nike'),
                          _chipSaran('Sepatu Adidas'),
                          _chipSaran('Sneaker Store'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom Panel ───────────────────────────────────────────────────
          if (adaPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomPanel(),
            ),

          // ── Info card posisi (hanya saat tidak ada panel) ──────────────────
          if (!adaPanel && _posisiSaya != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildInfoKartuLokasi(),
            ),

          // ── FAB lokasi saya ────────────────────────────────────────────────
          Positioned(
            bottom: adaPanel ? _fabBottomOffset() : 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _kembaliKeLokasi,
              backgroundColor: kSurfaceLight,
              foregroundColor: kPrimaryColor,
              elevation: 4,
              tooltip: 'Ke Lokasi Saya',
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // ── Loading overlay lokasi ─────────────────────────────────────────
          if (_loadingLokasi)
            Positioned(
              top: 76,
              left: 0,
              right: 0,
              child: Center(child: _buildLoadingBadge('Mendapatkan lokasi...')),
            ),

          // ── Loading rute overlay ───────────────────────────────────────────
          if (_loadingRute)
            Positioned(
              top: 76,
              left: 0,
              right: 0,
              child: Center(child: _buildLoadingBadge('Menghitung rute...')),
            ),
        ],
      ),
    );
  }

  double _fabBottomOffset() {
    if (_panelMode == 'rute') return 300;
    if (_panelMode == 'detail') return 270;
    return 260;
  }

  // ── Dispatcher panel bawah ────────────────────────────────────────────────
  Widget _buildBottomPanel() {
    if (_panelMode == 'rute' && _tokoDetail != null) return _buildPanelRute();
    if (_panelMode == 'detail' && _tokoDetail != null)
      return _buildPanelDetail();
    return _buildPanelListToko();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PANEL 1 — Daftar toko (horizontal cards)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildPanelListToko() {
    return Container(
      height: 240,
      decoration: const BoxDecoration(
        color: kSurfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _handleBar(),
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
                    style: TextStyle(
                      fontSize: 13,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorderColor),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: _hasilCari.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final toko = _hasilCari[i];
                final sel = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => _bukaDetailToko(toko),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel
                          ? kPrimaryColor.withValues(alpha: 0.08)
                          : kBgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? kPrimaryColor : kBorderColor,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ikonToko(),
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
                        _badgeRatingStatus(toko),
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

  // ════════════════════════════════════════════════════════════════════════════
  // PANEL 2 — Detail toko (mirip Google Maps)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildPanelDetail() {
    final toko = _tokoDetail!;
    return Container(
      decoration: const BoxDecoration(
        color: kSurfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handleBar(),
          // Header: nama + tombol tutup
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toko.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _badgeRatingStatus(toko),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _tutupPanel,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: kTextMuted,
                    size: 22,
                  ),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),

          // Tombol aksi: Rute, Bagikan (placeholder)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // ── Tombol RUTE ──────────────────────────────────────────────
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _muatRute(toko),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text(
                      'Rute',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ── Tombol KEMBALI KE LIST ────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _panelMode = 'list';
                    _tokoDetail = null;
                    _polylines.clear();
                  }),
                  icon: const Icon(Icons.list_rounded, size: 18),
                  label: const Text(
                    'List',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryColor,
                    side: const BorderSide(color: kPrimaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: kBorderColor),

          // Info detail
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _detailRow(Icons.location_on_outlined, toko.address),
                if (toko.phoneNumber != null)
                  _detailRow(Icons.phone_outlined, toko.phoneNumber!),
                if (toko.websiteUri != null)
                  _detailRow(
                    Icons.language_outlined,
                    toko.websiteUri!,
                    clamp: true,
                  ),
                _detailRow(
                  toko.isOpen
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  toko.isOpen ? 'Buka Sekarang' : 'Tutup Sekarang',
                  color: toko.isOpen
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PANEL 3 — Pilihan rute
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildPanelRute() {
    final toko = _tokoDetail!;
    return Container(
      decoration: const BoxDecoration(
        color: kSurfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handleBar(),

          // Header rute
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Rute',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                      Text(
                        'ke ${toko.name}',
                        style: const TextStyle(fontSize: 12, color: kTextMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _panelMode = 'detail';
                    _polylines.clear();
                    _opsiRute = [];
                    _tampilkanRute = false;
                  }),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: kTextMuted,
                    size: 22,
                  ),
                  tooltip: 'Kembali ke detail',
                ),
              ],
            ),
          ),

          // Label warna rute
          if (_opsiRute.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  for (int i = 0; i < _opsiRute.length; i++) ...[
                    Container(
                      width: 12,
                      height: 4,
                      color: kRouteColors[i % kRouteColors.length],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      i == 0 ? 'Utama' : 'Alt $i',
                      style: TextStyle(
                        fontSize: 11,
                        color: kRouteColors[i % kRouteColors.length],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: kBorderColor),

          // Loading atau daftar opsi
          if (_loadingRute)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: kPrimaryColor,
                  strokeWidth: 3,
                ),
              ),
            )
          else if (_opsiRute.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Rute tidak tersedia',
                style: TextStyle(color: kTextMuted),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _opsiRute.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                color: kBorderColor,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (_, i) {
                final rute = _opsiRute[i];
                final selected = _selectedRoute == i;
                return GestureDetector(
                  onTap: () => _pilihOpsiRute(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? kRouteColors[i % kRouteColors.length].withValues(
                              alpha: 0.08,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(
                              color: kRouteColors[i % kRouteColors.length],
                              width: 1.5,
                            )
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        // Indikator warna
                        Container(
                          width: 5,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kRouteColors[i % kRouteColors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Info rute
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car_rounded,
                                    size: 15,
                                    color:
                                        kRouteColors[i % kRouteColors.length],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    i == 0 ? 'Rute Utama' : 'Alternatif $i',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          kRouteColors[i % kRouteColors.length],
                                    ),
                                  ),
                                  if (i == 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Tercepat',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 13,
                                    color: kTextMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rute.durasi,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: kTextPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.straighten_rounded,
                                    size: 13,
                                    color: kTextMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rute.jarak,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: kTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Centang jika terpilih
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: kRouteColors[i % kRouteColors.length],
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Komponen kecil ───────────────────────────────────────────────────────
  Widget _handleBar() => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: kBorderColor,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _ikonToko() => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: kPrimaryColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.storefront_rounded, color: kPrimaryColor, size: 18),
  );

  Widget _badgeRatingStatus(PlaceResult toko) => Row(
    children: [
      if (toko.rating != null) ...[
        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 14),
        const SizedBox(width: 3),
        Text(
          toko.rating!.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            color: kTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (toko.userRatingCount != null)
          Text(
            ' (${toko.userRatingCount})',
            style: const TextStyle(fontSize: 11, color: kTextMuted),
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
  );

  Widget _detailRow(
    IconData icon,
    String text, {
    Color? color,
    bool clamp = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color ?? kTextMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? kTextPrimary,
              height: 1.4,
            ),
            maxLines: clamp ? 1 : null,
            overflow: clamp ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    ),
  );

  Widget _buildInfoKartuLokasi() => Container(
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
          child: const Icon(
            Icons.my_location_rounded,
            color: kPrimaryColor,
            size: 22,
          ),
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
                style: const TextStyle(
                  fontSize: 11,
                  color: kTextMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildLoadingBadge(String msg) => Container(
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
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          msg,
          style: const TextStyle(
            fontSize: 13,
            color: kTextPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _chipSaran(String label) => GestureDetector(
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
