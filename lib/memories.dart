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

    return ListView(
      children: [
        Section(
          padding: const EdgeInsets.all(0),
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: C.grad,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💞', style: TextStyle(fontSize: 30)),
                  const SizedBox(height: 8),
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
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
          child: GradientButton(
            label: 'Ghim khoảnh khắc này',
            icon: Icons.add_a_photo_outlined,
            onTap: _openAdd,
          ),
        ),

        if (list.isEmpty)
          const EmptyState(
            emoji: '📍',
            text:
                'Đang đi chơi cùng nhau?\nBấm nút trên, chụp một tấm và viết vài dòng.',
          ),

        ...list.map(_card),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _card(Memory m) {
    return Section(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.hasPhoto)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                  height: 190, width: double.infinity, child: m.photo()),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: C.pink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        m.place.isEmpty ? 'Không ghi địa điểm' : m.place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: C.muted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await MemoryStore.remove(m.id);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: C.purple),
                    const SizedBox(width: 6),
                    Text(prettyDateTime(m.time),
                        style: const TextStyle(
                            fontSize: 12,
                            color: C.purple,
                            fontWeight: FontWeight.w600)),
                    if (m.by.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('• ${m.by} ghim',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5, color: C.muted)),
                      ),
                    ],
                  ],
                ),
                if (m.note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(m.note,
                      style: const TextStyle(fontSize: 13.5, height: 1.5)),
                ],
              ],
            ),
          ),
        ],
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
