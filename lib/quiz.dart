// LoveSync - quiz.dart (v2)
// Duo Quiz: 60 cau hoi / 5 chu de, moi ngay tu doi 3 cau moi,
// swipe card, so sanh dap an doi song, lich su % thau hieu theo ngay.
import 'dart:math';

import 'package:flutter/material.dart';

import 'main.dart';
import 'sync.dart';

// ============================================================
// 1. MODEL + NGAN HANG CAU HOI
// ============================================================
class QuizQuestion {
  final String id;
  final String category;
  final String emoji;
  final String text;
  final List<String> options;
  const QuizQuestion(
      this.id, this.category, this.emoji, this.text, this.options);
}

class QuizCat {
  final String name;
  final String emoji;
  final Color color;
  const QuizCat(this.name, this.emoji, this.color);
}

const List<QuizCat> quizCategories = [
  QuizCat('Tình yêu & Thói quen', '💗', C.pink),
  QuizCat('Tài chính & Chi tiêu', '💰', Color(0xFFF0A868)),
  QuizCat('Hôn nhân & Gia đình', '🏡', Color(0xFF7FC8A9)),
  QuizCat('Ngôn ngữ tình yêu', '🎁', C.purple),
  QuizCat('Giá trị sống & Cảm xúc', '🌱', Color(0xFF6EC1E4)),
];

QuizCat catOf(String name) => quizCategories.firstWhere((c) => c.name == name,
    orElse: () => quizCategories.first);

