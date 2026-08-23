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

## Bản đồ kỷ niệm (Love Memories)

Vào tab **Của mình → Kỷ niệm → Ghim khoảnh khắc này**. Màn hình mở ra là app đã tự làm sẵn 2 việc:

- **Vị trí**: tự bật GPS lấy toạ độ, rồi đổi sang địa chỉ tiếng Việt (phường, quận, tỉnh) bằng `geocoding`. Có nút 🔄 để lấy lại nếu bắt sóng chậm. Mất mạng thì vẫn giữ toạ độ và hiển thị dạng số.
- **Thời gian**: gán `DateTime.now()` ngay lúc mở màn hình, không phải chọn.

Bạn chỉ cần bấm **Chụp ảnh** (hoặc chọn từ **Thư viện**) và viết ghi chú, rồi **Lưu kỷ niệm**.

Xem lại theo hai cách: **timeline** xếp mới nhất lên đầu, hoặc chạm banner hồng để mở **bản đồ** — mỗi kỷ niệm là một pin hình tròn có ảnh thu nhỏ, chạm vào pin hiện ảnh lớn kèm ghi chú.

### Cách ảnh được lưu và đồng bộ

| Thành phần | Nơi lưu | Có sang máy người ấy không |
|---|---|---|
| Toạ độ, địa chỉ, ngày giờ, ghi chú | SharedPreferences + Firebase | Có |
| Ảnh gốc (~1280px) | Thư mục riêng của app trên máy chụp | Không |
| Ảnh thu nhỏ 280px (~15 KB, base64) | Firebase, trong cùng bản ghi | Có |

Máy người kia hiển thị bản thu nhỏ, đủ để xem trên điện thoại. Làm vậy để tránh phải bật Firebase Storage (dịch vụ này nay yêu cầu gắn thẻ thanh toán) và để mỗi lần đồng bộ không bị nặng.

### Vì sao dùng flutter_map thay vì Google Maps

`google_maps_flutter` bắt buộc nhúng API key vào `AndroidManifest.xml`, mà workflow của bạn sinh lại thư mục `android/` mỗi lần build nên key sẽ mất. `flutter_map` lấy tile từ OpenStreetMap, không cần key, không cần cấu hình gì thêm.

### Quyền ứng dụng — workflow đã tự thêm

File `build.yml` mới tự chèn vào `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
<uses-feature android:name="android.hardware.location.gps" android:required="false"/>
```

và nâng `minSdk = 23` trong `android/app/build.gradle` (bắt buộc cho `geolocator`).
Nếu bạn build bằng Project IDX hay FlutLab thì phải tự dán đoạn XML trên vào ngay dưới thẻ `<manifest ...>`.

## Duo Quiz — bộ 3 câu đổi mới mỗi ngày

Ngân hàng **60 câu** chia 5 chủ đề: Tình yêu & Thói quen, Tài chính & Chi tiêu, Hôn nhân & Gia đình, Ngôn ngữ tình yêu, Giá trị sống & Cảm xúc.

Mỗi ngày app mở ra 3 câu mới dưới dạng thẻ vuốt ngang. Chọn xong một câu là thẻ tự trượt sang câu kế tiếp; thẻ cuối cùng là màn hình kết quả với vòng tròn % chạy dần và **tim bay** khi đạt từ 67% trở lên. Nút *So đáp án hai đứa* mở màn hình đối chiếu song song: cột hồng là bạn, cột tím là người ấy.

Icon 🕐 góc trên mở **Lịch sử thấu hiểu** — 3 tuần gần nhất, mỗi ngày một huy hiệu: 👑 Tri kỷ (100%), 💞 Ăn ý (≥67%), 🌤️ Khá hợp (≥34%), 🌱 Đang hiểu nhau. Chạm vào một ngày để xem lại đáp án của ngày đó.

### Cách hai máy luôn nhận cùng bộ câu hỏi

Không đồng bộ danh sách câu hỏi qua Firebase. Thay vào đó bộ 3 câu được tính từ chính ngày hiện tại:

```dart
_shuffled = List.from(quizBank)..shuffle(Random(20260101)); // seed cố định
start = (dayIndex(hôm nay) * 3) % 60;                        // lấy 3 câu liên tiếp
```

Seed cố định nên hai máy xáo trộn ra cùng một thứ tự, cùng ngày thì cùng `start` — luôn trùng nhau, kể cả khi đang offline. Ngân hàng 60 câu chia 3 câu/ngày nên **20 ngày mới lặp lại**.

Đáp án vẫn lưu ở key `quiz_me` như cũ, nghĩa là `sync.dart` không phải sửa gì. Lịch sử được dựng lại bằng cách tính ngược bộ câu hỏi của từng ngày rồi tra trong đáp án đã lưu — không tốn thêm dung lượng lưu trữ.

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
| "Định vị đang tắt" | GPS chưa bật | Vuốt thanh thông báo, bật Vị trí |
| "Quyền vị trí đang bị chặn" | Đã từ chối vĩnh viễn | Cài đặt máy → Ứng dụng → LoveSync → Quyền → Vị trí |
| Địa chỉ chỉ hiện toạ độ số | Không có mạng lúc ghim | Kỷ niệm vẫn lưu đúng chỗ, chỉ thiếu tên địa điểm |
| Bản đồ trắng, không có tile | Mất mạng | Tile lấy từ OpenStreetMap, cần Internet |
| Máy người ấy không thấy ảnh | Bản ghi cũ chưa có ảnh thu nhỏ | Ảnh ghim từ bản này trở đi mới đồng bộ được |
