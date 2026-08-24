// LoveSync v2 - Ung dung cho cap doi (dong bo realtime qua Firebase)
// File 1/4: main.dart -> Theme, Store, Shell, Mood Sync, AI Coach, Settings
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'quiz.dart';
import 'extras.dart';
import 'sync.dart';

// ============================================================
// 1. THEME & HELPERS
// ============================================================
class C {
  static const pink = Color(0xFFFF85A1);
  static const purple = Color(0xFFA29BFE);
  static const bg = Color(0xFFFDF7F9);
  static const card = Colors.white;
  static const ink = Color(0xFF2E2A33);
  static const muted = Color(0xFF8A8595);
  static const soft = Color(0xFFF1ECF7);

  static const grad = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

String two(int n) => n < 10 ? '0$n' : '$n';
String ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
String pretty(String isoDate) {
  final p = isoDate.split('-');
  if (p.length != 3) return isoDate;
  return '${p[2]}/${p[1]}/${p[0]}';
}

DateTime parseYmd(String s) {
  try {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  } catch (_) {
    return DateTime.now();
  }
}

const List<String> moodEmoji = ['😢', '😕', '😐', '🙂', '🥰'];
const List<String> moodLabel = ['Rất tệ', 'Hơi buồn', 'Bình thường', 'Vui', 'Tuyệt vời'];
const List<String> moodTags = [
  'Công việc',
  'Sức khoẻ',
  'Gia đình',
  'Tài chính',
  'Nhớ nhau',
  'Mệt mỏi',
  'Hạnh phúc',
  'Áp lực',
];

// ============================================================
// 2. STORE (SharedPreferences + hook day len Firebase)
// ============================================================
class MoodEntry {
  final String date; // yyyy-MM-dd
  final int level; // 1..5
  final List<String> tags;
  final String note;

  MoodEntry({
    required this.date,
    required this.level,
    this.tags = const [],
    this.note = '',
  });

  Map<String, dynamic> toJson() =>
      {'date': date, 'level': level, 'tags': tags, 'note': note};

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
        date: (j['date'] ?? '').toString(),
        level: (j['level'] is int) ? j['level'] as int : 3,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        note: (j['note'] ?? '').toString(),
      );
}

class Store {
  static late SharedPreferences p;

  /// Cac key thuoc du lieu dung chung -> tu day len Firebase khi thay doi.
  static const sharedKeys = ['wishlist', 'events', 'memories', 'fund_logs', 'fund'];