const List<QuizQuestion> quizBank = [
  // ---------------- TINH YEU & THOI QUEN ----------------
  QuizQuestion('L01', 'Tình yêu & Thói quen', '☀️',
      'Buổi sáng của người ấy thường bắt đầu thế nào?', [
    'Dậy sớm, thong thả',
    'Bấm báo thức lại vài lần',
    'Dậy là lướt điện thoại',
    'Tuỳ hôm, không cố định'
  ]),
  QuizQuestion('L02', 'Tình yêu & Thói quen', '🌙',
      'Người ấy thường đi ngủ lúc mấy giờ?',
      ['Trước 22h', 'Khoảng 23h', 'Sau 0h', 'Thất thường']),
  QuizQuestion('L03', 'Tình yêu & Thói quen', '🍜',
      'Món người ấy tìm đến khi buồn là gì?', [
    'Đồ ngọt, trà sữa',
    'Đồ cay nóng',
    'Món quen thuộc mẹ nấu',
    'Không ăn nổi khi buồn'
  ]),
  QuizQuestion('L04', 'Tình yêu & Thói quen', '📱',
      'Bao lâu không nhắn tin thì người ấy thấy hụt hẫng?',
      ['Vài tiếng', 'Nửa ngày', 'Cả ngày', 'Không quan trọng lắm']),
  QuizQuestion('L05', 'Tình yêu & Thói quen', '🎬',
      'Buổi hẹn lý tưởng của hai bạn?', [
    'Ăn tối yên tĩnh',
    'Đi phượt, du lịch',
    'Ở nhà nấu ăn xem phim',
    'Cà phê nói chuyện cả buổi'
  ]),
  QuizQuestion('L06', 'Tình yêu & Thói quen', '🎧',
      'Khi cần tĩnh tâm, người ấy làm gì?', [
    'Nghe nhạc một mình',
    'Đi bộ, chạy bộ',
    'Ngủ một giấc',
    'Tìm người để nói chuyện'
  ]),
  QuizQuestion('L07', 'Tình yêu & Thói quen', '🤝',
      'Sau khi cãi nhau, ai thường làm lành trước?',
      ['Tôi', 'Người ấy', 'Cả hai cùng lúc', 'Tuỳ chuyện, không cố định']),
  QuizQuestion('L08', 'Tình yêu & Thói quen', '🔒',
      'Mức riêng tư điện thoại mà cả hai thấy thoải mái?', [
    'Chia sẻ hoàn toàn',
    'Biết mật khẩu nhưng không xem',
    'Giữ riêng tư',
    'Chưa từng bàn tới'
  ]),
  QuizQuestion('L09', 'Tình yêu & Thói quen', '📅',
      'Tần suất gặp nhau lý tưởng trong tuần?',
      ['Hằng ngày', '3-4 lần', '1-2 lần', 'Linh hoạt theo lịch']),
  QuizQuestion('L10', 'Tình yêu & Thói quen', '💔',
      'Điều dễ khiến người ấy tổn thương nhất?', [
    'Bị phớt lờ tin nhắn',
    'Bị so sánh với người khác',
    'Lời nặng lúc cãi nhau',
    'Bị thất hứa'
  ]),
  QuizQuestion('L11', 'Tình yêu & Thói quen', '🎂',
      'Người ấy thích kiểu sinh nhật nào?', [
    'Tiệc đông vui bạn bè',
    'Chỉ hai đứa với nhau',
    'Đi chơi xa dịp đó',
    'Không cần tổ chức'
  ]),
  QuizQuestion('L12', 'Tình yêu & Thói quen', '📸',
      'Người ấy nghĩ gì về việc đăng ảnh cặp đôi lên mạng?', [
    'Rất thích, đăng thường xuyên',
    'Thỉnh thoảng dịp đặc biệt',
    'Ngại, ít khi đăng',
    'Không muốn công khai'
  ]),

  // ---------------- TAI CHINH & CHI TIEU ----------------
  QuizQuestion('M01', 'Tài chính & Chi tiêu', '👛',
      'Cách quản lý tiền phù hợp với hai bạn?', [
    'Gộp chung toàn bộ',
    'Quỹ chung cộng tiền riêng',
    'Ai tiêu người nấy lo',
    'Một người giữ tiền chính'
  ]),
  QuizQuestion('M02', 'Tài chính & Chi tiêu', '📈',
      'Có khoản dư mỗi tháng, ưu tiên làm gì?', [
    'Gửi tiết kiệm',
    'Đầu tư sinh lời',
    'Du lịch, trải nghiệm',
    'Trả bớt nợ, trả góp'
  ]),
  QuizQuestion('M03', 'Tài chính & Chi tiêu', '🛒',
      'Mua món trên bao nhiêu tiền thì cần hỏi ý nhau?',
      ['Trên 1 triệu', 'Trên 5 triệu', 'Trên 20 triệu', 'Không cần hỏi']),
  QuizQuestion('M04', 'Tài chính & Chi tiêu', '🤲',
      'Quan điểm về cho người thân vay tiền?', [
    'Sẵn sàng nếu có khả năng',
    'Chỉ khoản nhỏ',
    'Phải bàn bạc kỹ trước',
    'Hạn chế tối đa'
  ]),
  QuizQuestion('M05', 'Tài chính & Chi tiêu', '🎯',
      'Mục tiêu tài chính lớn nhất 3 năm tới?',
      ['Mua nhà, đất', 'Mua xe', 'Đám cưới', 'Quỹ dự phòng và đầu tư']),
  QuizQuestion('M06', 'Tài chính & Chi tiêu', '🔑',
      'Ai phù hợp làm tay hòm chìa khoá?',
      ['Tôi', 'Người ấy', 'Cả hai cùng theo dõi', 'Chưa cần ai giữ']),
  QuizQuestion('M07', 'Tài chính & Chi tiêu', '🍽️',
      'Đi ăn cùng nhau thì trả tiền thế nào?',
      ['Ai rủ người đó trả', 'Chia đôi', 'Một người trả cố định', 'Luân phiên']),
  QuizQuestion('M08', 'Tài chính & Chi tiêu', '💳',
      'Quan điểm về mua trả góp?', [
    'Chỉ mua khi trả góp 0%',
    'Chấp nhận nếu cần thiết',
    'Tránh hoàn toàn',
    'Tuỳ món hàng'
  ]),
  QuizQuestion('M09', 'Tài chính & Chi tiêu', '🎁',
      'Ngân sách hợp lý cho một món quà tặng nhau?', [
    'Dưới 500 nghìn',
    '500 nghìn đến 2 triệu',
    'Trên 2 triệu',
    'Giá không quan trọng'
  ]),
  QuizQuestion('M10', 'Tài chính & Chi tiêu', '📊',
      'Hai bạn có nên biết thu nhập của nhau không?',
      ['Biết chính xác', 'Biết khoảng chừng', 'Chỉ khi cưới', 'Không cần biết']),
  QuizQuestion('M11', 'Tài chính & Chi tiêu', '✈️',
      'Kiểu du lịch phù hợp túi tiền hai bạn?', [
    'Tiết kiệm, tự túc',
    'Trung bình, thoải mái',
    'Nghỉ dưỡng cao cấp',
    'Tuỳ dịp'
  ]),
  QuizQuestion('M12', 'Tài chính & Chi tiêu', '🏦',
      'Nếu một người mất việc vài tháng?', [
    'Người còn lại lo hết',
    'Dùng quỹ dự phòng chung',
    'Mỗi người tự xoay',
    'Nhờ gia đình hỗ trợ'
  ]),

  // ---------------- HON NHAN & GIA DINH ----------------
  QuizQuestion('H01', 'Hôn nhân & Gia đình', '💍',
      'Thời điểm kết hôn mong muốn?',
      ['Trong 1 năm tới', '1-3 năm tới', 'Sau 3 năm', 'Chưa xác định']),
  QuizQuestion('H02', 'Hôn nhân & Gia đình', '🏠',
      'Sau cưới, hai bạn muốn sống ở đâu?', [
    'Ở riêng',
    'Sống cùng bố mẹ',
    'Gần bố mẹ nhưng ở riêng',
    'Tuỳ điều kiện công việc'
  ]),
  QuizQuestion('H03', 'Hôn nhân & Gia đình', '👶', 'Số con mong muốn?',
      ['Một bé', 'Hai bé', 'Từ ba bé trở lên', 'Chưa muốn có con']),
  QuizQuestion('H04', 'Hôn nhân & Gia đình', '🧹',
      'Việc nhà nên phân chia thế nào?', [
    'Chia đôi rạch ròi',
    'Ai rảnh người đó làm',
    'Theo thế mạnh mỗi người',
    'Thuê người hỗ trợ'
  ]),
  QuizQuestion('H05', 'Hôn nhân & Gia đình', '🧳',
      'Nếu một người phải đi làm xa dài ngày?', [
    'Chấp nhận, gọi mỗi ngày',
    'Cùng chuyển đi theo',
    'Chỉ dưới 6 tháng',
    'Không chấp nhận'
  ]),
  QuizQuestion('H06', 'Hôn nhân & Gia đình', '🕊️',
      'Cách xử lý khi mâu thuẫn với gia đình hai bên?', [
    'Vợ chồng bảo vệ nhau trước',
    'Ai sai người đó nhận',
    'Giữ hoà khí, không tranh luận',
    'Nhờ người lớn phân xử'
  ]),
  QuizQuestion('H07', 'Hôn nhân & Gia đình', '🔗',
      'Điều quan trọng nhất giữ hôn nhân bền lâu?', [
    'Giao tiếp thẳng thắn',
    'Tài chính ổn định',
    'Tôn trọng không gian riêng',
    'Cùng mục tiêu sống'
  ]),
  QuizQuestion('H08', 'Hôn nhân & Gia đình', '🎊',
      'Đám cưới mơ ước có quy mô thế nào?', [
    'Nhỏ gọn, chỉ người thân',
    'Vừa phải, bạn bè thân',
    'Lớn, đông khách',
    'Không cần tiệc, chỉ đăng ký'
  ]),
  QuizQuestion('H09', 'Hôn nhân & Gia đình', '🍲',
      'Ai sẽ nấu ăn chính trong nhà?',
      ['Tôi', 'Người ấy', 'Cùng nấu', 'Đặt đồ ăn ngoài']),
  QuizQuestion('H10', 'Hôn nhân & Gia đình', '📚',
      'Quan điểm nuôi dạy con nghiêng về hướng nào?', [
    'Nghiêm khắc, kỷ luật',
    'Thoải mái, làm bạn với con',
    'Cân bằng cả hai',
    'Chưa nghĩ tới'
  ]),
  QuizQuestion('H11', 'Hôn nhân & Gia đình', '🎄', 'Tết và lễ lớn thì về nhà ai?',
      ['Luân phiên mỗi năm', 'Chia đôi kỳ nghỉ', 'Về nhà nội', 'Về nhà ngoại']),
  QuizQuestion('H12', 'Hôn nhân & Gia đình', '🐶',
      'Hai bạn có muốn nuôi thú cưng không?',
      ['Rất muốn', 'Muốn nhưng chưa tiện', 'Không thích', 'Tuỳ người kia quyết']),

  // ---------------- NGON NGU TINH YEU ----------------
  QuizQuestion('N01', 'Ngôn ngữ tình yêu', '💌',
      'Điều khiến người ấy cảm thấy được yêu nhất?', [
    'Lời nói yêu thương',
    'Thời gian ở bên nhau',
    'Hành động chăm sóc',
    'Quà tặng bất ngờ'
  ]),
  QuizQuestion('N02', 'Ngôn ngữ tình yêu', '🫂',
      'Khi buồn, người ấy muốn được đối xử thế nào?', [
    'Được ôm và ở cạnh',
    'Được lắng nghe, không khuyên',
    'Được ở một mình một lúc',
    'Được rủ đi chơi cho khuây'
  ]),
  QuizQuestion('N03', 'Ngôn ngữ tình yêu', '🗣️',
      'Lời khen nào khiến người ấy vui nhất?', [
    'Khen ngoại hình',
    'Khen năng lực, công việc',
    'Khen tính cách, tấm lòng',
    'Khen trước mặt người khác'
  ]),
  QuizQuestion('N04', 'Ngôn ngữ tình yêu', '☕',
      'Hành động chăm sóc nào người ấy quý nhất?', [
    'Nấu cho bữa ăn',
    'Đưa đón đi làm',
    'Nhắc uống thuốc, nghỉ ngơi',
    'Dọn dẹp giúp'
  ]),
  QuizQuestion('N05', 'Ngôn ngữ tình yêu', '🎀',
      'Kiểu quà người ấy thích nhận?', [
    'Đồ handmade tự làm',
    'Món đồ đang cần dùng',
    'Đồ hiệu, đắt tiền',
    'Trải nghiệm, vé đi chơi'
  ]),
  QuizQuestion('N06', 'Ngôn ngữ tình yêu', '⏰',
      'Khoảnh khắc bên nhau nào ý nghĩa nhất với người ấy?', [
    'Ăn cơm chung mỗi ngày',
    'Đi chơi cuối tuần',
    'Nói chuyện trước khi ngủ',
    'Cùng làm việc, học chung'
  ]),
  QuizQuestion('N07', 'Ngôn ngữ tình yêu', '🤗',
      'Người ấy có thoải mái với cử chỉ thân mật nơi công cộng không?',
      ['Rất thoải mái', 'Chỉ nắm tay', 'Ngại, thích riêng tư', 'Tuỳ nơi']),
  QuizQuestion('N08', 'Ngôn ngữ tình yêu', '📞',
      'Cách liên lạc người ấy thích nhất?',
      ['Nhắn tin cả ngày', 'Gọi điện thoại', 'Gọi video', 'Gặp trực tiếp là đủ']),
  QuizQuestion('N09', 'Ngôn ngữ tình yêu', '🌹',
      'Người ấy nghĩ gì về những dịp kỷ niệm nhỏ?', [
    'Rất quan trọng, phải nhớ',
    'Nhớ được thì vui',
    'Không quá quan trọng',
    'Thích bất ngờ hơn ngày cố định'
  ]),
  QuizQuestion('N10', 'Ngôn ngữ tình yêu', '✍️',
      'Người ấy thích nhận lời yêu thương theo cách nào?', [
    'Nói trực tiếp',
    'Viết thư, nhắn tin dài',
    'Thể hiện bằng hành động',
    'Không cần nói, tự hiểu'
  ]),
  QuizQuestion('N11', 'Ngôn ngữ tình yêu', '🎵',
      'Điều nhỏ nào khiến người ấy thấy được nhớ tới?', [
    'Mua đúng món họ thích',
    'Nhớ chuyện họ từng kể',
    'Nhắn tin hỏi thăm giữa ngày',
    'Chuẩn bị sẵn thứ họ cần'
  ]),
  QuizQuestion('N12', 'Ngôn ngữ tình yêu', '🌈',
      'Sau một ngày tệ, người ấy cần gì nhất từ bạn?', [
    'Một cái ôm im lặng',
    'Được kể hết ra',
    'Được rủ đi ăn món ngon',
    'Được để yên nghỉ ngơi'
  ]),

  // ---------------- GIA TRI SONG & CAM XUC ----------------
  QuizQuestion('G01', 'Giá trị sống & Cảm xúc', '🌱',
      'Điều gì quan trọng nhất với người ấy hiện tại?',
      ['Sự nghiệp', 'Gia đình', 'Sức khoẻ', 'Sự tự do']),
  QuizQuestion('G02', 'Giá trị sống & Cảm xúc', '😤',
      'Khi giận, người ấy phản ứng thế nào?', [
    'Nói thẳng ngay lúc đó',
    'Im lặng một lúc rồi nói',
    'Giữ trong lòng',
    'Đi chỗ khác cho nguôi'
  ]),
  QuizQuestion('G03', 'Giá trị sống & Cảm xúc', '🎓',
      'Người ấy đánh giá thành công theo tiêu chí nào?',
      ['Thu nhập', 'Được công nhận', 'Cân bằng cuộc sống', 'Giúp được người khác']),
  QuizQuestion('G04', 'Giá trị sống & Cảm xúc', '🧭',
      'Khi phải quyết định lớn, người ấy dựa vào?', [
    'Lý trí, phân tích',
    'Cảm xúc, trực giác',
    'Hỏi ý người thân',
    'Chần chừ rất lâu'
  ]),
  QuizQuestion('G05', 'Giá trị sống & Cảm xúc', '😰',
      'Điều người ấy lo lắng nhất lúc này?', [
    'Công việc bấp bênh',
    'Sức khoẻ bản thân, gia đình',
    'Tương lai hai đứa',
    'Áp lực tài chính'
  ]),
  QuizQuestion('G06', 'Giá trị sống & Cảm xúc', '🙏',
      'Người ấy xin lỗi theo cách nào?', [
    'Nói thẳng lời xin lỗi',
    'Làm điều gì đó bù đắp',
    'Nhắn tin dễ hơn nói',
    'Rất khó mở lời'
  ]),
  QuizQuestion('G07', 'Giá trị sống & Cảm xúc', '⚖️',
      'Người ấy coi trọng điều gì hơn trong tranh luận?',
      ['Được hiểu đúng ý', 'Giữ hoà khí', 'Tìm ra giải pháp', 'Được thắng lý']),
  QuizQuestion('G08', 'Giá trị sống & Cảm xúc', '🕰️',
      'Người ấy sống thiên về đâu?', [
    'Hưởng thụ hiện tại',
    'Tích luỹ cho tương lai',
    'Cân bằng cả hai',
    'Tuỳ giai đoạn'
  ]),
  QuizQuestion('G09', 'Giá trị sống & Cảm xúc', '👥',
      'Người ấy nạp năng lượng bằng cách nào?', [
    'Gặp gỡ bạn bè',
    'Ở một mình',
    'Ở bên người yêu',
    'Làm việc mình thích'
  ]),
  QuizQuestion('G10', 'Giá trị sống & Cảm xúc', '🚩',
      'Điều gì người ấy tuyệt đối không chấp nhận?', [
    'Nói dối',
    'Thiếu tôn trọng gia đình',
    'Không giữ lời hứa',
    'Thiếu cầu tiến'
  ]),
  QuizQuestion('G11', 'Giá trị sống & Cảm xúc', '🌊',
      'Trước thay đổi lớn, người ấy thường?', [
    'Hào hứng đón nhận',
    'Lo lắng nhưng vẫn làm',
    'Cần thời gian chuẩn bị',
    'Muốn giữ nguyên hiện tại'
  ]),
  QuizQuestion('G12', 'Giá trị sống & Cảm xúc', '💭',
      'Người ấy mong bạn hiểu điều gì nhất về họ?', [
    'Họ cần được tin tưởng',
    'Họ đang cố gắng hết sức',
    'Họ dễ tổn thương hơn vẻ ngoài',
    'Họ cần không gian riêng'
  ]),
];

