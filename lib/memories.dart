// LoveSync - memories.dart (ban khong dung GPS)
// Ky niem: nhap dia diem bang tay, thoi gian tu dong, chup/chon anh, ghi chu.
// Da go geolocator / geocoding / flutter_map de build APK on dinh.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart';
import 'sync.dart';
import 'extras.dart' show EmptyState;

// ============================================================
// MODEL
// ============================================================
class Memory {
  final String id;
  final String place; // ten dia diem, nguoi dung tu nhap
  final String at; // ISO8601 - tu dong gan luc luu
  final String photoPath; // anh goc tren may nay
  final String thumb; // anh thu nho base64 -> dong bo sang may kia
  final String note;
  final String by; // ai la nguoi ghim

  Memory({
    required this.id,
    required this.place,
    required this.at,
    this.photoPath = '',
    this.thumb = '',
    this.note = '',
    this.by = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'place': place,
        'at': at,
        'photoPath': photoPath,
        'thumb': thumb,
        'note': note,
        'by': by,
      };

  factory Memory.fromJson(Map<String, dynamic> j) => Memory(
        id: (j['id'] ?? '').toString(),
        place: (j['place'] ?? '').toString(),
        // Tuong thich ban cu: truoc day dung khoa 'date'
        at: (j['at'] ?? j['date'] ?? '').toString(),
        photoPath: (j['photoPath'] ?? '').toString(),
        thumb: (j['thumb'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        by: (j['by'] ?? '').toString(),
      );

  DateTime get time => DateTime.tryParse(at) ?? DateTime.now();
  bool get hasPhoto => photoPath.isNotEmpty || thumb.isNotEmpty;

  /// Anh de hien thi: uu tien file goc, khong co thi dung thumb dong bo ve.
  Widget photo({double? w, double? h, BoxFit fit = BoxFit.cover}) {
    if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
      return Image.file(File(photoPath), width: w, height: h, fit: fit);
    }
    if (thumb.isNotEmpty) {
      try {
        return Image.memory(base64Decode(thumb),
            width: w, height: h, fit: fit, gaplessPlayback: true);
      } catch (_) {}
    }
    return Container(
      width: w,
      height: h,
      color: C.soft,
      alignment: Alignment.center,
      child: const Icon(Icons.photo_outlined, color: C.muted),
    );
  }
}

class MemoryStore {
  static List<Memory> all() {
    final list = Store.listMap('memories').map(Memory.fromJson).toList();
    list.sort((a, b) => b.at.compareTo(a.at)); // moi nhat len dau
    return list;
  }

  static Future<void> add(Memory m) async {
    final list = all()..insert(0, m);
    await Store.setListMap('memories', list.map((e) => e.toJson()).toList());
  }

  static Future<void> remove(String id) async {
    final list = all().where((e) => e.id != id).toList();
    await Store.setListMap('memories', list.map((e) => e.toJson()).toList());
  }
}

String prettyDateTime(DateTime d) =>
    '${two(d.day)}/${two(d.month)}/${d.year} • ${two(d.hour)}:${two(d.minute)}';

/// Goi y dia diem gan day de bam 1 cham thay vi go lai.
List<String> recentPlaces() {
  final seen = <String>[];
  for (final m in MemoryStore.all()) {
    if (m.place.isNotEmpty && !seen.contains(m.place)) seen.add(m.place);
    if (seen.length >= 6) break;
  }
  return seen;
}

// ============================================================
// TAB TIMELINE
// ============================================================
class MemoryTab extends StatefulWidget {
  const MemoryTab({super.key});
  @override
  State<MemoryTab> createState() => _MemoryTabState();
}

class _MemoryTabState extends State<MemoryTab> {
  @override
  void initState() {
    super.initState();
    Sync.revision.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Sync.revision.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _openAdd() async {
    final ok = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const AddMemoryScreen()));
    if (ok == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = MemoryStore.all();
    final places = list.map((e) => e.place).where((e) => e.isNotEmpty).toSet();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Section(
                padding: const EdgeInsets.all(0),
                child: Container(
                  height: 118,
                  decoration: BoxDecoration(
                    gradient: C.grad,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💞', style: TextStyle(fontSize: 26)),
                        const SizedBox(height: 6),
                        Text(
                            list.isEmpty
                                ? 'Chưa có kỷ niệm nào'
                                : '${list.length} kỷ niệm • ${places.length} nơi đã đi qua',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                child: GradientButton(
                  label: 'Ghim khoảnh khắc này',
                  icon: Icons.add_a_photo_outlined,
                  onTap: _openAdd,
                ),
              ),
            ],
          ),
        ),

        if (list.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              emoji: '📍',
              text:
                  'Đang đi chơi cùng nhau?\nBấm nút trên, chụp một tấm và viết vài dòng.',
            ),
          )
        else
          // Luoi o vuong kieu Locket: nhin duoc nhieu ky niem cung luc,
          // cham vao mot o de xem anh lon va ghi chu day du.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _gridTile(list, i),
                childCount: list.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _gridTile(List<Memory> list, int i) {
    final m = list[i];
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => MemoryDetailScreen(items: list, index: i)),
        );
        if (changed == true && mounted) setState(() {});
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (m.hasPhoto)
              m.photo()
            else
              Container(
                decoration: BoxDecoration(gradient: C.gradSoft),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: Text(
                  m.note.isNotEmpty ? m.note : m.place,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, color: C.ink, height: 1.35),
                ),
              ),
            // Dai mo duoi de chu ngay luon doc duoc
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(m.hasPhoto ? 0.55 : 0.30),
                    ],
                  ),
                ),
                child: Text(
                  '${two(m.time.day)}/${two(m.time.month)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAN HINH XEM CHI TIET (vuot ngang de xem ky niem truoc/sau)
// ============================================================
class MemoryDetailScreen extends StatefulWidget {
  final List<Memory> items;
  final int index;
  const MemoryDetailScreen(
      {super.key, required this.items, required this.index});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  late final PageController _page = PageController(initialPage: widget.index);
  late List<Memory> _items = List.of(widget.items);
  bool _changed = false;
  late int _cur = widget.index;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _delete(Memory m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá kỷ niệm này?'),
        content: const Text('Ảnh và ghi chú sẽ mất trên cả hai máy.'),
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
    if (ok != true) return;
    await MemoryStore.remove(m.id);
    if (!mounted) return;
    _changed = true;
    setState(() => _items = MemoryStore.all());
    if (_items.isEmpty) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('${_cur + 1}/${_items.length}',
              style: const TextStyle(fontSize: 15)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(_items[_cur]),
            ),
          ],
        ),
        body: PageView.builder(
          controller: _page,
          itemCount: _items.length,
          onPageChanged: (i) => setState(() => _cur = i),
          itemBuilder: (_, i) {
            final m = _items[i];
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m.hasPhoto)
                    // Cho phep phong to thu nho bang hai ngon tay
                    InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: SizedBox(
                        width: double.infinity,
                        child: m.photo(fit: BoxFit.fitWidth),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.place, size: 17, color: C.pink),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                m.place.isEmpty
                                    ? 'Không ghi địa điểm'
                                    : m.place,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 14, color: C.lilac),
                            const SizedBox(width: 6),
                            Text(prettyDateTime(m.time),
                                style: const TextStyle(
                                    fontSize: 12.5, color: C.lilac)),
                            if (m.by.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text('• ${m.by} ghim',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white54)),
                              ),
                            ],
                          ],
                        ),
                        if (m.note.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(m.note,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.6)),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// MAN HINH THEM KY NIEM
