// =============================================================================
// lokasi_screen.dart
// Menampilkan Google Maps dan lokasi pengguna saat ini.
// Menggunakan Google Maps SDK for Android + Geolocation API.
// API Key: AIzaSyCVBa61HvhOJ0IBUrUXbHuVW3hqaqH9xMc
// =============================================================================

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

const kPrimaryColor = Color(0xFFFF6B35);
const kBgLight = Color(0xFFFFF8F5);
const kSurfaceLight = Color(0xFFFFFFFF);
const kTextPrimary = Color(0xFF1A1A1A);
const kTextMuted = Color(0xFF6B6B6B);
const kBorderColor = Color(0xFFE8E0DB);

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
  final Set<Marker> _markers = {};

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
    super.dispose();
  }

  Future<void> _ambilLokasi() async {
    setState(() => _loadingLokasi = true);
    try {
      // Cek service geolocation
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _tampilkanPesan(
          'Layanan lokasi dinonaktifkan. Aktifkan GPS terlebih dahulu.',
        );
        setState(() => _loadingLokasi = false);
        return;
      }

      // Cek & minta izin
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

      // Dapatkan posisi saat ini
      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );
      final latLng = LatLng(posisi.latitude, posisi.longitude);

      // Tambahkan marker lokasi pengguna
      final markerSaya = Marker(
        markerId: const MarkerId('lokasi_saya'),
        position: latLng,
        infoWindow: const InfoWindow(
          title: 'Lokasi Saya',
          snippet: 'Posisi Anda saat ini',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      );

      setState(() {
        _posisiSaya = latLng;
        _loadingLokasi = false;
        _markers.removeWhere((m) => m.markerId.value == 'lokasi_saya');
        _markers.add(markerSaya);
      });

      // Pindahkan kamera ke posisi pengguna
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

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: kTextPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kSurfaceLight,
        foregroundColor: kTextPrimary,
        elevation: 0,
        title: const Text(
          'Lokasi Saya',
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
          // ── Google Maps ────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              // Setelah map siap, jika lokasi sudah ada, pindahkan kamera
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

          // ── Info card lokasi pengguna ──────────────────────────────────
          if (_posisiSaya != null)
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
              ),
            ),

          // ── Tombol kembali ke lokasi saya ──────────────────────────────
          Positioned(
            bottom: 24,
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

          // ── Loading overlay ────────────────────────────────────────────
          if (_loadingLokasi)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimaryColor,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Mendapatkan lokasi...',
                        style: TextStyle(
                          fontSize: 13,
                          color: kTextPrimary,
                          fontWeight: FontWeight.w500,
                        ),
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
}
