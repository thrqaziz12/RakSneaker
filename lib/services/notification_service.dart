// =============================================================================
// notification_service.dart
// Service untuk mengelola local notifications.
// Notifikasi akan muncul 2 JAM SEBELUM waktu jadwal perawatan sepatu.
// Menggunakan flutter_local_notifications + timezone.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/jadwal_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inisialisasi plugin dan timezone. Panggil sekali di main().
  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    // Set timezone ke Asia/Jakarta (WIB)
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Fallback jika timezone tidak tersedia
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handler saat notifikasi di-tap (opsional)
        debugPrint('Notifikasi di-tap: ${details.payload}');
      },
    );

    // Minta izin notifikasi di Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Jadwalkan notifikasi 2 jam sebelum waktu perawatan sepatu.
  Future<void> scheduleJadwalNotification(JadwalModel jadwal) async {
    await init();

    // Hitung waktu notifikasi = jadwal - 2 jam
    final notifTime = jadwal.tanggalWaktu.subtract(const Duration(hours: 2));

    // Jika waktu notifikasi sudah lewat, tidak perlu dijadwalkan
    if (notifTime.isBefore(DateTime.now())) {
      debugPrint(
        'Notifikasi untuk jadwal "${jadwal.namaSepatu}" sudah lewat, tidak dijadwalkan.',
      );
      return;
    }

    final tzNotifTime = tz.TZDateTime.from(notifTime, tz.local);

    // Gunakan hashCode dari id sebagai notification ID (int)
    final notifId = jadwal.id.hashCode.abs() % 2147483647;

    const androidDetails = AndroidNotificationDetails(
      'jadwal_perawatan_channel',
      'Jadwal Perawatan Sepatu',
      channelDescription:
          'Notifikasi pengingat jadwal perawatan sepatu 2 jam sebelum waktu',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final jam = TimeOfDay.fromDateTime(jadwal.tanggalWaktu);
    final jamStr =
        '${jam.hour.toString().padLeft(2, '0')}:${jam.minute.toString().padLeft(2, '0')}';

    await _plugin.zonedSchedule(
      notifId,
      '🧹 Pengingat Perawatan Sepatu',
      '${jadwal.namaSepatu} (${jadwal.merekSepatu}) akan dirawat pukul $jamStr.'
          '${jadwal.keterangan.isNotEmpty ? ' Catatan: ${jadwal.keterangan}' : ''}',
      tzNotifTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jadwal.id,
    );

    debugPrint(
      'Notifikasi dijadwalkan untuk: ${jadwal.namaSepatu} pada ${notifTime.toString()}',
    );
  }

  /// Batalkan notifikasi berdasarkan ID jadwal.
  Future<void> cancelJadwalNotification(String jadwalId) async {
    await init();
    final notifId = jadwalId.hashCode.abs() % 2147483647;
    await _plugin.cancel(notifId);
    debugPrint('Notifikasi dibatalkan untuk jadwal id: $jadwalId');
  }

  /// Batalkan semua notifikasi.
  Future<void> cancelAllNotifications() async {
    await init();
    await _plugin.cancelAll();
  }
}
