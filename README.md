# LoveSync v2 — đồng bộ tự động qua Firebase

Khác v1: không còn phải copy/dán mã đồng bộ thủ công. Hai máy nhập chung một **mã cặp đôi** một lần, sau đó cảm xúc, quiz, wishlist, quỹ chung tự đồng bộ mỗi 30 giây và mỗi lần mở app.

## File cần cập nhật lên GitHub

| Đường dẫn | Ghi chú |
|---|---|
| `lib/main.dart` | **thay mới** |
| `lib/sync.dart` | **file mới** |
| `lib/quiz.dart` | giữ nguyên như v1 |
| `lib/extras.dart` | giữ nguyên như v1 |
| `pubspec.yaml` | giữ nguyên |
| `.github/workflows/build.yml` | **thay mới** (đã thêm `permissions: contents: write` để hết lỗi Release) |

Không thêm thư viện mới, không cần `google-services.json`, không sửa Gradle — app gọi thẳng Firebase bằng REST API qua gói `http` đã có.

---

## Bước 1 — Tạo Firebase Realtime Database (5 phút, miễn phí)

1. Vào https://console.firebase.google.com → **Add project** → đặt tên `lovesync` → tắt Google Analytics cho nhanh → Create.
2. Menu trái → **Build → Realtime Database** → **Create Database**.
3. Chọn location **Singapore (asia-southeast1)** cho gần Việt Nam.
4. Bảo mật chọn **Start in locked mode** → Enable.
5. Sang tab **Rules**, xoá hết và dán đoạn này → **Publish**:

```json
{
  "rules": {
    "couples": {
      "$code": {
        ".read": "$code.length >= 12",
        ".write": "$code.length >= 12"
      }
    }
  }
}
```

6. Sang tab **Data**, copy dòng URL ở trên cùng, dạng:
   `https://lovesync-xxxx-default-rtdb.asia-southeast1.firebasedatabase.app`

## Bước 2 — Ghép đôi trên app

Cả hai máy cùng làm:

1. Cài APK v2 → mở **Cài đặt**.
2. Dán **Firebase Database URL** vừa copy (giống hệt nhau ở cả hai máy).
3. Ô **Mã cặp đôi**: bạn bấm biểu tượng xúc xắc để sinh mã ngẫu nhiên 16 ký tự, rồi bấm **Copy thông tin kết nối** gửi Zalo cho bạn gái. Cô ấy dán đúng chuỗi đó vào máy mình.
4. Bấm **Kết nối & đồng bộ ngay**. Hiện "Đã đồng bộ với <tên>" là xong.

Từ giờ chỉ cần ghi cảm xúc, máy kia tự thấy sau tối đa 30 giây. Muốn cập nhật ngay thì kéo màn hình xuống (pull to refresh) hoặc bấm icon 🔄 trên đầu.

---

## Tên và ảnh đại diện tự đồng bộ

Vào **Cài đặt → chạm vào vòng tròn avatar** để chọn 1 trong 36 emoji dựng sẵn, sửa tên rồi bấm **Lưu thông tin**.
Máy còn lại sẽ thấy tên và avatar mới sau tối đa 30 giây, hoặc ngay lập tức nếu kéo màn hình xuống.

Avatar lưu dưới dạng **chính ký tự emoji** (vài byte) nên đồng bộ tức thì, không cần Firebase Storage, không cần plugin native nào — dự án vẫn chỉ có `shared_preferences` và `http`, build APK không phát sinh rủi ro.

Chưa chọn emoji thì app hiển thị chữ cái đầu của tên trên nền pastel. Trong bảng chọn có nút *Dùng chữ cái đầu của tên* để quay lại kiểu này.

Ô "Tên người ấy" chỉ dùng khi chưa ghép đôi. Sau khi ghép, tên và avatar của người kia luôn lấy theo máy của họ.

## Kỷ niệm (Love Memories)

Hiển thị dạng **lưới ô vuông 3 cột kiểu Locket** — 9 kỷ niệm trong một màn hình thay vì phải cuộn từng thẻ dọc.

- Chạm một ô để mở ảnh toàn màn hình trên nền đen.
- Vuốt ngang để xem kỷ niệm trước/sau, không phải quay ra lưới.
- Chụm hai ngón để phóng to ảnh.
- Ô nào không có ảnh thì hiện ghi chú trên nền pastel, không để trống.
- Góc dưới mỗi ô có ngày/tháng trên dải mờ, luôn đọc được dù ảnh sáng hay tối.
- Nút xoá nằm trong màn hình chi tiết, có hỏi xác nhận — tránh xoá nhầm khi lướt.

Khi ghim mới:
- **Thời gian**: tự gán `DateTime.now()` ngay khi mở màn hình.
- **Địa điểm**: gõ tay. Nơi đã ghim trước đó hiện thành nút bấm một chạm.
- **Ảnh**: chụp trực tiếp hoặc chọn từ thư viện.

### Vì sao bỏ GPS và bản đồ