// ============================================================
// 2. LOGIC: BO CAU HOI THEO NGAY
// ============================================================
class DailyQuiz {
  static const int perDay = 3;

  /// Xao tron voi seed co dinh -> moi may deu tao ra day giong het nhau.
  static final List<QuizQuestion> _shuffled =
      List<QuizQuestion>.from(quizBank)..shuffle(Random(20260101));

  static int dayIndex(DateTime d) =>
      DateTime(d.year, d.month, d.day).difference(DateTime(2024, 1, 1)).inDays;

  /// Bo cau hoi cua mot ngay. Chi phu thuoc vao ngay nen hai may luon trung nhau,
  /// khong can dong bo danh sach cau hoi qua Firebase.
  static List<QuizQuestion> forDate(DateTime d) {
    final n = _shuffled.length;
    final start = (dayIndex(d) * perDay) % n;
    return List.generate(perDay, (i) => _shuffled[(start + i) % n]);
  }

  static List<QuizQuestion> today() => forDate(DateTime.now());

  /// So ngay de duyet het ngan hang roi lap lai.
  static int get cycleDays => quizBank.length ~/ perDay;

  /// Ket qua cua mot ngay.
  static ({int matched, int both, int mine}) result(DateTime d) {
    final qs = forDate(d);
    final me = Store.quiz('me');
    final pa = Store.quiz('partner');
    int matched = 0, both = 0, mine = 0;
    for (final q in qs) {
      if (me.containsKey(q.id)) mine++;
      if (me.containsKey(q.id) && pa.containsKey(q.id)) {
        both++;
        if (me[q.id] == pa[q.id]) matched++;
      }
    }
    return (matched: matched, both: both, mine: mine);
  }