// ============================================================
class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});
  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _place = TextEditingController();
  final _note = TextEditingController();
  final DateTime _at = DateTime.now(); // tu dong gan luc mo man hinh

  String _photoPath = '';
  String _thumb = '';
  bool _saving = false;

  @override
  void dispose() {
    _place.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final file = await ImagePicker().pickImage(
        source: src,
        maxWidth: 1280,
        imageQuality: 82,
      );
      if (file == null) return;

      // Copy ra thu muc rieng cua app de anh khong bi he thong don dep
      final dir = await getApplicationDocumentsDirectory();
      final name = 'mem_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(file.path).copy('${dir.path}/$name');
      final thumb = await _makeThumb(file.path);

      if (!mounted) return;
      setState(() {
        _photoPath = saved.path;
        _thumb = thumb;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, 'Không lấy được ảnh: $e');
    }
  }

  /// Tao anh thu nho (~15KB) de day len Firebase cho may nguoi kia xem.
  Future<String> _makeThumb(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return '';
      final small = img.copyResize(decoded, width: 280);
      return base64Encode(img.encodeJpg(small, quality: 55));
    } catch (_) {
      return ''; // that bai thi anh van con tren may nay
    }
  }

  Future<void> _save() async {
    if (_note.text.trim().isEmpty &&
        _photoPath.isEmpty &&
        _place.text.trim().isEmpty) {
      toast(context, 'Thêm ảnh hoặc vài dòng ghi chú nhé');
      return;
    }
    setState(() => _saving = true);
    await MemoryStore.add(Memory(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Store.str('uid')}',
      place: _place.text.trim(),
      at: _at.toIso8601String(),
      photoPath: _photoPath,
      thumb: _thumb,
      note: _note.text.trim(),
      by: Store.myName,
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoPath.isNotEmpty;
    final goiY = recentPlaces();

    return Scaffold(
      appBar: AppBar(title: const Text('Ghim kỷ niệm')),
      body: ListView(
        children: [
          // --- Thoi gian tu dong
          Section(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: C.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.schedule, color: C.purple),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thời gian',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${prettyDateTime(_at)}  (tự động)',
                          style:
                              const TextStyle(fontSize: 12.5, color: C.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Dia diem nhap tay
          Section(
            title: 'Ở đâu?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _place,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'VD: Cà phê Cộng, Quận 7',
                    prefixIcon: Icon(Icons.place_outlined, color: C.muted),
                  ),
                ),
                if (goiY.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Nơi đã ghim trước đây',
                      style: TextStyle(fontSize: 12, color: C.muted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: goiY
                        .map((p) => GestureDetector(
                              onTap: () => setState(() => _place.text = p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: C.soft,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(p,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: C.muted)),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          // --- Anh
          Section(
            title: 'Hình ảnh',
            child: Column(
              children: [
                if (hasPhoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.file(File(_photoPath), fit: BoxFit.cover),
                    ),
                  ),
                if (hasPhoto) const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('Chụp ảnh'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Thư viện'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Ghi chu
          Section(
            title: 'Hôm nay có gì đáng nhớ?',
            child: TextField(
              controller: _note,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'Viết lại cảm xúc, câu nói, món đã ăn...'),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            child: GradientButton(
              label: 'Lưu kỷ niệm',
              icon: Icons.favorite,
              loading: _saving,
              onTap: _save,
            ),
          ),
        ],
      ),
    );
  }
}
