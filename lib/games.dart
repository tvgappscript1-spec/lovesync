// LoveSync - games.dart
// Co ca-ro 9x9, thang khi co 5 quan lien tiep. Hai may danh luan phien
// qua Firebase Realtime Database, tu tai nuoc di moi moi 3 giay.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';
import 'sync.dart';

const int kSize = 9; // ban 9x9
const int kWin = 5; // 5 quan lien tiep la thang

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _poll;
  bool _loading = true;
  bool _sending = false;

  /// Ban co: chuoi 81 ky tu, '.' la o trong, 'x' va 'o' la quan.
  String _board = '.' * (kSize * kSize);
  String _turn = ''; // uid cua nguoi den luot
  String _xUid = ''; // ai cam quan X
  String _oUid = '';
  String _winner = ''; // uid nguoi thang, hoac 'draw'
  List<int> _winLine = []; // cac o tao thanh duong thang
  int _scoreX = 0, _scoreO = 0;
  int _lastMove = -1;

  bool get _iAmX => _xUid == Sync.uid;
  String get _mySymbol => _iAmX ? 'x' : 'o';
  bool get _myTurn => _turn == Sync.uid && _winner.isEmpty;
  bool get _joined => _xUid == Sync.uid || _oUid == Sync.uid;

  @override
  void initState() {
    super.initState();
    _load();
    // Doi phuong danh xong thi may minh thay sau toi da 3 giay
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  // ---------- Dong bo ----------
  Future<void> _load({bool quiet = false}) async {
    final g = await Sync.fetchGame();
    if (!mounted) return;
    if (g == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _board = (g['board'] ?? '.' * (kSize * kSize)).toString();
      _turn = (g['turn'] ?? '').toString();
      _xUid = (g['x'] ?? '').toString();
      _oUid = (g['o'] ?? '').toString();
      _winner = (g['winner'] ?? '').toString();
      _scoreX = ((g['scoreX'] as num?) ?? 0).toInt();
      _scoreO = ((g['scoreO'] as num?) ?? 0).toInt();
      _lastMove = ((g['lastMove'] as num?) ?? -1).toInt();
      _winLine = ((g['winLine'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList();
      _loading = false;
    });
  }

  Map<String, dynamic> _toMap() => {
        'board': _board,
        'turn': _turn,
        'x': _xUid,
        'o': _oUid,
        'winner': _winner,
        'winLine': _winLine,
        'scoreX': _scoreX,
        'scoreO': _scoreO,
        'lastMove': _lastMove,
        'ts': DateTime.now().millisecondsSinceEpoch,
      };

  Future<void> _push() async {
    setState(() => _sending = true);
    await Sync.saveGame(_toMap());
    if (mounted) setState(() => _sending = false);
  }

  // ---------- Van moi ----------
  Future<void> _newGame({bool swap = false}) async {
    // Nguoi bam nut se cam quan X va di truoc, tru khi doi ben
    final me = Sync.uid;
    final other = _xUid == me
        ? _oUid
        : (_oUid == me ? _xUid : '');

    setState(() {
      _board = '.' * (kSize * kSize);
      _winner = '';
      _winLine = [];
      _lastMove = -1;
      if (swap && other.isNotEmpty) {
        _xUid = other;
        _oUid = me;
        _turn = other;
      } else {
        _xUid = me;
        _oUid = other; // rong thi doi phuong se tu dien khi ho mo man hinh
        _turn = me;
      }
    });
    await _push();
  }

  /// Nguoi thu hai mo man hinh -> tu nhan quan con trong.
  Future<void> _join() async {
    if (_xUid.isEmpty) {
      _xUid = Sync.uid;
      _turn = Sync.uid;
    } else if (_oUid.isEmpty && _xUid != Sync.uid) {
      _oUid = Sync.uid;
    } else {
      return;
    }
    await _push();
  }

  // ---------- Danh mot nuoc ----------
  Future<void> _tap(int i) async {
    if (_loading || _sending) return;
    if (!Sync.enabled) {
      toast(context, 'Cần ghép đôi trước ở Cài đặt');
      return;
    }
    if (!_joined) {
      await _join();
      return;
    }
    if (_winner.isNotEmpty) {
      toast(context, 'Ván đã kết thúc, bấm Ván mới nhé');
      return;
    }
    if (!_myTurn) {
      toast(context, 'Chưa tới lượt bạn');
      return;
    }
    if (_board[i] != '.') return;

    HapticFeedback.selectionClick();
    final chars = _board.split('');
    chars[i] = _mySymbol;
    final newBoard = chars.join();

    final line = _findWin(newBoard, i, _mySymbol);
    final full = !newBoard.contains('.');

    setState(() {
      _board = newBoard;
      _lastMove = i;
      if (line.isNotEmpty) {
        _winner = Sync.uid;
        _winLine = line;
        if (_mySymbol == 'x') {
          _scoreX++;
        } else {
          _scoreO++;
        }
      } else if (full) {
        _winner = 'draw';
      } else {
        _turn = _iAmX ? _oUid : _xUid;
      }
    });

    await _push();

    if (!mounted) return;
    if (_winner == Sync.uid) {
      HapticFeedback.heavyImpact();
      _showEnd('🎉 Bạn thắng rồi!');
    } else if (_winner == 'draw') {
      _showEnd('🤝 Hoà nhau');
    }
  }

  /// Tim 5 quan lien tiep di qua o vua danh, theo 4 huong.
  List<int> _findWin(String board, int idx, String s) {
    final r = idx ~/ kSize, c = idx % kSize;
    const dirs = [
      [0, 1], // ngang
      [1, 0], // doc
      [1, 1], // cheo xuong phai
      [1, -1], // cheo xuong trai
    ];

    for (final d in dirs) {
      final cells = <int>[idx];
      // Di ve mot phia
      for (var k = 1; k < kWin; k++) {
        final nr = r + d[0] * k, nc = c + d[1] * k;
        if (nr < 0 || nr >= kSize || nc < 0 || nc >= kSize) break;
        if (board[nr * kSize + nc] != s) break;
        cells.add(nr * kSize + nc);
      }
      // Va phia nguoc lai
      for (var k = 1; k < kWin; k++) {
        final nr = r - d[0] * k, nc = c - d[1] * k;
        if (nr < 0 || nr >= kSize || nc < 0 || nc >= kSize) break;
        if (board[nr * kSize + nc] != s) break;
        cells.add(nr * kSize + nc);
      }
      if (cells.length >= kWin) {
        cells.sort();
        return cells;
      }
    }
    return [];
  }

  void _showEnd(String msg) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          decoration: BoxDecoration(
            gradient: C.grad,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Để sau',
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
                      onPressed: () {
                        Navigator.pop(context);
                        _newGame(swap: true);
                      },
                      child: const Text('Ván mới'),
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

  // ---------- Giao dien ----------
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        PageHeader(
          title: 'Cờ ca-rô',
          subtitle: 'Đánh luân phiên, ai được 5 quân liền là thắng',
          actions: [
            IconButton(
              tooltip: 'Tải nước đi mới',
              icon: const Icon(Icons.refresh),
              onPressed: () => _load(),
            ),
          ],
        ),

        if (!Sync.enabled)
          Section(
            child: Row(
              children: const [
                Text('🔗', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Vào Cài đặt ghép đôi trước, rồi hai bạn chơi được với nhau.',
                      style: TextStyle(fontSize: 13, color: C.muted)),
                ),
              ],
            ),
          ),

        _scoreBoard(),
        _boardWidget(),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: GradientButton(
            label: _winner.isEmpty && _board.contains('x')
                ? 'Bắt đầu lại ván này'
                : 'Ván mới',
            icon: Icons.refresh_rounded,
            loading: _sending,
            onTap: () => _newGame(swap: _winner.isNotEmpty),
          ),
        ),
      ],
    );
  }

  Widget _scoreBoard() {
    final meX = _iAmX;
    final myScore = meX ? _scoreX : _scoreO;
    final paScore = meX ? _scoreO : _scoreX;

    return Section(
      child: Row(
        children: [
          Expanded(child: _player(Store.myName, Store.myAvatar, meX, myScore, _turn == Sync.uid)),
          Column(
            children: [
              const Text('VS',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: C.muted)),
              const SizedBox(height: 4),
              Text('$myScore - $paScore',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          Expanded(
              child: _player(Store.partnerName, Store.partnerAvatar, !meX,
                  paScore, _turn.isNotEmpty && _turn != Sync.uid)),
        ],
      ),
    );
  }

  Widget _player(
      String name, String emoji, bool isX, int score, bool active) {
    final color = isX ? C.pink : C.purple;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: active ? color : Colors.transparent, width: 2.5),
          ),
          child: Avatar(emoji: emoji, name: name, size: 44, ring: color),
        ),
        const SizedBox(height: 6),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(isX ? '❌ quân X' : '⭕ quân O',
            style: TextStyle(fontSize: 11.5, color: color)),
        if (active)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('đang tới lượt',
                style: TextStyle(fontSize: 10.5, color: C.muted)),
          ),
      ],
    );
  }

  Widget _boardWidget() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: C.pink)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: C.purple.withOpacity(0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: kSize,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: kSize * kSize,
            itemBuilder: (_, i) => _cell(i),
          ),
        ),
      ),
    );
  }

  Widget _cell(int i) {
    final v = _board[i];
    final isWin = _winLine.contains(i);
    final isLast = i == _lastMove;

    return GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWin
              ? C.pink.withOpacity(0.22)
              : isLast
                  ? C.soft
                  : C.soft.withOpacity(0.45),
          borderRadius: BorderRadius.circular(6),
          border: isLast
              ? Border.all(color: C.purple.withOpacity(0.5), width: 1.2)
              : null,
        ),
        alignment: Alignment.center,
        child: v == '.'
            ? null
            : Text(
                v == 'x' ? '✕' : '◯',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: v == 'x' ? C.pink : C.purple,
                ),
              ),
      ),
    );
  }
}