  static int percent(DateTime d) {
    final r = result(d);
    return r.both == 0 ? 0 : (r.matched * 100 / r.both).round();
  }
}

// ============================================================
// 3. MAN HINH CHINH
// ============================================================
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _page = PageController(viewportFraction: 0.9);
  int _index = 0;
  late List<QuizQuestion> _today;

  @override
  void initState() {
    super.initState();
    _today = DailyQuiz.today();
    Sync.revision.addListener(_onSync);
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Sync.revision.removeListener(_onSync);
    _page.dispose();
    super.dispose();
  }

  Future<void> _answer(QuizQuestion q, int i) async {
    await Store.setQuizAnswer('me', q.id, i);
    if (!mounted) return;
    setState(() {});
    // Chon xong thi tu truot sang the tiep theo
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    _page.nextPage(
        duration: const Duration(milliseconds: 380), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final me = Store.quiz('me');
    final answered = _today.where((q) => me.containsKey(q.id)).length;

    return ListView(
      children: [
        PageHeader(
          title: 'Duo Quiz',
          subtitle: 'Bộ 3 câu hôm nay, mai lại có bộ mới',
          actions: [
            IconButton(
              tooltip: 'Lịch sử',
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QuizHistoryScreen())),
            ),
          ],
        ),

        // Thanh tien do
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: List.generate(_today.length, (i) {
              final done = me.containsKey(_today[i].id);
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    gradient: done ? C.grad : null,
                    color: done ? null : C.soft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
        ),

        // Bo the: 3 cau hoi + 1 the ket qua
        SizedBox(
          height: 440,
          child: PageView.builder(
            controller: _page,
            itemCount: _today.length + 1,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              if (i == _today.length) return const _ResultCard();
              return _QuestionCard(
                q: _today[i],
                order: i + 1,
                total: _today.length,
                myAnswer: me[_today[i].id] as int?,
                onPick: (idx) => _answer(_today[i], idx),
              );
            },
          ),
        ),

        const SizedBox(height: 14),
        Center(
          child: Text(
            _index >= _today.length
                ? 'Chạm nút để xem hai đứa trả lời khác nhau chỗ nào'
                : answered < _today.length
                    ? 'Đã trả lời $answered/${_today.length} câu • vuốt để sang câu sau'
                    : 'Xong rồi! Vuốt tiếp để xem kết quả 💕',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: C.muted),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ============================================================
// 4. THE CAU HOI
// ============================================================
class _QuestionCard extends StatelessWidget {
  final QuizQuestion q;
  final int order, total;
  final int? myAnswer;
  final ValueChanged<int> onPick;

  const _QuestionCard({
    required this.q,
    required this.order,
    required this.total,
    required this.myAnswer,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cat = catOf(q.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: cat.color.withOpacity(0.20),
                blurRadius: 22,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dai mau theo chu de
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.13),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 17)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(q.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: cat.color)),
                  ),
                  Text('$order/$total',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: C.muted)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(q.text,
                        style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            height: 1.35)),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: q.options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final sel = myAnswer == i;
                          return GestureDetector(
                            onTap: () => onPick(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: sel
                                    ? cat.color.withOpacity(0.16)
                                    : C.soft.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: sel ? cat.color : Colors.transparent,
                                    width: 1.6),
                              ),
                              child: Row(
                                children: [
                                  AnimatedScale(
                                    scale: sel ? 1 : 0.65,
                                    duration: const Duration(milliseconds: 220),
                                    child: Icon(
                                        sel
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 17,
                                        color: sel ? cat.color : C.muted),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(q.options[i],
                                        style: TextStyle(
                                            fontSize: 13.5,
                                            height: 1.3,
                                            fontWeight: sel
                                                ? FontWeight.w700
                                                : FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
// 5. THE KET QUA + TIM BAY
// ============================================================
class _ResultCard extends StatefulWidget {
  const _ResultCard();
  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _msg(int p, int both) {
    if (both == 0) return 'Chờ người ấy trả lời để so đáp án nhé';
    if (p == 100) return 'Ăn ý tuyệt đối, hiểu nhau như một 💞';
    if (p >= 67) return 'Rất hiểu nhau rồi đó!';
    if (p >= 34) return 'Có vài điểm khác nhau, tối nay kể cho nhau nghe nha';
    return 'Khác nhau nhiều, đây là cơ hội để hiểu nhau hơn';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final r = DailyQuiz.result(today);
    final p = DailyQuiz.percent(today);
    final celebrate = r.both > 0 && p >= 67;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: C.grad,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: C.pink.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12)),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Mức thấu hiểu hôm nay',
                    style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: p / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => SizedBox(
                    width: 124,
                    height: 124,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 124,
                          height: 124,
                          child: CircularProgressIndicator(
                            value: v,
                            strokeWidth: 11,
                            backgroundColor: Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        Text('${(v * 100).round()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(_msg(p, r.both),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
                const SizedBox(height: 6),
                Text('Trùng ${r.matched}/${r.both} câu cả hai đã trả lời',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: C.pink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => QuizCompareScreen(date: today)),
                  ),
                  icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                  label: const Text('So đáp án hai đứa'),
                ),
              ],
            ),
          ),
          if (celebrate)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) =>
                      CustomPaint(painter: _HeartsPainter(_c.value)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tim bay len khi diem cao. Ve bang CustomPainter, khong dung thu vien ngoai.
class _HeartsPainter extends CustomPainter {
  final double t;
  _HeartsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(9);
    for (var i = 0; i < 14; i++) {
      final x0 = rnd.nextDouble() * size.width;
      final speed = 0.6 + rnd.nextDouble() * 0.7;
      final phase = rnd.nextDouble();
      final s = 5.0 + rnd.nextDouble() * 6;
      final prog = (t * speed + phase) % 1.0;
      final y = size.height * (1.05 - prog);
      final x = x0 + sin(prog * pi * 4 + i) * 14;
      final op = prog < 0.15 ? prog / 0.15 : (1 - prog) / 0.85;
      _heart(canvas, Offset(x, y), s,
          Colors.white.withOpacity((op * 0.85).clamp(0.0, 1.0)));
    }
  }

  void _heart(Canvas c, Offset o, double s, Color color) {
    final path = Path()
      ..moveTo(o.dx, o.dy + s * 0.7)
      ..cubicTo(o.dx - s * 1.4, o.dy - s * 0.4, o.dx - s * 0.4, o.dy - s * 1.2,
          o.dx, o.dy - s * 0.4)
      ..cubicTo(o.dx + s * 0.4, o.dy - s * 1.2, o.dx + s * 1.4, o.dy - s * 0.4,
          o.dx, o.dy + s * 0.7)
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter old) => old.t != t;
}

// ============================================================
// 6. SO DAP AN DOI SONG
// ============================================================
class QuizCompareScreen extends StatefulWidget {
  final DateTime date;
  const QuizCompareScreen({super.key, required this.date});

  @override
  State<QuizCompareScreen> createState() => _QuizCompareScreenState();
}

class _QuizCompareScreenState extends State<QuizCompareScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    // Ban phao hoa neu hom nay co cau nao hai dua tra loi giong nhau
    final r = DailyQuiz.result(widget.date);
    if (r.matched > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fw.forward());
    }
  }

  @override
  void dispose() {
    _fw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.date;
    final qs = DailyQuiz.forDate(date);
    final me = Store.quiz('me');
    final pa = Store.quiz('partner');
    final r = DailyQuiz.result(date);

    return Scaffold(
      appBar: AppBar(
          title: Text(
              'Đáp án ${two(date.day)}/${two(date.month)}/${date.year}')),
      body: Stack(
        children: [
          ListView(
            children: [
              Section(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _who(Store.myAvatar, Store.myName, C.pink),
                        const Text('💞', style: TextStyle(fontSize: 22)),
                        _who(Store.partnerAvatar, Store.partnerName, C.purple),
                      ],
                    ),
                    if (r.both > 0) ...[
                      const SizedBox(height: 14),
                      Text(
                          r.matched == r.both
                              ? '🎆 Trùng khớp toàn bộ ${r.both} câu!'
                              : 'Trùng ${r.matched}/${r.both} câu đã mở khoá',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: r.matched > 0
                                  ? Colors.green.shade600
                                  : C.muted)),
                    ],
                  ],
                ),
              ),
              ...qs.map((q) => _questionRow(q, me, pa)),
              const SizedBox(height: 24),
            ],
          ),
          // Lop phao hoa phu len tren, khong chan thao tac
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fw,
                builder: (_, __) => _fw.value == 0 || _fw.isCompleted
                    ? const SizedBox.shrink()
                    : CustomPaint(painter: _FireworksPainter(_fw.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionRow(
      QuizQuestion q, Map<String, dynamic> me, Map<String, dynamic> pa) {
    final a = me[q.id] as int?;
    final b = pa[q.id] as int?;
    final same = a != null && b != null && a == b;
    final locked = a == null || b == null; // chua du hai nguoi -> khoa
    final cat = catOf(q.category);

    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(q.text,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        height: 1.35)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (locked)
            // Khoa hai chieu: khong lo dap an cua ai het, ke ca cua chinh minh
            _lockedBox(a != null, b != null)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _answerBox(q.options[a], C.pink, same)),
                const SizedBox(width: 10),
                Expanded(child: _answerBox(q.options[b], C.purple, same)),
              ],
            ),

          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                  same
                      ? Icons.check_circle
                      : locked
                          ? Icons.lock_outline
                          : Icons.forum_outlined,
                  size: 15,
                  color: same
                      ? Colors.green.shade600
                      : locked
                          ? C.muted
                          : cat.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  same
                      ? 'Hai bạn nghĩ giống nhau'
                      : locked
                          ? 'Mở khoá khi cả hai cùng trả lời'
                          : 'Khác nhau, chủ đề đáng nói chuyện tối nay',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: same
                          ? Colors.green.shade600
                          : locked
                              ? C.muted
                              : cat.color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _who(String emoji, String name, Color color) => Column(
        children: [
          Avatar(emoji: emoji, name: name, size: 48, ring: color),
          const SizedBox(height: 6),
          SizedBox(
            width: 96,
            child: Text(name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      );

  /// O bi khoa: che ca hai dap an, chi cho biet ai da tra loi.
  Widget _lockedBox(bool meDone, bool paDone) {
    Widget dot(bool done, String name, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(done ? Icons.check_circle : Icons.circle_outlined,
                size: 14, color: done ? color : C.muted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: done ? color : C.muted)),
            ),
          ],
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        gradient: C.gradSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.pink.withOpacity(0.25), width: 1.4),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_rounded, color: C.pink, size: 26),
          const SizedBox(height: 8),
          const Text('Đáp án đang bị khoá',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13.5, color: C.ink)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              dot(meDone, Store.myName, C.pink),
              dot(paDone, Store.partnerName, C.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerBox(String text, Color color, bool same) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(same ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: same ? color : color.withOpacity(0.25), width: 1.4),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: C.ink,
                fontWeight: FontWeight.w600)),
      );
}

