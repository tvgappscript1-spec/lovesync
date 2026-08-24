// LoveSync - chat.dart
// Nhan tin giua hai nguoi, dung chung Firebase Realtime Database qua REST.
// Khi dang o man hinh nay thi tu tai tin moi moi 5 giay.
import 'dart:async';

import 'package:flutter/material.dart';

import 'main.dart';
import 'sync.dart';

/// Nhung cau hay dung, cham la gui luon.
const List<String> quickNotes = [
  '❤️',
  '🤗',
  'Nhớ nè',
  'Ăn cơm chưa?',
  'Đang làm gì đó?',
  'Về tới chưa?',
  'Cố lên nha',
  'Yêu bạn ❤️',
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    Sync.revision.addListener(_onSync);
    // Dang mo tab chat -> tai tin moi nhanh hon binh thuong
    _poll = Timer.periodic(const Duration(seconds: 5), (_) async {
      await Sync.pullChat();
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Sync.markChatRead();
      _toBottom(jump: true);
    });
  }

  void _onSync() {
    if (!mounted) return;
    setState(() {});
    Sync.markChatRead();
  }

  @override
  void dispose() {
    _poll?.cancel();
    Sync.revision.removeListener(_onSync);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (jump) {
      _scroll.jumpTo(max);
    } else {
      _scroll.animateTo(max,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    final err = await Sync.sendMessage(text);
    if (!mounted) return;
    setState(() => _sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
    if (err != null) toast(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final msgs = Store.listMap('chat')
      ..sort((a, b) =>
          ((a['ts'] as num?) ?? 0).compareTo((b['ts'] as num?) ?? 0));

    return Column(
      children: [
        _header(),
        Expanded(
          child: msgs.isEmpty ? _empty() : _list(msgs),
        ),
        _quickRow(),
        _inputBar(),
      ],
    );
  }

  // ---------- Header ----------
  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Avatar(
              emoji: Store.partnerAvatar,
              name: Store.partnerName,
              size: 46,
              ring: C.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Store.partnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Sync.enabled ? const Color(0xFF6FCF97) : C.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                        Sync.enabled
                            ? 'Đang kết nối'
                            : 'Chưa ghép đôi',
                        style: const TextStyle(fontSize: 12, color: C.muted)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tải tin mới',
            icon: const Icon(Icons.refresh, color: C.muted),
            onPressed: () async {
              await Sync.pullChat();
              if (!mounted) return;
              setState(() {});
              _toBottom();
            },
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return ListView(
      children: [
        const SizedBox(height: 40),
        const Center(child: Text('💌', style: TextStyle(fontSize: 52))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Text(
            Sync.enabled
                ? 'Chưa có tin nhắn nào.\nGửi câu đầu tiên cho ${Store.partnerName} đi.'
                : 'Vào Cài đặt ghép đôi trước, rồi hai bạn nhắn tin được ngay.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: C.muted, fontSize: 14, height: 1.6),
          ),
        ),
      ],
    );
  }

  // ---------- Danh sach tin ----------
  Widget _list(List<Map<String, dynamic>> msgs) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      itemCount: msgs.length,
      itemBuilder: (_, i) {
        final m = msgs[i];
        final mine = m['by'] == Sync.uid;
        final ts = ((m['ts'] as num?) ?? 0).toInt();
        final time = DateTime.fromMillisecondsSinceEpoch(ts);

        // Hien dai ngay khi sang ngay moi
        final prevTs = i == 0 ? 0 : ((msgs[i - 1]['ts'] as num?) ?? 0).toInt();
        final prevDay = DateTime.fromMillisecondsSinceEpoch(prevTs);
        final newDay = i == 0 ||
            time.day != prevDay.day ||
            time.month != prevDay.month;

        // Tin chi co emoji thi phong to, bo bong bong
        final text = (m['text'] ?? '').toString();
        final onlyEmoji = text.runes.length <= 3 &&
            RegExp(r'^[\p{Emoji}\s]+$', unicode: true).hasMatch(text);

        return Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (newDay)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: C.soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                      '${two(time.day)}/${two(time.month)}/${time.year}',
                      style: const TextStyle(fontSize: 11, color: C.muted)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment:
                    mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!mine) ...[
                    Avatar(
                        emoji: (m['avatar'] ?? '').toString(),
                        name: (m['name'] ?? '').toString(),
                        size: 30,
                        ring: C.purple),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: onlyEmoji
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(text,
                                style: const TextStyle(fontSize: 40)),
                          )
                        : Container(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                            decoration: BoxDecoration(
                              gradient: mine ? C.grad : null,
                              color: mine ? null : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(mine ? 20 : 6),
                                bottomRight: Radius.circular(mine ? 6 : 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (mine ? C.pink : C.purple)
                                      .withOpacity(0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(text,
                                    style: TextStyle(
                                        fontSize: 14.5,
                                        height: 1.4,
                                        color:
                                            mine ? Colors.white : C.ink)),
                                const SizedBox(height: 3),
                                Text('${two(time.hour)}:${two(time.minute)}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: mine
                                            ? Colors.white70
                                            : C.muted)),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- Cau gui nhanh ----------
  Widget _quickRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: quickNotes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _send(quickNotes[i]),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: C.gradSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: C.pink.withOpacity(0.28)),
            ),
            child: Text(quickNotes[i],
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: C.pink)),
          ),
        ),
      ),
    );
  }

  // ---------- O nhap ----------
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Nhắn gì đó cho ${Store.partnerName}...',
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: C.soft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: C.pink.withOpacity(0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: C.pink, width: 1.6),
                ),
              ),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _send(_input.text),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: C.grad,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: C.pink.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
