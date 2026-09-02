// LoveSync - wheel.dart
// Vong quay hen ho: chon ngau nhien dia diem / hoat dong cho hai dua.
// Ve bang CustomPainter, quay nhanh roi cham dan nhu co quan tinh.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';
import 'sync.dart';
import 'extras.dart' show inputDialog;

/// Goi y san khi danh sach con trong.
const List<String> defaultWheelItems = [
  'Ăn lẩu',
  'Cà phê view đẹp',
  'Xem phim rạp',
  'Đi dạo công viên',
  'Nấu ăn ở nhà',
  'Ăn vặt vỉa hè',
  'Đi siêu thị chung',
  'Chụp ảnh dạo phố',
];

/// Mau tung mui, xoay vong.
const List<Color> wheelColors = [
  Color(0xFFFFB0C4),
  Color(0xFFBFB4FF),
  Color(0xFFFFD3A5),
  Color(0xFF9FE0CF),
  Color(0xFFFFC2D6),
  Color(0xFFC8BFFF),
  Color(0xFFFFE0B2),
  Color(0xFFB5EAD7),
];

class WheelTab extends StatefulWidget {
  const WheelTab({super.key});
  @override
  State<WheelTab> createState() => _WheelTabState();
}

class _WheelTabState extends State<WheelTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  late Animation<double> _anim = const AlwaysStoppedAnimation(0);

  double _angle = 0; // goc hien tai cua banh xe (radian)
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    Sync.revision.addListener(_onSync);
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Sync.revision.removeListener(_onSync);
    _ctrl.dispose();
    super.dispose();
  }

  // ---------- Du lieu ----------
  List<String> get items {
    final raw = Store.listMap('wheel');
    if (raw.isEmpty) return defaultWheelItems;
    return raw.map((e) => (e['text'] ?? '').toString()).toList();
  }

  Future<void> _saveItems(List<String> list) async {
    await Store.setListMap('wheel', list.map((e) => {'text': e}).toList());
  }

  Future<void> _add() async {
    final r = await inputDialog(context,
        title: 'Thêm vào vòng quay', fields: ['Địa điểm hoặc hoạt động']);
    final t = (r?['Địa điểm hoặc hoạt động'] ?? '').trim();
    if (t.isEmpty) return;
    if (items.length >= 12) {
      if (mounted) toast(context, 'Tối đa 12 ô cho dễ đọc');
      return;
    }
    await _saveItems([...items, t]);
    if (mounted) setState(() {});
  }

  Future<void> _remove(int i) async {
    final list = [...items]..removeAt(i);
    if (list.isEmpty) {
      if (mounted) toast(context, 'Cần ít nhất 1 ô');
      return;
    }
    await _saveItems(list);
    if (mounted) setState(() {});
  }

  // ---------- Quay ----------
  void _spin() {
    if (_spinning) return;
    final list = items;
    if (list.length < 2) {
      toast(context, 'Thêm ít nhất 2 ô rồi hãy quay');
      return;
    }

    HapticFeedback.mediumImpact();
    final rnd = Random();
    // Quay 5-8 vong roi dung o mot goc ngau nhien
    final target =
        _angle + (5 + rnd.nextInt(4)) * 2 * pi + rnd.nextDouble() * 2 * pi;

    _anim = Tween<double>(begin: _angle, end: target).animate(
      // easeOutCubic cho cam giac quay manh roi cham dan nhu co ma sat
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    setState(() => _spinning = true);
    _ctrl.forward(from: 0).whenComplete(() async {
      _angle = target % (2 * pi);
      final picked = _itemAtPointer(_angle, list.length);
      await _saveResult(list[picked]);
      if (!mounted) return;
      setState(() => _spinning = false);
      HapticFeedback.heavyImpact();
      _showResult(list[picked]);
    });
  }

  /// Kim chi nam o dinh (goc -pi/2). Tinh xem mui nao dang o do.
  /// Mui i bat dau tai -pi/2 + i*sector + angle, nen mui phu kim la mui
  /// thoa (i*sector + angle) vua vuot qua mot vong -> dung ceil, khong dung floor.
  int _itemAtPointer(double angle, int n) {
    final sector = 2 * pi / n;
    final a = angle % (2 * pi);
    return (n - (a / sector).ceil()) % n;
  }

  Future<void> _saveResult(String text) async {
    await Store.setMap('wheel_last', {
      'text': text,
      'by': Store.myName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _showResult(String text) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            gradient: C.grad,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: C.pink.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              const Text('Hôm nay hai đứa',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.3)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _spin();
                      },
                      child: const Text('Quay lại',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: C.pink,
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Chốt!'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = items;
    final last = Store.map('wheel_last');

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Ket qua lan quay gan nhat (dong bo tu ca hai may)
        if ((last['text'] ?? '').toString().isNotEmpty)
          Section(
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${last['text']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${last['by']} vừa quay được',
                          style: const TextStyle(
                              fontSize: 11.5, color: C.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Banh xe
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: 300,
              height: 320,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) {
                        final a = _spinning ? _anim.value : _angle;
                        return CustomPaint(
                          size: const Size(300, 300),
                          painter: _WheelPainter(items: list, angle: a),
                        );
                      },
                    ),
                  ),
                  // Kim chi o dinh
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: CustomPaint(
                      size: const Size(30, 34),
                      painter: _PointerPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: GradientButton(
            label: _spinning ? 'Đang quay...' : 'Quay đi!',
            icon: Icons.refresh_rounded,
            loading: _spinning,
            onTap: _spin,
          ),
        ),

        // Danh sach o
        Section(
          title: 'Các ô trên vòng quay (${list.length})',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(list.length, (i) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                    decoration: BoxDecoration(
                      color: wheelColors[i % wheelColors.length]
                          .withOpacity(0.35),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(list[i],
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: C.ink)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _remove(i),
                          child: const Icon(Icons.close,
                              size: 15, color: C.muted),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              GradientButton(
                label: 'Thêm ô mới',
                icon: Icons.add,
                soft: true,
                onTap: _add,
              ),
              const SizedBox(height: 8),
              const Text(
                'Danh sách này đồng bộ sang máy người ấy. Ai sửa thì bên kia cũng thấy.',
                style: TextStyle(fontSize: 11.5, color: C.muted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// VE BANH XE
// ============================================================
class _WheelPainter extends CustomPainter {
  final List<String> items;
  final double angle;
  _WheelPainter({required this.items, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    final n = items.length;
    final sector = 2 * pi / n;

    // Bong do duoi banh xe
    canvas.drawCircle(
      center.translate(0, 4),
      r,
      Paint()
        ..color = C.purple.withOpacity(0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    for (var i = 0; i < n; i++) {
      final start = -pi / 2 + i * sector + angle;

      // Mui quat
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        sector,
        true,
        Paint()..color = wheelColors[i % wheelColors.length],
      );
      // Vach ngan trang
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        sector,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );

      // Chu chay doc theo ban kinh
      final tp = TextPainter(
        text: TextSpan(
          text: items[i],
          style: const TextStyle(
            color: C.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: r * 0.62);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(start + sector / 2);
      tp.paint(canvas, Offset(r * 0.30, -tp.height / 2));
      canvas.restore();
    }

    // Vien ngoai
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white,
    );

    // Nut tam
    canvas.drawCircle(center, 24, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      24,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = C.pink,
    );

    final heart = TextPainter(
      text: const TextSpan(text: '💕', style: TextStyle(fontSize: 20)),
      textDirection: TextDirection.ltr,
    )..layout();
    heart.paint(canvas, center.translate(-heart.width / 2, -heart.height / 2));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.angle != angle || old.items.length != items.length;
}

/// Kim chi hinh giot nuoc huong xuong.
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width * 0.14, size.height * 0.10)
      ..quadraticBezierTo(
          size.width / 2, -size.height * 0.12, size.width * 0.86, size.height * 0.10)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(path, Paint()..color = C.pink);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