Bản đầu dùng `geolocator` + `geocoding` để tự lấy toạ độ và `flutter_map` hiển thị pin. Ba thư viện này là nguồn gốc của hầu hết lỗi Gradle khi build APK. Đổi lại chỉ tiết kiệm được vài giây gõ tên quán, nên đã gỡ cả ba.

### Cách ảnh được lưu và đồng bộ

| Thành phần | Nơi lưu | Có sang máy người ấy không |
|---|---|---|
| Địa điểm, thời gian, ghi chú | SharedPreferences + Firebase | Có |
| Ảnh gốc (~1280px) | Thư mục riêng của app trên máy chụp | Không |
| Ảnh thu nhỏ 280px (~15 KB, base64) | Firebase, trong cùng bản ghi | Có |

Làm vậy để tránh phải bật Firebase Storage (nay yêu cầu gắn thẻ thanh toán) và giữ mỗi vòng đồng bộ đủ nhẹ.

## Thủ thỉ (nhắn tin)

Tab 💬 giữa Cảm xúc và Duo Quiz, dùng chung Firebase đã cấu hình.

- Bong bóng gradient hồng cho bạn bên phải, nền trắng cho người ấy bên trái.
- Tin chỉ có emoji hiện to, không bọc bong bóng.
- Hàng **câu gửi nhanh** trên ô nhập: chạm là gửi, khỏi gõ.
- **Thông báo tin nhắn**: đang ở tab khác mà người ấy nhắn thì app hiện thẻ nổi gradient ở đáy màn hình kèm rung nhẹ, chạm vào nhảy thẳng vào tab chat.
- Nhịp kiểm tra: 5 giây khi đang mở tab chat, 10 giây khi ở tab khác, 30 giây cho các dữ liệu còn lại.
- Huy hiệu số tin chưa đọc trên biểu tượng tab, và thẻ tin mới nhất ngay ở màn Cảm xúc.

**Thông báo khi app đã đóng**: có, qua dịch vụ miễn phí ntfy.sh. Mỗi máy cài thêm app ntfy một lần rồi đăng ký kênh riêng — xem `THONG-BAO-NTFY.md`. Cách này tránh được Firebase Cloud Messaging vốn cần `google-services.json`, plugin native và một server giữ khoá để gửi tin.

Dữ liệu nằm ở `couples/{mã cặp đôi}/chat/{ts}_{uid}`, giữ 300 tin gần nhất. Rules hiện tại đã phủ nhánh này.

## AI Coach — chọn 1 trong 4 dịch vụ

Vào **Cài đặt → AI Coach**, chạm ô để chọn:

| | Chi phí | Lấy key tại | Model mặc định |
|---|---|---|---|
| ⚡ **Groq** | Miễn phí, không cần thẻ | console.groq.com/keys | `llama-3.3-70b-versatile` |
| ✨ **Gemini** | Miễn phí, không cần thẻ | aistudio.google.com/apikey | `gemini-2.0-flash` |
| 🔀 **OpenRouter** | Miễn phí ở model đuôi `:free` | openrouter.ai/keys | `meta-llama/llama-3.3-70b-instruct:free` |
| 🤖 **ChatGPT** | Trả phí theo lượt, cần nạp tiền | platform.openai.com/api-keys | `gpt-4o-mini` |

Mặc định là **Groq** vì miễn phí và nhanh nhất.

**Key lưu riêng cho từng dịch vụ** — đổi qua đổi lại không phải nhập lại. Hết hạn mức bên này thì chạm sang bên kia dùng tiếp, đây là lý do nên nhập sẵn ít nhất hai key.

Ô **Model** để trống là dùng mặc định. Muốn đổi thì tra tên model trên trang của dịch vụ đó rồi gõ vào.

Vì sao thêm được nhiều dịch vụ dễ thế: Groq, OpenRouter và ChatGPT đều theo **chuẩn API giống hệt nhau**, chỉ khác địa chỉ endpoint. Riêng Gemini có định dạng riêng nên xử lý tách. Muốn thêm dịch vụ khác (Cerebras, NVIDIA NIM, Mistral...), chỉ cần thêm một dòng vào danh sách `aiProviders` trong `lib/main.dart`.

**Lưu ý về ChatGPT:** gói ChatGPT Plus không dùng được cho API — hai thứ tính tiền riêng. Muốn gọi API phải nạp tiền ở mục Billing.

## Vòng quay hẹn hò

Tab **Của mình → Vòng quay**. Bấm *Quay đi!* để chọn ngẫu nhiên địa điểm hoặc hoạt động cho hai đứa.

- Vẽ bằng `CustomPainter`, không thêm thư viện nào.
- Quay 5–8 vòng rồi chậm dần theo `easeOutCubic`, cho cảm giác có quán tính và ma sát.
- Rung nhẹ lúc bắt đầu, rung mạnh lúc dừng.
- Tự thêm/xoá ô, tối đa 12 ô cho chữ còn đọc được.
- Danh sách ô và kết quả lần quay gần nhất **đồng bộ hai máy** — bạn gái mở app cũng thấy "Vương vừa quay được Ăn lẩu".

## Duo Quiz — khoá đáp án hai chiều

