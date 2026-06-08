// =============================================================================
// lokasi_screen.dart
// Menampilkan peta toko sepatu menggunakan OpenStreetMap (flutter_map)
// dan sensor geolocation untuk posisi pengguna saat ini.
// =============================================================================

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
    );
  }
}

// ── Data toko sepatu (sesuaikan koordinat sesuai lokasi nyata) ──────────────
class TokoSepatu {
  final String nama;
  final String alamat;
  final String jamBuka;
  final LatLng koordinat;
  final String telepon;

  const TokoSepatu({
    required this.nama,
    required this.alamat,
    required this.jamBuka,
    required this.koordinat,
    required this.telepon,
  });
}

final List<TokoSepatu> daftarToko = [
  TokoSepatu(
    nama: 'RakSneaker Malioboro',
    alamat: 'Jl. Malioboro No. 52, Yogyakarta',
    jamBuka: 'Senin–Sabtu, 09.00–21.00',
    koordinat: const LatLng(-7.7956, 110.3695),
    telepon: '0274-555-001',
  ),
  TokoSepatu(
    nama: 'RakSneaker Sleman City Hall',
    alamat: 'Sleman City Hall Lt. 2, Sleman',
    jamBuka: 'Setiap Hari, 10.00–22.00',
    koordinat: const LatLng(-7.7517, 110.3925),
    telepon: '0274-555-002',
  ),
  TokoSepatu(
    nama: 'RakSneaker Amplaz',
    alamat: 'Ambarrukmo Plaza Lt. 1, Yogyakarta',
    jamBuka: 'Setiap Hari, 10.00–22.00',
    koordinat: const LatLng(-7.7836, 110.4065),
    telepon: '0274-555-003',
  ),
  TokoSepatu(
    nama: 'RakSneaker Godean',
    alamat: 'Jl. Godean Km. 5, Sleman',
    jamBuka: 'Senin–Sabtu, 09.00–20.00',
    koordinat: const LatLng(-7.7886, 110.3278),
    telepon: '0274-555-004',
  ),
];

class LokasiScreen extends StatefulWidget {
  const LokasiScreen({super.key});

  @override
  State<LokasiScreen> createState() => _LokasiScreenState();
}

class _LokasiScreenState extends State<LokasiScreen> {
  final MapController _mapController = MapController();
  LatLng? _posisiSaya;
  bool _loadingLokasi = false;
  TokoSepatu? _tokoDipilih;
  int? _tokoIndex;

  // Pusat peta default: Yogyakarta
  static const LatLng _pusatDefault = LatLng(-7.7956, 110.3695);

  @override
  void initState() {
    super.initState();
    _ambilLokasi();
  }

  Future<void> _ambilLokasi() async {
    setState(() => _loadingLokasi = true);
    try {
      // Cek service geolocation
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _tampilkanPesan('Layanan lokasi dinonaktifkan. Aktifkan GPS terlebih dahulu.');
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
            'Izin lokasi ditolak permanen. Buka Pengaturan untuk mengaktifkan.');
        setState(() => _loadingLokasi = false);
        return;
      }

