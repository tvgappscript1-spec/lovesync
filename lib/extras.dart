// LoveSync - File 3/3: extras.dart
// Ban do ky niem | Wishlist chung | Lich ky niem | Quy tiet kiem chung
import 'package:flutter/material.dart';
import 'main.dart';
import 'memories.dart';
import 'wheel.dart';

class ExtrasScreen extends StatelessWidget {
  const ExtrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const PageHeader(
            title: 'Của mình',
            subtitle: 'Kỷ niệm, mong ước và mục tiêu chung',
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: C.pink,
            unselectedLabelColor: C.muted,
            indicatorColor: C.pink,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            tabs: [
              Tab(text: 'Kỷ niệm'),
              Tab(text: 'Vòng quay'),
              Tab(text: 'Wishlist'),
              Tab(text: 'Ngày quan trọng'),
              Tab(text: 'Quỹ chung'),
            ],
          ),
          const SizedBox(height: 12),
          const Expanded(
            child: TabBarView(
              children: [
                MemoryTab(),
                WheelTab(),
                _WishlistTab(),
                _EventTab(),
                _SavingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Helper: dialog nhap lieu
// ------------------------------------------------------------
Future<Map<String, String>?> inputDialog(
  BuildContext context, {
  required String title,
  required List<String> fields,
  List<TextInputType>? types,
}) async {
  final ctrls = fields.map((_) => TextEditingController()).toList();
  final res = await showDialog<Map<String, String>>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: const TextStyle(fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < fields.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: ctrls[i],
                keyboardType: types != null && i < types.length
                    ? types[i]
                    : TextInputType.text,
                decoration: InputDecoration(labelText: fields[i]),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ')),
        TextButton(
          onPressed: () {
            final map = <String, String>{};
            for (var i = 0; i < fields.length; i++) {
              map[fields[i]] = ctrls[i].text.trim();
            }
            Navigator.pop(context, map);
          },
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
  for (final c in ctrls) {
    c.dispose();
  }
  return res;
}

class EmptyState extends StatelessWidget {
  final String emoji;
  final String text;
  const EmptyState({super.key, required this.emoji, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, fontSize: 13.5, height: 1.5)),
        ],
      ),
    );
  }
}

Widget addFab(VoidCallback onTap, String label) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    child: GradientButton(label: label, icon: Icons.add, onTap: onTap),
  );
}

// ------------------------------------------------------------
// 2. WISHLIST CHUNG
// ------------------------------------------------------------
class _WishlistTab extends StatefulWidget {
  const _WishlistTab();
  @override
  State<_WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<_WishlistTab> {
  List<Map<String, dynamic>> get items => Store.listMap('wishlist');

  Future<void> _add() async {
    final r = await inputDialog(context,
        title: 'Thêm điều muốn cùng làm',
        fields: ['Điều ước', 'Ghi chú']);
    if (r == null || (r['Điều ước'] ?? '').isEmpty) return;
    final l = items..insert(0, {'title': r['Điều ước'], 'note': r['Ghi chú'], 'done': false});
    await Store.setListMap('wishlist', l);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = items;
    final done = list.where((e) => e['done'] == true).length;
    return ListView(
      children: [
        Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đã hoàn thành $done/${list.length} điều ước',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: list.isEmpty ? 0 : done / list.length,
                  minHeight: 10,
                  backgroundColor: C.soft,
                  valueColor: const AlwaysStoppedAnimation(C.pink),
                ),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          const EmptyState(
              emoji: '✨',
              text: 'Wishlist đang trống.\nThêm điều hai bạn muốn cùng làm năm nay.'),
        ...list.asMap().entries.map((e) {
          final done = e.value['done'] == true;
          return Section(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: CheckboxListTile(
              value: done,
              activeColor: C.pink,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('${e.value['title']}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? C.muted : C.ink,
                  )),
              subtitle: '${e.value['note'] ?? ''}'.isEmpty
                  ? null
                  : Text('${e.value['note']}',
                      style: const TextStyle(fontSize: 12, color: C.muted)),
              secondary: IconButton(
                icon: const Icon(Icons.close, size: 18, color: C.muted),
                onPressed: () async {
                  final l = items..removeAt(e.key);
                  await Store.setListMap('wishlist', l);
                  setState(() {});
                },
              ),
              onChanged: (v) async {
                final l = items;
                l[e.key]['done'] = v ?? false;
                await Store.setListMap('wishlist', l);
                setState(() {});
              },
            ),
          );
        }),
        addFab(_add, 'Thêm điều ước'),
      ],
    );
  }
}

// ------------------------------------------------------------
// 3. LICH KY NIEM
// ------------------------------------------------------------
class _EventTab extends StatefulWidget {
  const _EventTab();
  @override
  State<_EventTab> createState() => _EventTabState();
}

class _EventTabState extends State<_EventTab> {
  List<Map<String, dynamic>> get items => Store.listMap('events');