Trước đây trả lời xong là thấy ngay ô của người kia nếu họ đã làm. Giờ đáp án **bị khoá cho tới khi cả hai cùng trả lời** câu đó — che luôn đáp án của chính mình, nên không ai đoán trước được.

Ô khoá hiện hai dấu tích cho biết ai đã trả lời, ai chưa. Khi đủ hai người, đáp án mở ra cạnh nhau. Nếu có câu trùng nhau, màn hình bắn **pháo hoa** — 5 chùm nổ lệch nhịp, hạt rơi theo trọng lực, cũng vẽ bằng `CustomPainter`.

## Cờ ca-rô (tab 5 dưới cùng)

Bàn 9×9, ai xếp được **5 quân liên tiếp** theo hàng, cột hoặc chéo là thắng.

- Đánh luân phiên qua Firebase, máy kia thấy nước đi sau tối đa 3 giây.
- Người bấm *Ván mới* cầm quân ✕ và đi trước; thắng xong bấm Ván mới thì tự đổi bên.
- Ô vừa đánh có viền tím, 5 ô thắng tô hồng.
- Tỷ số hai bên lưu trên Firebase nên không mất khi tắt app.
- Avatar bên nào sáng viền là bên đó đang tới lượt.

Thuật toán dò 5 quân đã được test riêng cho cả 4 hướng và trường hợp vắt qua biên bàn cờ.

## AI Coach

Chuyển vào **Của mình → AI Coach** (tab thứ 3), nhường chỗ dưới cùng cho Cờ ca-rô. Chức năng giữ nguyên, chỉ ẩn bớt tiêu đề cho gọn.

## Trang Cảm xúc

- Biểu đồ 7 ngày đổi từ cột sang **đường cong mượt** (Bezier) có vùng tô nhạt bên dưới, hai màu cho hai người.
- Ngày chưa ghi thì bỏ trống thay vì vẽ cột rỗng, nên nhìn ra xu hướng rõ hơn.
- Huy hiệu **🔥 chuỗi ngày ghi liên tiếp** ở góc phải. Hôm nay chưa ghi thì chuỗi chưa bị đứt.

## Cập nhật app không mất dữ liệu

APK được ký bằng khoá cố định `android/app/lovesync.jks` trong repo, và `versionCode` tự tăng theo số lần chạy workflow. Nhờ vậy bản mới cài đè lên bản cũ được, giữ nguyên dữ liệu.

Chi tiết và các lưu ý quan trọng nằm trong `CAP-NHAT-APP.md`.

## Cơ chế đồng bộ (để bạn biết mà xử lý khi có vấn đề)

```
couples/{mã cặp đôi}/
├── members/{uid máy A}   → tên, 60 ngày cảm xúc, đáp án quiz
├── members/{uid máy B}   → tên, cảm xúc, quiz
└── shared                → wishlist, kỷ niệm, ngày quan trọng, quỹ chung + mốc thời gian
```

- **Dữ liệu cá nhân** (cảm xúc, quiz): mỗi máy ghi vào nhánh riêng của mình, chỉ đọc nhánh của người kia → không bao giờ đè nhau.
- **Dữ liệu dùng chung** (wishlist, quỹ...): dùng cơ chế *last-write-wins* so theo mốc thời gian. Nếu hai người cùng sửa một lúc, bản lưu sau thắng. Với hai người dùng thì rủi ro này rất thấp.
- Mất mạng thì app vẫn chạy bình thường bằng dữ liệu cục bộ, có mạng lại sẽ tự đẩy lên.

## Về bảo mật — nói thẳng để bạn cân nhắc

Rules trên cho phép **bất kỳ ai biết mã cặp đôi** đều đọc/ghi được nhánh đó. Đây là đánh đổi để không phải làm đăng nhập Firebase Auth. Vì vậy:

- Dùng mã ngẫu nhiên 16 ký tự do app sinh, đừng đặt kiểu `vuonglinh2026`.
- Chỉ gửi mã qua tin nhắn riêng, không đăng lên nhóm hay GitHub.
- Không ghi thông tin nhạy cảm (số tài khoản, mật khẩu) vào ghi chú.

Nếu sau này muốn chặt chẽ hơn, bước nâng cấp là bật **Firebase Authentication (Anonymous)** và siết rule theo `auth.uid`. Cần thì tôi làm tiếp.

## Lỗi thường gặp

| Thông báo trong app | Nguyên nhân | Xử lý |
|---|---|---|
| Firebase từ chối truy cập | Rules chưa publish hoặc sai | Dán lại đoạn Rules ở Bước 1.5 |
| Sai Database URL | Copy thiếu / thừa ký tự | Copy lại từ tab Data, không có dấu `/` ở cuối |
| Đã đồng bộ, chưa thấy người ấy vào phòng | Máy kia chưa bấm Kết nối, hoặc mã lệch 1 ký tự | So lại từng ký tự mã trên hai máy |
| Mã cặp đôi phải từ 12 ký tự | Rule chặn mã ngắn | Bấm nút xúc xắc sinh mã mới |
| Máy người ấy không thấy ảnh | Bản ghi cũ chưa có ảnh thu nhỏ | Ảnh ghim từ bản này trở đi mới đồng bộ được |
