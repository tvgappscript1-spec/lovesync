// LoveSync - memories.dart
// Ban do ky niem: tu dong lay GPS + dia chi, tu gan ngay gio, chup/chon anh, ghi chu.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart';
import 'sync.dart';
import 'extras.dart' show EmptyState;

// ============================================================
// MODEL
// ============================================================
class Memory {
  final String id;
  final double lat;
  final double lng;
  final String place; // ten ngan gon: phuong/quan
  final String address; // dia chi day du
  final String at; // ISO8601 - ngay gio tu dong
  final String photoPath; // anh goc tren may nay
  final String thumb; // anh thu nho base64 -> de dong bo sang may kia
  final String note;
  final String by; // ai la nguoi luu

  Memory({
    required this.id,
    required this.lat,
    required this.lng,
    required this.place,
    required this.address,
    required this.at,
    this.photoPath = '',
    this.thumb = '',
    this.note = '',
    this.by = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'place': place,
        'address': address,
        'at': at,
        'photoPath': photoPath,
        'thumb': thumb,
        'note': note,
        'by': by,
      };

  factory Memory.fromJson(Map<String, dynamic> j) => Memory(
        id: (j['id'] ?? '').toString(),
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        place: (j['place'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        at: (j['at'] ?? '').toString(),
        photoPath: (j['photoPath'] ?? '').toString(),
        thumb: (j['thumb'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        by: (j['by'] ?? '').toString(),
      );

  DateTime get time => DateTime.tryParse(at) ?? DateTime.now();
  bool get hasCoords => lat != 0 || lng != 0;

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

// ============================================================
// TAB TIMELINE  (thay the tab "Ky niem" cu trong extras.dart)
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
    final withCoords = list.where((e) => e.hasCoords).toList();

    return ListView(
      children: [
        // Banner ban do
        Section(
          padding: const EdgeInsets.all(0),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: withCoords.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MemoryMapScreen(items: withCoords)),
                    ),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: C.grad,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined,
                        size: 34, color: Colors.white),
                    const SizedBox(height: 8),
                    Text('${withCoords.length} nơi hai đứa đã đi qua',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                        withCoords.isEmpty
                            ? 'Ghim kỷ niệm đầu tiên để mở bản đồ'
                            : 'Chạm để xem trên bản đồ',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11.5)),
                  ],
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
          child: GradientButton(
            label: 'Ghim khoảnh khắc này',
            icon: Icons.add_location_alt_outlined,
            onTap: _openAdd,
          ),
        ),

        if (list.isEmpty)
          const EmptyState(
            emoji: '📍',
            text:
                'Chưa có kỷ niệm nào.\nĐang đi chơi cùng nhau? Bấm nút trên, app tự lấy vị trí và thời gian.',
          ),

        ...list.map((m) => _card(m)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _card(Memory m) {
    final hasPhoto = m.photoPath.isNotEmpty || m.thumb.isNotEmpty;
    return Section(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhoto)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: m.photo(),
              ),
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
                        m.place.isEmpty ? 'Không rõ địa điểm' : m.place,
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
                if (m.address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(m.address,
                        style:
                            const TextStyle(fontSize: 12, color: C.muted)),
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
                      Text('• ${m.by} ghim',
                          style:
                              const TextStyle(fontSize: 11.5, color: C.muted)),
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
  final _note = TextEditingController();
  final DateTime _at = DateTime.now(); // tu dong gan luc mo man hinh

  bool _locating = false;
  String _locError = '';
  double? _lat, _lng;
  String _place = '', _address = '';

  String _photoPath = '';
  String _thumb = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _locate(); // tu dong lay vi tri ngay khi mo
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  // ---------- GPS + doi toa do thanh dia chi ----------
  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locError = '';
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Định vị đang tắt. Bật GPS trên điện thoại rồi thử lại.';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        throw 'Bạn chưa cho phép truy cập vị trí.';
      }
      if (perm == LocationPermission.deniedForever) {
        throw 'Quyền vị trí đang bị chặn. Vào Cài đặt hệ thống để mở lại.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;

      // Doi toa do -> dia chi thuc te
      try {
        // geocoding 3.x: dat ngon ngu bang ham rieng, khong con tham so trong ham duoi
        try {
          await setLocaleIdentifier('vi_VN');
        } catch (_) {
          // Thiet bi khong ho tro locale nay thi dung mac dinh
        }
        final marks = await placemarkFromCoordinates(_lat!, _lng!);
        if (marks.isNotEmpty) {
          final p = marks.first;
          final short = [p.subAdministrativeArea, p.administrativeArea]
              .where((e) => (e ?? '').isNotEmpty)
              .join(', ');
          _place = short.isEmpty ? 'Vị trí hiện tại' : short;
          _address = [
            p.street,
            p.subLocality,
            p.locality,
            p.subAdministrativeArea,
            p.administrativeArea,
            p.country
          ].where((e) => (e ?? '').trim().isNotEmpty).join(', ');
        }
      } catch (_) {
        // Khong co mang thi van giu toa do
        _place = 'Vị trí hiện tại';
        _address = '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}';
      }
    } catch (e) {
      _locError = e.toString();
    }
    if (mounted) setState(() => _locating = false);
  }

  // ---------- Anh ----------
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

      // Thu nho de dong bo sang may nguoi kia
      final thumbFile = await _makeThumb(file.path);

      setState(() {
        _photoPath = saved.path;
        _thumb = thumbFile;
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
    if (_note.text.trim().isEmpty && _photoPath.isEmpty && _lat == null) {
      toast(context, 'Thêm ảnh hoặc vài dòng ghi chú nhé');
      return;
    }
    setState(() => _saving = true);
    await MemoryStore.add(Memory(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Store.str('uid')}',
      lat: _lat ?? 0,
      lng: _lng ?? 0,
      place: _place,
      address: _address,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Ghim kỷ niệm')),
      body: ListView(
        children: [
          // --- Vi tri tu dong
          Section(
            title: 'Vị trí',
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: C.pink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _locating
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: C.pink),
                        )
                      : const Icon(Icons.my_location, color: C.pink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _locating
                      ? const Text('Đang lấy vị trí...',
                          style: TextStyle(fontSize: 13, color: C.muted))
                      : _locError.isNotEmpty
                          ? Text(_locError,
                              style: const TextStyle(
                                  fontSize: 12.5, color: Colors.redAccent))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _place.isEmpty
                                        ? 'Chưa có vị trí'
                                        : _place,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                if (_address.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(_address,
                                        style: const TextStyle(
                                            fontSize: 12, color: C.muted)),
                                  ),
                              ],
                            ),
                ),
                IconButton(
                  tooltip: 'Lấy lại vị trí',
                  icon: const Icon(Icons.refresh, color: C.muted),
                  onPressed: _locating ? null : _locate,
                ),
              ],
            ),
          ),

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
                      Text(prettyDateTime(_at),
                          style:
                              const TextStyle(fontSize: 12.5, color: C.muted)),
                    ],
                  ),
                ),
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
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
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

