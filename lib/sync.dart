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
  static Timer? _chatTimer;

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
              'ntfy': myTopic,
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
              'wheel': Store.listMap('wheel'),
              'wheel_last': Store.map('wheel_last'),
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

          // Kenh thong bao cua nguoi kia -> de gui push khi minh nhan tin
          await Store.setStr('partner_ntfy', (m['ntfy'] ?? '').toString());

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
          await Store.setListMap('wheel', _l(s['wheel']));
          await Store.setMap('wheel_last',
              Map<String, dynamic>.from((s['wheel_last'] as Map?) ?? {}));
          await Store.setMap(
              'fund', Map<String, dynamic>.from((s['fund'] as Map?) ?? {}));
          await Store.setStr('shared_ts', '$serverTs');
        }
      }

      applyingRemote = false;
      await pushMine();
      await pullChat();

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
  // THONG BAO DAY (ntfy.sh) — hoat dong ca khi app da dong
  // ----------------------------------------------------------
  /// Kenh rieng cua may nay. Nguoi kia se gui thong bao toi day.
  static String get myTopic {
    var t = Store.str('ntfy_topic');
    if (t.isEmpty) {
      t = 'lovesync-${randomCode()}';
      Store.p.setString('ntfy_topic', t);
    }
    return t;
  }

  static String get partnerTopic => Store.str('partner_ntfy').trim();
  static bool get notifyOn => Store.str('notify_on', '1') == '1';

  /// Co hien noi dung tin trong thong bao khong. Mac dinh la KHONG,
  /// vi kenh ntfy cong khai cho ai biet ten kenh.
  static bool get notifyPreview => Store.str('notify_preview', '0') == '1';

  static Future<String?> pushNotify({
    required String title,
    required String body,
    String tags = 'heart',
  }) async {
    if (!notifyOn) return null;
    final topic = partnerTopic;
    if (topic.isEmpty) return 'Người ấy chưa bật thông báo';
    try {
      final res = await http
          .post(
            Uri.parse('https://ntfy.sh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'topic': topic,
              'title': title,
              'message': body,
              'tags': [tags],
              'priority': 4,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200 ? null : 'Gửi thông báo lỗi ${res.statusCode}';
    } catch (e) {
      return 'Không gửi được thông báo';
    }
  }

  /// Gui thu ve chinh kenh cua minh de kiem tra da cai dat dung chua.
  static Future<String> testNotify() async {
    try {
      final res = await http
          .post(
            Uri.parse('https://ntfy.sh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'topic': myTopic,
              'title': 'LoveSync',
              'message': 'Thông báo hoạt động rồi 💕',
              'tags': ['heart'],
              'priority': 4,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200
          ? 'Đã gửi thử. Kiểm tra app ntfy trên máy bạn.'
          : 'Lỗi ${res.statusCode}, thử lại sau';
    } catch (e) {
      return 'Không có mạng';
    }
  }

  // ----------------------------------------------------------
  // NHAN TIN
  // ----------------------------------------------------------
  /// Gui mot tin nhan. Luu xuong may truoc de hien ngay, roi day len Firebase.
  static Future<String?> sendMessage(String text) async {
    if (!enabled) return 'Chưa ghép đôi nên chưa gửi được';
    final t = text.trim();
    if (t.isEmpty) return null;

    final ts = DateTime.now().millisecondsSinceEpoch;
    final id = '${ts}_$uid';
    final msg = {
      'id': id,
      'by': uid,
      'name': Store.myName,
      'avatar': Store.myAvatar,
      'text': t,
      'ts': ts,
    };

    // Hien ngay tren man hinh, khong cho mang
    final local = Store.listMap('chat')..add(msg);
    await Store.setListMap('chat', local);
    await Store.setStr('chat_read_ts', '$ts');
    revision.value++;

    try {
      await http
          .put(_u('chat/$id'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(msg))
          .timeout(const Duration(seconds: 20));

      // Bao cho may nguoi kia du app cua ho da dong han
      await pushNotify(
        title: '${Store.myName} vừa nhắn 💌',
        body: notifyPreview ? t : 'Mở LoveSync để đọc nhé',
      );
      return null;
    } catch (_) {
      return 'Mất mạng, tin sẽ được gửi lại khi có kết nối';
    }
  }

  /// Gui mot tam anh. Anh duoc thu nho truoc khi day len cho nhe.
  static Future<String?> sendImage(String base64Jpg, {String caption = ''}) async {
    if (!enabled) return 'Chưa ghép đôi nên chưa gửi được';

    final ts = DateTime.now().millisecondsSinceEpoch;
    final id = '${ts}_$uid';
    final msg = {
      'id': id,
      'by': uid,
      'name': Store.myName,
      'avatar': Store.str('my_avatar'),
      'text': caption,
      'img': base64Jpg,
      'ts': ts,
    };

    final local = Store.listMap('chat')..add(msg);
    await Store.setListMap('chat', local);
    await Store.setStr('chat_read_ts', '$ts');
    revision.value++;

    try {
      await http
          .put(_u('chat/$id'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(msg))
          .timeout(const Duration(seconds: 40));

      await pushNotify(
        title: '${Store.myName} vừa gửi ảnh 📷',
        body: notifyPreview && caption.isNotEmpty
            ? caption
            : 'Mở LoveSync để xem nhé',
        tags: 'camera',
      );
      return null;
    } catch (_) {
      return 'Mất mạng, ảnh chưa gửi được';
    }
  }

  // ----------------------------------------------------------
  // VAN CO CA-RO
  // ----------------------------------------------------------
  /// Doc van co hien tai tu Firebase.
  static Future<Map<String, dynamic>?> fetchGame() async {
    if (!enabled) return null;
    try {
      final res = await http
          .get(Uri.parse('$dbUrl/couples/$code/game.json'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final raw = jsonDecode(utf8.decode(res.bodyBytes));
      if (raw is! Map) return null;
      return Map<String, dynamic>.from(raw);
    } catch (_) {
      return null;
    }
  }

  /// Ghi de van co. Hai nguoi danh luan phien nen it khi ghi cung luc.
  static Future<bool> saveGame(Map<String, dynamic> game) async {
    if (!enabled) return false;
    try {
      final res = await http
          .put(_u('game'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(game))
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> pullChat() async {
    if (!enabled) return;
    try {
      final res = await http
          .get(Uri.parse('$dbUrl/couples/$code/chat.json'))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return;
      final raw = jsonDecode(utf8.decode(res.bodyBytes));
      if (raw is! Map) return;

      final list = raw.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..sort((a, b) =>
            ((a['ts'] as num?) ?? 0).compareTo((b['ts'] as num?) ?? 0));

      // Giu 300 tin gan nhat cho nhe may
      final trimmed = list.length > 300 ? list.sublist(list.length - 300) : list;

      final before = Store.listMap('chat').length;
      await Store.setListMap('chat', trimmed);
      // Co tin moi -> bao cho man hinh de hien thong bao
      if (trimmed.length != before) revision.value++;
    } catch (_) {}
  }

  /// So tin cua nguoi kia ma minh chua doc.
  static int unreadCount() {
    final readTs = int.tryParse(Store.str('chat_read_ts', '0')) ?? 0;
    return Store.listMap('chat')
        .where((m) =>
            m['by'] != uid && (((m['ts'] as num?) ?? 0).toInt()) > readTs)
        .length;
  }

  static Future<void> markChatRead() async {
    final list = Store.listMap('chat');
    if (list.isEmpty) return;
    final last = ((list.last['ts'] as num?) ?? 0).toInt();
    await Store.setStr('chat_read_ts', '$last');
    revision.value++;
  }

  // ----------------------------------------------------------
  // TU DONG DONG BO MOI 30 GIAY
  // ----------------------------------------------------------
  static void startAuto() {
    _timer?.cancel();
    _chatTimer?.cancel();
    if (!enabled) return;
    pullAll();
    // Du lieu chung: 30 giay mot lan
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => pullAll());
    // Tin nhan: 10 giay mot lan de bao kip thoi du dang o tab khac
    _chatTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => pullChat());
  }

  static void stopAuto() {
    _timer?.cancel();
    _chatTimer?.cancel();
    _timer = null;
    _chatTimer = null;
  }
}