  static Future<void> init() async {
    p = await SharedPreferences.getInstance();
    if (str('uid').isEmpty) {
      final r = Random.secure();
      final id = List.generate(12,
          (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[r.nextInt(36)]).join();
      await p.setString('uid', id);
    }
  }

  // ---- generic
  static String str(String k, [String d = '']) => p.getString(k) ?? d;
  static Future<void> setStr(String k, String v) async {
    await p.setString(k, v);
  }

  static List<Map<String, dynamic>> listMap(String k) {
    final raw = p.getString(k);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setListMap(String k, List<Map<String, dynamic>> v) async {
    await p.setString(k, jsonEncode(v));
    _afterWrite(k);
  }

  static Map<String, dynamic> map(String k) {
    final raw = p.getString(k);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> setMap(String k, Map<String, dynamic> v) async {
    await p.setString(k, jsonEncode(v));
    _afterWrite(k);
  }

  /// Ghi xong thi day len Firebase (khong cho doi ket qua).
  static void _afterWrite(String k) {
    if (Sync.applyingRemote) return;
    if (sharedKeys.contains(k)) {
      Sync.pushShared();
    } else if (k == 'moods_me' || k == 'quiz_me') {
      Sync.pushMine();
    }
  }

  // ---- profile
  static String get myName => str('my_name', 'Tôi');
  static String get partnerName => str('partner_name', 'Người ấy');
  static String get myAvatar => str('my_avatar');
  static String get partnerAvatar => str('partner_avatar');
  static String get loveStart => str('love_start', '');
  static String get apiKey => str('gemini_key', '');

  /// Sua ten hoac avatar -> danh dau moc thoi gian va day len ngay.
  static Future<void> saveProfile({String? name, String? avatar}) async {
    if (name != null) await p.setString('my_name', name);
    if (avatar != null) await p.setString('my_avatar', avatar);
    await p.setString(
        'my_profile_ts', '${DateTime.now().millisecondsSinceEpoch}');
    await Sync.pushMine();
  }

  // ---- moods: who = 'me' | 'partner'
  static List<MoodEntry> moods(String who) => listMap('moods_$who')
      .map((e) => MoodEntry.fromJson(e))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  static Future<void> saveMood(String who, MoodEntry m) async {
    final all = moods(who).where((e) => e.date != m.date).toList()..add(m);
    all.sort((a, b) => b.date.compareTo(a.date));
    await setListMap('moods_$who', all.map((e) => e.toJson()).toList());
  }

  static MoodEntry? moodOf(String who, String date) {
    for (final m in moods(who)) {
      if (m.date == date) return m;
    }
    return null;
  }

  // ---- quiz answers: {questionId: optionIndex}
  static Map<String, dynamic> quiz(String who) => map('quiz_$who');

  static Future<void> setQuizAnswer(String who, String qid, int idx) async {
    final m = quiz(who);
    m[qid] = idx;
    await setMap('quiz_$who', m);
  }
}

// ============================================================
// 3. APP
// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  Sync.startAuto();
  runApp(const LoveSyncApp());
}

class LoveSyncApp extends StatelessWidget {
  const LoveSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: C.pink,
        primary: C.pink,
        secondary: C.purple,
        surface: C.card,
      ),
      scaffoldBackgroundColor: C.bg,
      fontFamily: 'Roboto',
    );
    return MaterialApp(
      title: 'LoveSync',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          foregroundColor: C.ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: C.soft.withOpacity(0.55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mo lai app -> keo du lieu moi nhat ve ngay.
    if (state == AppLifecycleState.resumed) {
      Sync.startAuto();
    } else if (state == AppLifecycleState.paused) {
      Sync.stopAuto();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      MoodScreen(),
      QuizScreen(),
      CoachScreen(),
      ExtrasScreen(),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: C.pink.withOpacity(0.15),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Cảm xúc'),
          NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz),
              label: 'Duo Quiz'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'AI Coach'),
          NavigationDestination(
              icon: Icon(Icons.widgets_outlined),
              selectedIcon: Icon(Icons.widgets),
              label: 'Của mình'),
        ],
      ),
    );
  }
}

// ============================================================
// 4. WIDGET DUNG CHUNG
// ============================================================
class Section extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets padding;
  const Section({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: padding,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: C.purple.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: C.ink)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ve gradient bang Container chu KHONG dung Ink.
    // Ink ve nen vao Material gan nhat (nen Scaffold), nam DUOI the trang cua
    // Section -> nut se bi che mat, chi con chu trang tren nen trang.
    return Opacity(
      opacity: onTap == null || loading ? 0.6 : 1,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: C.grad,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: C.pink.withOpacity(0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: loading ? null : onTap,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  const PageHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: C.muted, fontSize: 13)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    behavior: SnackBarBehavior.floating,
    backgroundColor: C.ink,
  ));
}

/// Bo avatar emoji dung san. Gia tri luu trong SharedPreferences la chinh emoji.
const List<String> avatarEmojis = [
  '🐻', '🐼', '🐨', '🦊', '🐱', '🐶',
  '🐰', '🐯', '🦁', '🐷', '🐸', '🐵',
  '🐧', '🦉', '🦄', '🐢', '🐳', '🦖',
  '🌻', '🌸', '🌵', '🍓', '🍑', '🍉',
  '⭐', '🌙', '☁️', '🔥', '💎', '🎧',
  '👑', '🎸', '⚽', '🚀', '🍀', '💗',
];

/// Anh dai dien: emoji da chon, hoac chu cai dau cua ten neu chua chon.
class Avatar extends StatelessWidget {
  final String emoji;
  final String name;
  final double size;
  final Color ring;
  const Avatar({
    super.key,
    required this.emoji,
    required this.name,
    this.size = 56,
    this.ring = C.pink,
  });