  int _daysLeft(String date) {
    final d = parseYmd(date);
    final now = DateTime.now();
    var next = DateTime(now.year, d.month, d.day);
    if (next.isBefore(DateTime(now.year, now.month, now.day))) {
      next = DateTime(now.year + 1, d.month, d.day);
    }
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Future<void> _add() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày quan trọng',
    );
    if (picked == null || !mounted) return;
    final r = await inputDialog(context,
        title: 'Ngày ${pretty(ymd(picked))}', fields: ['Tên dịp']);
    if (r == null || (r['Tên dịp'] ?? '').isEmpty) return;
    final l = items..add({'title': r['Tên dịp'], 'date': ymd(picked)});
    l.sort((a, b) => _daysLeft('${a['date']}').compareTo(_daysLeft('${b['date']}')));
    await Store.setListMap('events', l);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = items
      ..sort((a, b) => _daysLeft('${a['date']}').compareTo(_daysLeft('${b['date']}')));
    return ListView(
      children: [
        if (Store.loveStart.isNotEmpty)
          Section(
            child: Row(
              children: [
                const Text('💘', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Đã yêu nhau ${DateTime.now().difference(parseYmd(Store.loveStart)).inDays} ngày',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('Từ ${pretty(Store.loveStart)}',
                          style:
                              const TextStyle(fontSize: 12, color: C.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (list.isEmpty)
          const EmptyState(
              emoji: '🗓️',
              text: 'Chưa có ngày nào được lưu.\nThêm sinh nhật, ngày cưới, ngày quen nhau...'),
        ...list.asMap().entries.map((e) {
          final left = _daysLeft('${e.value['date']}');
          return Section(
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: left <= 7 ? C.grad : null,
                    color: left <= 7 ? null : C.soft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$left',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: left <= 7 ? Colors.white : C.ink)),
                      Text('ngày',
                          style: TextStyle(
                              fontSize: 10,
                              color: left <= 7 ? Colors.white70 : C.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.value['title']}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(pretty('${e.value['date']}'),
                          style:
                              const TextStyle(fontSize: 12, color: C.muted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: C.muted),
                  onPressed: () async {
                    final l = items..removeAt(e.key);
                    await Store.setListMap('events', l);
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        }),
        addFab(_add, 'Thêm ngày quan trọng'),
      ],
    );
  }
}

// ------------------------------------------------------------
// 4. QUY TIET KIEM CHUNG
// ------------------------------------------------------------
class _SavingTab extends StatefulWidget {
  const _SavingTab();
  @override
  State<_SavingTab> createState() => _SavingTabState();
}

class _SavingTabState extends State<_SavingTab> {
  Map<String, dynamic> get fund => Store.map('fund');
  List<Map<String, dynamic>> get logs => Store.listMap('fund_logs');

  double get total =>
      logs.fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));

  String money(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '${b.toString()} đ';
  }

  Future<void> _setGoal() async {
    final r = await inputDialog(context,
        title: 'Mục tiêu chung',
        fields: ['Tên mục tiêu', 'Số tiền cần (đ)'],
        types: [TextInputType.text, TextInputType.number]);
    if (r == null) return;
    await Store.setMap('fund', {
      'name': r['Tên mục tiêu'],
      'target': double.tryParse((r['Số tiền cần (đ)'] ?? '').replaceAll('.', '')) ?? 0,
    });
    setState(() {});
  }

  Future<void> _deposit() async {
    final r = await inputDialog(context,
        title: 'Ghi nhận khoản góp',
        fields: ['Số tiền (đ)', 'Ai góp?'],
        types: [TextInputType.number, TextInputType.text]);
    if (r == null) return;
    final amt = double.tryParse((r['Số tiền (đ)'] ?? '').replaceAll('.', ''));
    if (amt == null || amt <= 0) return;
    final l = logs
      ..insert(0, {
        'amount': amt,
        'who': (r['Ai góp?'] ?? '').isEmpty ? Store.myName : r['Ai góp?'],
        'date': ymd(DateTime.now()),
      });
    await Store.setListMap('fund_logs', l);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final target = (fund['target'] as num?)?.toDouble() ?? 0;
    final name = '${fund['name'] ?? ''}';
    final ratio = target <= 0 ? 0.0 : (total / target).clamp(0.0, 1.0);

    return ListView(
      children: [
        Section(
          padding: const EdgeInsets.all(0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: C.grad,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Chưa đặt mục tiêu' : name,
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(money(total),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
                if (target > 0) ...[
                  const SizedBox(height: 4),
                  Text('trên mục tiêu ${money(target)}  •  ${(ratio * 100).round()}%',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _setGoal,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54)),
                      child: const Text('Đặt mục tiêu'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _deposit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: C.pink,
                          elevation: 0),
                      child: const Text('Góp tiền'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (logs.isEmpty)
          const EmptyState(
              emoji: '🐷',
              text: 'Quỹ chung đang trống.\nGhi nhận khoản góp đầu tiên của hai bạn.'),
        ...logs.asMap().entries.map((e) => Section(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, color: C.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(money((e.value['amount'] as num).toDouble()),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${e.value['who']} • ${pretty('${e.value['date']}')}',
                            style: const TextStyle(
                                fontSize: 12, color: C.muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: C.muted),
                    onPressed: () async {
                      final l = logs..removeAt(e.key);
                      await Store.setListMap('fund_logs', l);
                      setState(() {});
                    },
                  ),
                ],
              ),
            )),
        const SizedBox(height: 24),
      ],
    );
  }
}
