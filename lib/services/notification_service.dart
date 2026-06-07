// =============================================================================
// notification_service.dart
// Service untuk mengelola local notifications.
// Notifikasi akan muncul TEPAT PADA waktu jadwal perawatan sepatu,
// atau beberapa menit sebelumnya sesuai parameter [minutesBefore].
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
    // Bug Fix #3: Selalu inisialisasi timezone data & set lokal
    // agar tz.local tidak invalid setelah hot restart / re-init.
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Fallback jika timezone tidak tersedia
    }

    if (_initialized) return;

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

  /// Jadwalkan notifikasi pada waktu jadwal perawatan sepatu.
  ///
  /// [minutesBefore] menentukan berapa menit sebelum jadwal notifikasi muncul.
  /// Default = 30 (30 menit sebelum jadwal). Isi 0 untuk tepat saat jadwal.
  Future<void> scheduleJadwalNotification(
    JadwalModel jadwal, {
    int minutesBefore = 30,
  }) async {
    await init();

    // Hitung waktu notifikasi = waktu jadwal - minutesBefore menit
    final notifTime = jadwal.tanggalWaktu.subtract(
      Duration(minutes: minutesBefore),
    );

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

    // Sesuaikan deskripsi channel berdasarkan minutesBefore
    final channelDescription = minutesBefore == 0
        ? 'Notifikasi pengingat jadwal perawatan sepatu tepat saat waktu'
        : 'Notifikasi pengingat jadwal perawatan sepatu $minutesBefore menit sebelum waktu';

    final androidDetails = AndroidNotificationDetails(
      'jadwal_perawatan_channel',
      'Jadwal Perawatan Sepatu',
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: const BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final jam = TimeOfDay.fromDateTime(jadwal.tanggalWaktu);
    final jamStr =
        '${jam.hour.toString().padLeft(2, '0')}:${jam.minute.toString().padLeft(2, '0')}';

    // Buat judul dan isi notifikasi yang relevan
    final title = minutesBefore == 0
        ? '🧹 Waktunya Perawatan Sepatu!'
        : '🧹 Pengingat Perawatan Sepatu ($minutesBefore menit lagi)';

    final body =
        '${jadwal.namaSepatu} (${jadwal.merekSepatu}) akan dirawat pukul $jamStr.'
        '${jadwal.keterangan.isNotEmpty ? ' Catatan: ${jadwal.keterangan}' : ''}';

    try {
      // Bug Fix #4: Cek izin SCHEDULE_EXACT_ALARM (Android 12+)
      // Gunakan exactAllowWhileIdle jika izin tersedia, fallback ke exact.
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canScheduleExact =
          await androidImpl?.canScheduleExactNotifications() ?? true;

      final scheduleMode = canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.exact;

      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        tzNotifTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jadwal.id,
      );

      debugPrint(
        'Notifikasi dijadwalkan untuk: '
        '${jadwal.namaSepatu} pada ${notifTime.toString()} '
        '(mode: ${scheduleMode.name})',
      );
    } on Exception catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi: $e');
    }
  }

  /// Batalkan notifikasi berdasarkan ID jadwal.
  Future<void> cancelJadwalNotification(String jadwalId) async {
    await init();
    final notifId = jadwalId.hashCode.abs() % 2147483647;
    await _plugin.cancel(notifId);
    // Bug Fix #2: Perbaiki string interpolasi (sebelumnya memakai \$jadwalId)
    debugPrint('Notifikasi dibatalkan untuk jadwal id: $jadwalId');
  }

  /// Batalkan semua notifikasi.
  Future<void> cancelAllNotifications() async {
    await init();
    await _plugin.cancelAll();
  }
}
