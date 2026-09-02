// LoveSync - notif.dart
// Thong bao tren thanh trang thai Android (co am thanh, rung, hien o man hinh khoa).
//
// Luu y ve pham vi: thong bao nay do CHINH may nay tao ra khi app con dang chay
// (dang mo hoac vua chuyen sang chay ngam). Khi app bi dong han, Android dung
// het timer nen phai dua vao ntfy.sh — xem THONG-BAO-NTFY.md.
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notif {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Ham chay khi nguoi dung cham vao thong bao.
  static void Function()? onTap;

  static Future<void> init() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: android),
        onDidReceiveNotificationResponse: (_) => onTap?.call(),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notif init loi: $e');
    }
  }

  /// Android 13 tro len bat buoc hoi quyen thong bao.
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('Xin quyen thong bao loi: $e');
      return false;
    }
  }

  static Future<bool> isEnabled() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> show({
    required String title,
    required String body,
  }) async {
    if (!_ready) await init();
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'lovesync_chat',
          'Tin nhắn LoveSync',
          channelDescription: 'Báo khi người ấy nhắn tin',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          color: Color(0xFFFF85A1),
          styleInformation: BigTextStyleInformation(''),
        ),
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Hien thong bao loi: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