// ============================================================
// MAN HINH BAN DO
// ============================================================
class MemoryMapScreen extends StatefulWidget {
  final List<Memory> items;
  const MemoryMapScreen({super.key, required this.items});
  @override
  State<MemoryMapScreen> createState() => _MemoryMapScreenState();
}

class _MemoryMapScreenState extends State<MemoryMapScreen> {
  final _map = MapController();

  LatLng get _center {
    final lat = widget.items.map((e) => e.lat).reduce((a, b) => a + b) /
        widget.items.length;
    final lng = widget.items.map((e) => e.lng).reduce((a, b) => a + b) /
        widget.items.length;
    return LatLng(lat, lng);
  }

  void _openDetail(Memory m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.photoPath.isNotEmpty || m.thumb.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: m.photo()),
                ),
              const SizedBox(height: 14),
              Text(m.place.isEmpty ? 'Kỷ niệm' : m.place,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${prettyDateTime(m.time)}'
                  '${m.by.isEmpty ? '' : '  •  ${m.by} ghim'}',
                  style: const TextStyle(fontSize: 12.5, color: C.purple)),
              if (m.address.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(m.address,
                    style: const TextStyle(fontSize: 12, color: C.muted)),
              ],
              if (m.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(m.note,
                    style: const TextStyle(fontSize: 14, height: 1.55)),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ kỷ niệm')),
      body: FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 11,
          minZoom: 3,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.lovesync.app',
          ),
          MarkerLayer(
            markers: widget.items
                .map((m) => Marker(
                      point: LatLng(m.lat, m.lng),
                      width: 54,
                      height: 62,
                      child: GestureDetector(
                        onTap: () => _openDetail(m),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: C.pink, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 6)
                                ],
                              ),
                              child: ClipOval(
                                child: (m.photoPath.isNotEmpty ||
                                        m.thumb.isNotEmpty)
                                    ? m.photo(w: 44, h: 44)
                                    : const Icon(Icons.favorite,
                                        color: C.pink, size: 20),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down,
                                color: C.pink, size: 20),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: C.pink,
        onPressed: () => _map.move(_center, 11),
        child: const Icon(Icons.center_focus_strong, color: Colors.white),
      ),
    );
  }
}
