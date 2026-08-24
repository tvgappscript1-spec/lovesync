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

Vào tab **Của mình → Kỷ niệm → Ghim khoảnh khắc này**:

- **Thời gian**: tự gán `DateTime.now()` ngay khi mở màn hình, không phải chọn.
- **Địa điểm**: gõ tay. Những nơi đã ghim trước đó hiện thành nút bấm một chạm, nên lần sau tới quán cũ chỉ cần chạm là xong.
- **Ảnh**: chụp trực tiếp hoặc chọn từ thư viện.
- **Ghi chú**: viết cảm xúc, câu nói, món đã ăn.

### Vì sao bỏ GPS và bản đồ

Bản đầu dùng `geolocator` + `geocoding` để tự lấy toạ độ và đổi thành địa chỉ, kèm `flutter_map` hiển thị pin. Ba thư viện này là nguồn gốc của hầu hết lỗi Gradle khi build APK (xung đột compileSdk, NDK, AAR metadata). Đổi lại chỉ tiết kiệm được vài giây gõ tên quán.

Đã gỡ cả ba. Dự án giờ chỉ còn `image_picker` và `path_provider` là plugin native, build nhẹ và ổn định hơn nhiều.

### Cách ảnh được lưu và đồng bộ

| Thành phần | Nơi lưu | Có sang máy người ấy không |
|---|---|---|
| Địa điểm, thời gian, ghi chú | SharedPreferences + Firebase | Có |
| Ảnh gốc (~1280px) | Thư mục riêng của app trên máy chụp | Không |
| Ảnh thu nhỏ 280px (~15 KB, base64) | Firebase, trong cùng bản ghi | Có |

Làm vậy để tránh phải bật Firebase Storage (nay yêu cầu gắn thẻ thanh toán) và giữ mỗi vòng đồng bộ đủ nhẹ.

### Quyền ứng dụng

Đã đặt sẵn trong `android/app/src/main/AndroidManifest.xml`: `INTERNET`, `CAMERA`, `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE` (chỉ tới Android 12). Không còn quyền vị trí.

## Thủ thỉ (nhắn tin)

Tab 💬 giữa Cảm xúc và Duo Quiz. Dùng chung Firebase Realtime Database đã cấu hình, không cần thêm dịch vụ nào.

- Bong bóng chat: tin của bạn nền gradient hồng bên phải, tin người ấy nền trắng bên trái.
- Tin chỉ có emoji (≤3 ký tự) hiển thị to, không bọc bong bóng.
- Hàng **câu gửi nhanh** phía trên ô nhập: chạm là gửi luôn, không phải gõ.
- Khi đang mở tab này, app tải tin mới mỗi **5 giây**; các tab khác vẫn theo nhịp 30 giây.
- Huy hiệu số tin chưa đọc hiện trên biểu tượng tab, và thẻ tin mới nhất hiện ngay ở màn Cảm xúc.
- Gửi lúc mất mạng: tin vẫn hiện trên máy bạn nhưng chưa lên server. App báo rõ, gửi lại khi có mạng.

Dữ liệu nằm ở `couples/{mã cặp đôi}/chat/{ts}_{uid}`, giữ 300 tin gần nhất cho nhẹ máy. Rules hiện tại đã phủ nhánh này, không cần sửa gì trên Firebase.

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
