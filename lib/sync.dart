// LoveSync v2 - sync.dart
// Dong bo 2 may qua Firebase Realtime Database (REST API - khong can SDK).
//
// Cau truc du lieu tren Firebase:
//   couples/{pairCode}/members/{uid} = { name, moods[], quiz{}, ts }
//   couples/{pairCode}/shared        = { wishlist[], events[], fund{}, fund_logs[], ts, by }
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

class Sync {
  /// Bat khi dang ghi du lieu tu server xuong may -> tranh vong lap push/pull.
  static bool applyingRemote = false;

  /// Trang thai hien thi tren UI.
  static final ValueNotifier<String> status = ValueNotifier<String>('');

  /// Tang len sau moi lan dong bo thanh cong -> man hinh tu ve lai.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static Timer? _timer;

  static String get dbUrl =>
      Store.str('db_url').trim().replaceAll(RegExp(r'/+$'), '');
  static String get code => Store.str('pair_code').trim();
  static String get uid => Store.str('uid');

  static bool get enabled => dbUrl.isNotEmpty && code.length >= 12;

  static String randomCode() {
    const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
    final r = Random.secure();
    return List.generate(16, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static Uri _u(String path) => Uri.parse('$dbUrl/couples/$code/$path.json');

  // ----------------------------------------------------------
  // PUSH
  // ----------------------------------------------------------
  static Future<void> pushMine() async {
    if (!enabled || applyingRemote) return;
    try {
      await http
          .put(
            _u('members/$uid'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': Store.myName,
              'avatar': Store.str('my_avatar'),
              'profileTs': int.tryParse(Store.str('my_profile_ts', '0')) ?? 0,
              'moods': Store.moods('me').take(60).map((e) => e.toJson()).toList(),
              'quiz': Store.quiz('me'),
              'ts': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      // Mat mang thi bo qua, lan sync sau se day lai.
    }
  }

  static Future<void> pushShared() async {
    if (!enabled || applyingRemote) return;
    final ts = DateTime.now().millisecondsSinceEpoch;
    try {
      await http
          .put(
            _u('shared'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'wishlist': Store.listMap('wishlist'),
              'events': Store.listMap('events'),
              'memories': Store.listMap('memories'),
              'fund': Store.map('fund'),
              'fund_logs': Store.listMap('fund_logs'),
              'ts': ts,
              'by': Store.myName,
            }),
          )
          .timeout(const Duration(seconds: 20));
      await Store.setStr('shared_ts', '$ts');
    } catch (_) {}
  }

  // ----------------------------------------------------------
  // PULL
  // ----------------------------------------------------------
  static Future<String> pullAll() async {
    if (dbUrl.isEmpty) return 'Chưa nhập Database URL trong Cài đặt';
    if (code.length < 12) return 'Mã cặp đôi phải từ 12 ký tự trở lên';

    try {
      final res = await http
          .get(Uri.parse('$dbUrl/couples/$code.json'))
          .timeout(const Duration(seconds: 25));

      if (res.statusCode == 401 || res.statusCode == 403) {
        return 'Firebase từ chối truy cập. Kiểm tra lại phần Rules của Realtime Database.';
      }
      if (res.statusCode == 404) {
        return 'Sai Database URL. Copy lại URL trong Firebase Console.';
      }
      if (res.statusCode != 200) {
        return 'Lỗi kết nối (mã ${res.statusCode})';
      }

      final raw = jsonDecode(utf8.decode(res.bodyBytes));
      if (raw == null) {
        await pushMine();
        await pushShared();
        return 'Đã tạo phòng mới. Gửi mã cặp đôi cho người ấy nhé.';
      }

      final data = Map<String, dynamic>.from(raw as Map);
      applyingRemote = true;

      // ---- Du lieu ca nhan cua nguoi kia
      String partnerFound = '';
      bool profileChanged = false;
      final members = data['members'];
      if (members is Map) {
        for (final e in members.entries) {
          if (e.key == uid) continue;
          final m = Map<String, dynamic>.from(e.value as Map);

          // Ten + avatar: cap nhat ngay khi nguoi kia sua
          partnerFound = (m['name'] ?? 'Người ấy').toString();
          if (Store.partnerName != partnerFound) profileChanged = true;
          await Store.setStr('partner_name', partnerFound);

          final av = (m['avatar'] ?? '').toString();
          if (Store.str('partner_avatar') != av) profileChanged = true;
          await Store.setStr('partner_avatar', av);

          final moods = (m['moods'] as List?) ?? [];
          await Store.setListMap('moods_partner',
              moods.map((x) => Map<String, dynamic>.from(x as Map)).toList());
          await Store.setMap('quiz_partner',
              Map<String, dynamic>.from((m['quiz'] as Map?) ?? {}));
          break; // chi lay 1 nguoi kia
        }
      }

      // ---- Du lieu dung chung: chi ghi de khi ban tren server moi hon
      final shared = data['shared'];
      if (shared is Map) {
        final s = Map<String, dynamic>.from(shared);
        final serverTs = (s['ts'] as num?)?.toInt() ?? 0;
        final localTs = int.tryParse(Store.str('shared_ts', '0')) ?? 0;
        if (serverTs > localTs) {
          await Store.setListMap('wishlist', _l(s['wishlist']));
          await Store.setListMap('events', _l(s['events']));
          await Store.setListMap('memories', _l(s['memories']));
          await Store.setListMap('fund_logs', _l(s['fund_logs']));
          await Store.setMap(
              'fund', Map<String, dynamic>.from((s['fund'] as Map?) ?? {}));
          await Store.setStr('shared_ts', '$serverTs');
        }
      }

      applyingRemote = false;
      await pushMine();

      status.value = 'Đồng bộ lúc ${_now()}';
      revision.value++; // bao cho cac man hinh ve lai
      return partnerFound.isEmpty
          ? 'Đã đồng bộ. Chưa thấy người ấy vào phòng.'
          : profileChanged
              ? 'Đã cập nhật hồ sơ mới của $partnerFound'
              : 'Đã đồng bộ với $partnerFound';
    } catch (e) {
      applyingRemote = false;
      return 'Lỗi: $e';
    }
  }

  static List<Map<String, dynamic>> _l(dynamic v) => ((v as List?) ?? [])
      .map((x) => Map<String, dynamic>.from(x as Map))
      .toList();

  static String _now() {
    final d = DateTime.now();
    return '${two(d.hour)}:${two(d.minute)}';
  }

  // ----------------------------------------------------------
  // TU DONG DONG BO MOI 30 GIAY
  // ----------------------------------------------------------
  static void startAuto() {
    _timer?.cancel();
    if (!enabled) return;
    pullAll();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => pullAll());
  }

  static void stopAuto() {
    _timer?.cancel();
    _timer = null;
  }
}