/// Phao hoa: vai chum sang no ra roi mo dan. Ve bang CustomPainter,
/// khong dung thu vien ngoai.
class _FireworksPainter extends CustomPainter {
  final double t; // 0 -> 1
  _FireworksPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(2026);
    const bursts = 5;
    const perBurst = 26;

    for (var b = 0; b < bursts; b++) {
      // Moi chum no o mot thoi diem khac nhau
      final delay = b * 0.13;
      final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final cx = size.width * (0.15 + rnd.nextDouble() * 0.7);
      final cy = size.height * (0.12 + rnd.nextDouble() * 0.45);
      final maxR = size.width * (0.22 + rnd.nextDouble() * 0.16);
      final hue = rnd.nextInt(4);
      final color = [C.pink, C.purple, const Color(0xFFFFD166), C.peach][hue];

      // No nhanh luc dau roi cham dan
      final r = maxR * (1 - pow(1 - local, 3)).toDouble();
      final opacity = (1 - local).clamp(0.0, 1.0);

      for (var i = 0; i < perBurst; i++) {
        final a = 2 * pi * i / perBurst + b;
        // Hat roi nhe xuong theo trong luc
        final gravity = size.height * 0.06 * local * local;
        final p = Offset(cx + cos(a) * r, cy + sin(a) * r + gravity);

        canvas.drawCircle(
          p,
          2.6 * (1 - local * 0.5),
          Paint()..color = color.withOpacity(opacity * 0.9),
        );
      }

      // Quang sang o tam luc vua no
      if (local < 0.3) {
        canvas.drawCircle(
          Offset(cx, cy),
          maxR * 0.28 * (1 - local / 0.3),
          Paint()..color = Colors.white.withOpacity(0.5 * (1 - local / 0.3)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) => old.t != t;
}

// ============================================================
// 7. LICH SU + HUY HIEU
// ============================================================
class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  ({String emoji, String label, Color color}) _badge(int p) {
    if (p == 100) {
      return (emoji: '👑', label: 'Tri kỷ', color: const Color(0xFFD9A400));
    }
    if (p >= 67) return (emoji: '💞', label: 'Ăn ý', color: C.pink);
    if (p >= 34) return (emoji: '🌤️', label: 'Khá hợp', color: C.purple);
    return (emoji: '🌱', label: 'Đang hiểu nhau', color: C.muted);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(21, (i) => now.subtract(Duration(days: i)));
    final played = days.where((d) => DailyQuiz.result(d).mine > 0).toList();

    final avg = played.isEmpty
        ? 0
        : (played.map(DailyQuiz.percent).reduce((a, b) => a + b) /
                played.length)
            .round();

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử thấu hiểu')),
      body: ListView(
        children: [
          Section(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      gradient: C.grad,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('$avg%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trung bình 3 tuần qua',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                          'Đã chơi ${played.length} ngày • ngân hàng ${quizBank.length} câu, hết ${DailyQuiz.cycleDays} ngày mới lặp lại',
                          style: const TextStyle(
                              fontSize: 12, color: C.muted, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (played.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 50, horizontal: 40),
              child: Column(
                children: [
                  Text('🗓️', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 12),
                  Text(
                      'Chưa có ngày nào được ghi lại.\nTrả lời bộ câu hỏi hôm nay để bắt đầu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: C.muted, fontSize: 13.5, height: 1.5)),
                ],
              ),
            ),
          ...played.map((d) {
            final r = DailyQuiz.result(d);
            final p = DailyQuiz.percent(d);
            final b = _badge(p);
            final isToday = DailyQuiz.dayIndex(d) == DailyQuiz.dayIndex(now);

            return Section(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => QuizCompareScreen(date: d))),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: b.color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(b.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                  isToday
                                      ? 'Hôm nay'
                                      : '${two(d.day)}/${two(d.month)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(b.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: b.color)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                              r.both == 0
                                  ? 'Bạn trả lời ${r.mine}/3 • chờ người ấy'
                                  : 'Trùng ${r.matched}/${r.both} câu',
                              style: const TextStyle(
                                  fontSize: 12, color: C.muted)),
                        ],
                      ),
                    ),
                    Text(r.both == 0 ? '—' : '$p%',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: r.both == 0 ? C.muted : b.color)),
                    const Icon(Icons.chevron_right, color: C.muted, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