      // Dapatkan posisi — gunakan LocationSettings sesuai platform
      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );
      final latLng = LatLng(posisi.latitude, posisi.longitude);
      setState(() {
        _posisiSaya = latLng;
        _loadingLokasi = false;
      });
      // Arahkan peta ke posisi saya
      _mapController.move(latLng, 14.0);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _pilihToko(int index) {
    final toko = daftarToko[index];
    setState(() {
      _tokoDipilih = toko;
      _tokoIndex = index;
    });
    _mapController.move(toko.koordinat, 16.0);
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
          'Lokasi Toko',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
        actions: [
          // Tombol lokasi saya
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
                  tooltip: 'Lokasi Saya',
                ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: kBorderColor,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Peta OpenStreetMap ───────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pusatDefault,
                    initialZoom: 13.0,
                    maxZoom: 19.0,
                    minZoom: 5.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // Layer tile OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.raksneaker.app',
                      maxZoom: 19,
                    ),
                    // Marker toko sepatu
                    MarkerLayer(
                      markers: [
                        // Marker posisi saya (biru)
                        if (_posisiSaya != null)
                          Marker(
                            point: _posisiSaya!,
                            width: 60,
                            height: 60,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Saya',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Marker setiap toko
                        ...List.generate(daftarToko.length, (i) {
                          final toko = daftarToko[i];
                          final dipilih = _tokoIndex == i;
                          return Marker(
                            point: toko.koordinat,
                            width: dipilih ? 80 : 60,
                            height: dipilih ? 80 : 60,
                            child: GestureDetector(
                              onTap: () => _pilihToko(i),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: dipilih
                                          ? kPrimaryColor
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kPrimaryColor,
                                        width: dipilih ? 0 : 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: kPrimaryColor.withValues(
                                              alpha: dipilih ? 0.5 : 0.2),
                                          blurRadius: dipilih ? 12 : 6,
                                          spreadRadius: dipilih ? 2 : 0,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      color: dipilih
                                          ? Colors.white
                                          : kPrimaryColor,
                                      size: dipilih ? 22 : 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                // Kredit OpenStreetMap (wajib)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9, color: kTextMuted),
                    ),
                  ),
                ),
                // Tombol reset ke default
                Positioned(
                  top: 12,
                  right: 12,
                  child: _MapFabButton(
                    icon: Icons.zoom_out_map_rounded,
                    tooltip: 'Tampilan Semua Toko',
                    onTap: () {
                      setState(() {
                        _tokoDipilih = null;
                        _tokoIndex = null;
                      });
                      _mapController.move(_pusatDefault, 13.0);
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────────
          Container(
            height: 1,
            color: kBorderColor,
          ),

          // ── Daftar toko horizontal di bawah ─────────────────────────────
          Container(
            color: kSurfaceLight,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    'Toko Terdekat',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: daftarToko.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final toko = daftarToko[i];
                      final dipilih = _tokoIndex == i;
                      return GestureDetector(
                        onTap: () => _pilihToko(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 190,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: dipilih
                                ? kPrimaryColor.withValues(alpha: 0.08)
                                : kBgLight,
                            border: Border.all(
                              color: dipilih ? kPrimaryColor : kBorderColor,
                              width: dipilih ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    color: dipilih ? kPrimaryColor : kTextMuted,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      toko.nama,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: dipilih
                                            ? kPrimaryColor
                                            : kTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                toko.alamat,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kTextMuted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: kTextMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      toko.jamBuka,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: kTextMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
          ),

          // ── Detail toko dipilih ──────────────────────────────────────────
          if (_tokoDipilih != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: kSurfaceLight,
                border: Border(top: BorderSide(color: kBorderColor)),
              ),
              child: _DetailTokoCard(toko: _tokoDipilih!),
            ),
        ],
      ),
    );
  }
}

// ── Widget tombol floating di peta ──────────────────────────────────────────
class _MapFabButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapFabButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kSurfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: kTextPrimary),
        ),
      ),
    );
  }
}

// ── Card detail toko yang dipilih ────────────────────────────────────────────
class _DetailTokoCard extends StatelessWidget {
  final TokoSepatu toko;
  const _DetailTokoCard({required this.toko});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: kPrimaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                toko.nama,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 12, color: kTextMuted),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      toko.alamat,
                      style:
                          const TextStyle(fontSize: 12, color: kTextMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 12, color: kTextMuted),
                  const SizedBox(width: 3),
                  Text(
                    toko.jamBuka,
                    style:
                        const TextStyle(fontSize: 12, color: kTextMuted),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.phone_rounded,
                      size: 12, color: kTextMuted),
                  const SizedBox(width: 3),
                  Text(
                    toko.telepon,
                    style:
                        const TextStyle(fontSize: 12, color: kTextMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