  @override
  Widget build(BuildContext context) {
    // Bo qua du lieu cu khong phai emoji (vd chuoi base64 tu ban truoc).
    final e = (emoji.isNotEmpty && emoji.length <= 8) ? emoji : '';
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring.withOpacity(0.16),
        border: Border.all(color: ring, width: 2),
      ),
      child: e.isEmpty
          ? Text(letter,
              style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w800,
                  color: ring))
          : Text(e, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// Bang chon emoji lam avatar.
Future<String?> pickAvatarEmoji(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn ảnh đại diện',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Người ấy sẽ thấy ngay sau vài giây',
                style: TextStyle(fontSize: 12.5, color: C.muted)),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: avatarEmojis.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (_, i) {
                  final e = avatarEmojis[i];
                  final sel = e == current;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, e),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? C.pink.withOpacity(0.18) : C.soft,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel ? C.pink : Colors.transparent,
                            width: 2),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Dùng chữ cái đầu của tên'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// 5. MOOD SYNC
// ============================================================
class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final String today = ymd(DateTime.now());
  int _level = 3;
  final Set<String> _tags = {};
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final m = Store.moodOf('me', today);
    if (m != null) {
      _level = m.level;
      _tags.addAll(m.tags);
      _noteCtrl.text = m.note;
    }
    Sync.status.addListener(_onSync);
    Sync.revision.addListener(_onSync);
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Sync.status.removeListener(_onSync);
    Sync.revision.removeListener(_onSync);
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await Store.saveMood(
      'me',
      MoodEntry(
          date: today,
          level: _level,
          tags: _tags.toList(),
          note: _noteCtrl.text.trim()),
    );
    if (!mounted) return;
    setState(() {});
    toast(context, 'Đã lưu và gửi cho ${Store.partnerName}');
  }

  Future<void> _refresh() async {
    final msg = await Sync.pullAll();
    if (!mounted) return;
    setState(() {});
    toast(context, msg);
  }

  int _daysTogether() {
    if (Store.loveStart.isEmpty) return 0;
    return DateTime.now().difference(parseYmd(Store.loveStart)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final mine = Store.moodOf('me', today);
    final theirs = Store.moodOf('partner', today);
    final days = _daysTogether();

    return RefreshIndicator(
      color: C.pink,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          PageHeader(
            title: 'LoveSync',
            subtitle: days > 0
                ? 'Chúng mình đã bên nhau $days ngày'
                : 'Đồng bộ cảm xúc mỗi ngày',
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Đồng bộ ngay',
                onPressed: _refresh,
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),

          if (!Sync.enabled)
            Section(
              child: Row(
                children: [
                  const Text('🔗', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Chưa ghép đôi. Vào Cài đặt để kết nối với người ấy.',
                      style: TextStyle(fontSize: 13, color: C.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                      if (mounted) setState(() {});
                    },
                    child: const Text('Ghép đôi'),
                  ),
                ],
              ),
            ),

          // Cap doi hom nay
          Section(
            title: 'Hôm nay ${pretty(today)}',
            child: Row(
              children: [
                Expanded(
                    child: _personTile(Store.myName, Store.myAvatar, mine, true)),
                Container(
                  width: 44,
                  alignment: Alignment.center,
                  child: const Text('💞', style: TextStyle(fontSize: 24)),
                ),
                Expanded(
                    child: _personTile(
                        Store.partnerName, Store.partnerAvatar, theirs, false)),
              ],
            ),
          ),

          if (mine != null && theirs != null) _syncBanner(mine, theirs),

          // Nhap cam xuc
          Section(
            title: 'Hôm nay bạn thấy thế nào?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) {
                    final sel = _level == i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _level = i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 58,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: sel ? C.grad : null,
                          color: sel ? null : C.soft.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(moodEmoji[i],
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : C.muted)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(moodLabel[_level - 1],
                      style: const TextStyle(
                          color: C.muted, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                const Text('Điều gì ảnh hưởng tới bạn?',
                    style: TextStyle(fontSize: 13, color: C.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: moodTags.map((t) {
                    final sel = _tags.contains(t);
                    return GestureDetector(
                      onTap: () =>
                          setState(() => sel ? _tags.remove(t) : _tags.add(t)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? C.pink.withOpacity(0.15) : C.soft,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: sel ? C.pink : Colors.transparent),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: sel ? C.pink : C.muted)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Viết vài dòng cho người ấy đọc...'),
                ),
                const SizedBox(height: 14),
                GradientButton(
                    label: 'Lưu cảm xúc hôm nay',
                    icon: Icons.favorite,
                    onTap: _save),
              ],
            ),
          ),

          // Bieu do 7 ngay
          Section(title: '7 ngày gần nhất', child: _weekChart()),

          if (Sync.status.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text(Sync.status.value,
                    style: const TextStyle(fontSize: 11.5, color: C.muted)),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _personTile(String name, String avatar, MoodEntry? m, bool isMe) {
    final color = isMe ? C.pink : C.purple;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 72,
            height: 66,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Avatar(emoji: avatar, name: name, size: 60, ring: color),
                Positioned(
                  right: 2,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(m == null ? '❔' : moodEmoji[m.level - 1],
                        style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(m == null ? 'Chưa ghi nhận' : moodLabel[m.level - 1],
              style: const TextStyle(fontSize: 12, color: C.muted)),
          if (m != null && m.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text('"${m.note}"',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: C.muted,
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  Widget _syncBanner(MoodEntry a, MoodEntry b) {
    final gap = (a.level - b.level).abs();
    final sync = ((1 - gap / 4) * 100).round();
    String msg;
    if (gap == 0) {
      msg = 'Hai bạn đang cùng một nhịp cảm xúc. Giữ nhé!';
    } else if (gap == 1) {
      msg = 'Khá đồng điệu. Một tin nhắn nhỏ là đủ để kéo gần thêm.';
    } else if (gap == 2) {
      msg = 'Có chút lệch nhịp. Hãy hỏi người ấy hôm nay thế nào.';
    } else {
      msg = 'Lệch nhịp rõ rệt. Một cuộc gọi lúc này quan trọng hơn tin nhắn.';
    }
    return Section(
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: sync / 100,
                  strokeWidth: 6,
                  backgroundColor: C.soft,
                  valueColor: const AlwaysStoppedAnimation(C.pink),
                ),
                Text('$sync%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mức đồng điệu hôm nay',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(msg,
                    style: const TextStyle(fontSize: 12.5, color: C.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekChart() {
    final days = List.generate(
        7, (i) => ymd(DateTime.now().subtract(Duration(days: 6 - i))));
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final me = Store.moodOf('me', d)?.level ?? 0;
          final pa = Store.moodOf('partner', d)?.level ?? 0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _bar(me, C.pink),
                    const SizedBox(width: 3),
                    _bar(pa, C.purple),
                  ],
                ),
                const SizedBox(height: 6),
                Text(d.substring(8),
                    style: const TextStyle(fontSize: 10.5, color: C.muted)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _bar(int level, Color color) {
    final h = level == 0 ? 6.0 : 16.0 * level;
    return Container(
      width: 10,
      height: h,
      decoration: BoxDecoration(
        color: level == 0 ? C.soft : color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ============================================================
// 6. AI COACH (Gemini API)
// ============================================================
class GeminiService {
  static const model = 'gemini-2.0-flash';

  static Future<String> ask(String prompt) async {
    final key = Store.apiKey.trim();
    if (key.isEmpty) {
      return '⚠️ Chưa có API key.\n\nVào Cài đặt → dán Gemini API key (lấy miễn phí tại aistudio.google.com/apikey) để bật AI Coach.';
    }
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key');
    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {'temperature': 0.9, 'maxOutputTokens': 900}
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (res.statusCode != 200) {
        return 'Không gọi được AI (mã ${res.statusCode}). Kiểm tra lại API key hoặc kết nối mạng.';
      }
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final cands = data['candidates'] as List?;
      if (cands == null || cands.isEmpty) {
        return 'AI chưa trả lời được, thử lại nhé.';
      }
      final parts = (cands.first['content']?['parts'] as List?) ?? [];
      final text = parts.map((e) => (e['text'] ?? '').toString()).join();
      return text.trim().isEmpty
          ? 'AI chưa trả lời được, thử lại nhé.'
          : text.trim();
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }
}

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  bool _loading = false;
  String _answer = '';
  final _askCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _answer = Store.str('last_advice');
  }

  @override
  void dispose() {
    _askCtrl.dispose();
    super.dispose();
  }

  String _context() {
    final b = StringBuffer();
    b.writeln('Tên tôi: ${Store.myName}. Tên người yêu: ${Store.partnerName}.');
    if (Store.loveStart.isNotEmpty) {
      final d = DateTime.now().difference(parseYmd(Store.loveStart)).inDays;
      b.writeln('Chúng tôi đã yêu nhau $d ngày.');
    }
    b.writeln('\nNhật ký cảm xúc 7 ngày gần nhất (thang 1-5):');
    for (var i = 0; i < 7; i++) {
      final d = ymd(DateTime.now().subtract(Duration(days: i)));
      final me = Store.moodOf('me', d);
      final pa = Store.moodOf('partner', d);
      if (me == null && pa == null) continue;
      b.writeln(
          '- ${pretty(d)} | Tôi: ${me == null ? "chưa ghi" : "${me.level}/5 ${me.tags.join(", ")} ${me.note}"}'
          ' | ${Store.partnerName}: ${pa == null ? "chưa ghi" : "${pa.level}/5 ${pa.tags.join(", ")} ${pa.note}"}');
    }
    return b.toString();
  }

  Future<void> _run(String task) async {
    setState(() => _loading = true);
    final prompt = '''
Bạn là "AI Relationship Coach" của ứng dụng LoveSync — một chuyên gia tâm lý tình yêu người Việt, ấm áp, thực tế, không giáo điều, không phán xét.

DỮ LIỆU CẶP ĐÔI:
${_context()}

NHIỆM VỤ: $task

YÊU CẦU TRẢ LỜI:
- Viết tiếng Việt, giọng gần gũi như một người bạn tinh tế.
- Ngắn gọn, tối đa 250 từ, chia mục rõ ràng, có emoji vừa phải.
- Luôn có ít nhất 1 hành động cụ thể làm được ngay hôm nay.
- Nếu dữ liệu còn thiếu, cứ đưa lời khuyên chung nhưng đừng nhắc đi nhắc lại là thiếu dữ liệu.
- Không chẩn đoán tâm lý, không khuyên chia tay.
''';
    final res = await GeminiService.ask(prompt);
    await Store.setStr('last_advice', res);
    if (!mounted) return;
    setState(() {
      _answer = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const PageHeader(
          title: 'AI Coach',
          subtitle: 'Đọc cảm xúc của cả hai và gợi ý cách quan tâm',
        ),
        Section(
          title: 'Chọn điều bạn cần',
          child: Column(
            children: [
              _actionTile(
                '💗',
                'Phân tích tâm trạng cặp đôi',
                'Đọc dữ liệu 7 ngày và chỉ ra điều đang diễn ra',
                'Phân tích tâm trạng của cả hai trong tuần qua: xu hướng, điểm lệch nhịp, nguyên nhân có thể, và tôi nên làm gì.',
              ),
              _actionTile(
                '💬',
                'Gợi ý chủ đề trò chuyện',
                '5 câu hỏi mở để nói chuyện tối nay',
                'Gợi ý 5 chủ đề / câu hỏi mở để tôi bắt chuyện với người yêu tối nay, bám sát tâm trạng gần đây của cả hai.',
              ),
              _actionTile(
                '🎁',
                'Cách quan tâm hôm nay',
                'Hành động nhỏ, chi phí thấp, hiệu quả cao',
                'Gợi ý 3 hành động quan tâm cụ thể tôi có thể làm hôm nay cho người yêu, phù hợp tâm trạng hiện tại, chi phí thấp.',
              ),
              _actionTile(
                '🤝',
                'Hoà giải sau cãi vã',
                'Cách mở lời khi cả hai đang căng',
                'Chúng tôi vừa có mâu thuẫn. Hướng dẫn tôi cách mở lời hoà giải, kèm 2 mẫu tin nhắn xin lỗi chân thành.',
              ),
            ],
          ),
        ),
        Section(
          title: 'Hỏi Coach điều khác',
          child: Column(
            children: [
              TextField(
                controller: _askCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText:
                        'VD: Người ấy đang áp lực công việc, mình nên nói gì?'),
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: 'Gửi câu hỏi',
                icon: Icons.send_rounded,
                loading: _loading,
                onTap: () {
                  final q = _askCtrl.text.trim();
                  if (q.isEmpty) {
                    toast(context, 'Nhập câu hỏi trước nhé');
                    return;
                  }
                  FocusScope.of(context).unfocus();
                  _run(q);
                },
              ),
            ],
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: C.pink)),
          ),
        if (_answer.isNotEmpty && !_loading)
          Section(
            title: 'Lời khuyên từ Coach',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(_answer,
                    style: const TextStyle(height: 1.55, fontSize: 14.5)),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _answer));
                    toast(context, 'Đã copy');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy nội dung'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _actionTile(String emoji, String title, String sub, String task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _loading ? null : () => _run(task),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.soft.withOpacity(0.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: const TextStyle(fontSize: 12, color: C.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: C.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 7. SETTINGS + GHEP DOI
// ============================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _me = TextEditingController(text: Store.myName);
  late final _partner = TextEditingController(text: Store.partnerName);
  late final _key = TextEditingController(text: Store.apiKey);
  late final _db = TextEditingController(text: Store.str('db_url'));
  late final _code = TextEditingController(text: Store.str('pair_code'));
  String _start = Store.loveStart;
  bool _connecting = false;

  @override
  void dispose() {
    _me.dispose();
    _partner.dispose();
    _key.dispose();
    _db.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Ghi du lieu xuong may. Dung chung cho nut Luu va luc thoat man hinh.
  Future<void> _writeProfile() async {
    await Store.setStr('partner_name',
        _partner.text.trim().isEmpty ? 'Người ấy' : _partner.text.trim());
    await Store.setStr('gemini_key', _key.text.trim());
    await Store.setStr('love_start', _start);
    await Store.setStr('db_url', _db.text.trim());
    await Store.setStr('pair_code', _code.text.trim());
    await Store.saveProfile(
        name: _me.text.trim().isEmpty ? 'Tôi' : _me.text.trim());
  }

  Future<void> _saveProfile() async {
    await _writeProfile();
    Sync.startAuto();
    if (!mounted) return;
    setState(() {});
    toast(context, 'Đã lưu và gửi sang máy người ấy');
  }

  Future<void> _chooseAvatar() async {
    final e = await pickAvatarEmoji(context, Store.myAvatar);
    if (e == null) return; // nguoi dung dong bang chon
    await Store.saveProfile(avatar: e);
    if (!mounted) return;
    setState(() {});
    toast(context, e.isEmpty ? 'Đã gỡ ảnh đại diện' : 'Đã đổi ảnh đại diện');
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    await Store.setStr('db_url', _db.text.trim());
    await Store.setStr('pair_code', _code.text.trim());
    final msg = await Sync.pullAll();
    Sync.startAuto();
    if (!mounted) return;
    setState(() {
      _connecting = false;
      _partner.text = Store.partnerName;
    });
    toast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Bam mui ten quay lai -> tu dong luu, khong lo mat du lieu vua nhap
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _writeProfile();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cài đặt'),
          actions: [
            TextButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check, size: 18, color: C.pink),
              label: const Text('Lưu',
                  style: TextStyle(
                      color: C.pink, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: ListView(
        children: [
          Section(
            title: 'Hai chúng mình',
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _chooseAvatar,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Avatar(
                              emoji: Store.myAvatar,
                              name: _me.text,
                              size: 72),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                  gradient: C.grad, shape: BoxShape.circle),
                              child: const Icon(Icons.edit,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ảnh đại diện của bạn',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          const Text(
                              'Chạm để chọn emoji. Người ấy sẽ thấy sau vài giây.',
                              style: TextStyle(fontSize: 12, color: C.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: _me,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Tên bạn')),
                const SizedBox(height: 12),
                TextField(
                  controller: _partner,
                  decoration: InputDecoration(
                    labelText: 'Tên người ấy',
                    helperText: Sync.enabled
                        ? 'Đã ghép đôi — tên và ảnh sẽ tự cập nhật theo máy của người ấy'
                        : null,
                    helperMaxLines: 2,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Avatar(
                          emoji: Store.partnerAvatar,
                          name: _partner.text,
                          size: 32,
                          ring: C.purple),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate:
                          _start.isEmpty ? DateTime.now() : parseYmd(_start),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _start = ymd(d));
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: C.soft.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: C.muted),
                        const SizedBox(width: 12),
                        Text(_start.isEmpty
                            ? 'Chọn ngày bắt đầu yêu'
                            : 'Yêu nhau từ ${pretty(_start)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GradientButton(
                    label: 'Lưu thông tin',
                    icon: Icons.check,
                    onTap: _saveProfile),
              ],
            ),
          ),

          // ---------- GHEP DOI ----------
          Section(
            title: 'Ghép đôi (đồng bộ tự động)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Sync.enabled
                        ? Colors.green.withOpacity(0.10)
                        : C.soft.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          Sync.enabled
                              ? Icons.link_rounded
                              : Icons.link_off_rounded,
                          size: 18,
                          color: Sync.enabled ? Colors.green : C.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          Sync.enabled
                              ? 'Đang bật. Dữ liệu tự đồng bộ mỗi 30 giây.'
                              : 'Chưa bật. Nhập Database URL và mã cặp đôi bên dưới.',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _db,
                  decoration: const InputDecoration(
                    labelText: 'Firebase Database URL',
                    hintText: 'https://ten-project-default-rtdb.firebaseio.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  decoration: InputDecoration(
                    labelText: 'Mã cặp đôi (tối thiểu 12 ký tự)',
                    suffixIcon: IconButton(
                      tooltip: 'Tạo mã ngẫu nhiên',
                      icon: const Icon(Icons.casino_outlined),
                      onPressed: () =>
                          setState(() => _code.text = Sync.randomCode()),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hai máy phải nhập GIỐNG HỆT cả URL lẫn mã cặp đôi. Ai biết mã là đọc được dữ liệu, nên đừng đăng mã lên chỗ công khai.',
                  style: TextStyle(fontSize: 11.5, color: C.muted, height: 1.5),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: 'Kết nối & đồng bộ ngay',
                  icon: Icons.sync,
                  loading: _connecting,
                  onTap: _connect,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            'LoveSync — cài app rồi nhập 2 dòng này vào Cài đặt:\n'
                            'Database URL: ${_db.text.trim()}\n'
                            'Mã cặp đôi: ${_code.text.trim()}'));
                    toast(context, 'Đã copy, gửi cho người ấy nhé');
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Copy thông tin kết nối'),
                ),
              ],
            ),
          ),

          Section(
            title: 'AI Coach (Gemini)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _key,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Gemini API key', hintText: 'AIza...'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lấy key miễn phí tại aistudio.google.com/apikey. Key chỉ lưu trên máy bạn.',
                  style: TextStyle(fontSize: 12, color: C.muted),
                ),
                const SizedBox(height: 14),
                GradientButton(
                    label: 'Lưu API key',
                    icon: Icons.check,
                    onTap: _saveProfile),
              ],
            ),
          ),

          Section(
            child: TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Xoá dữ liệu trên máy này?'),
                    content: const Text(
                        'Dữ liệu trên Firebase vẫn còn. Nhập lại mã cặp đôi là lấy về được.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Huỷ')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Xoá')),
                    ],
                  ),
                );
                if (ok == true) {
                  Sync.stopAuto();
                  await Store.p.clear();
                  await Store.init();
                  if (!mounted) return;
                  toast(context, 'Đã xoá dữ liệu trên máy');
                  setState(() {});
                }
              },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text('Xoá dữ liệu trên máy này',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
