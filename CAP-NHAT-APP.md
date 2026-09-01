# Cập nhật app mà không mất dữ liệu

## Vì sao trước đây cài đè lại báo lỗi

Android chỉ cho cài đè khi APK mới có **cùng chữ ký số** với bản đang cài. Trước đây APK được ký bằng "debug key" — mà GitHub Actions tạo một debug key **mới toanh mỗi lần chạy**. Hai bản build khác chữ ký, nên máy sẽ báo *"Ứng dụng không được cài đặt"* và cách duy nhất là gỡ app đi cài lại, kéo theo mất sạch dữ liệu cục bộ.

## Cách đã xử lý

Trong repo giờ có sẵn khoá ký cố định:

```
android/app/lovesync.jks     <- khoá ký, hạn 30 năm
android/key.properties       <- mật khẩu để Gradle đọc khoá
```

Mọi bản build đều ký bằng khoá này, nên chữ ký không đổi. Ngoài ra workflow tự tăng `versionCode` theo số lần chạy (`github.run_number`), để Android hiểu bản mới là bản nâng cấp.

Kết quả: **anh chỉ cần gửi file APK mới, mở lên, bấm Cập nhật.** Toàn bộ cảm xúc, tin nhắn, kỷ niệm, wishlist, mã cặp đôi, API key đều giữ nguyên.

## Kiểm tra chữ ký có đúng không

Trong log workflow, mở bước **Kiem tra chu ky APK**. Nó in ra dấu vân tay SHA-256. Con số này phải **giống hệt nhau ở mọi lần build**. Nếu đổi, nghĩa là repo thiếu file `lovesync.jks` hoặc `key.properties`.

Bước **Kiem tra cau truc project** cũng cảnh báo sẵn nếu thiếu hai file này.

## Ba điều quan trọng

**1. Đừng bao giờ xoá hoặc tạo lại `lovesync.jks`.** Mất khoá này là mất luôn khả năng cập nhật — bản build sau sẽ khác chữ ký, phải gỡ cài đặt và mất dữ liệu. Nên tải file đó về máy cất riêng một bản.

**2. Nên để repo ở chế độ Private.** Khoá ký và mật khẩu đang nằm trong repo. Với app dùng riêng hai người thì rủi ro thấp, nhưng để public nghĩa là ai cũng tải được khoá và ký một APK giả mạo cùng chữ ký. Vào **Settings → General → Danger Zone → Change repository visibility → Private**.

**3. Bản cài lần đầu phải là bản đã ký khoá mới.** APK cũ trên máy anh và bạn gái đang ký bằng debug key, nên **lần này vẫn phải gỡ app cũ rồi cài lại**. Từ lần sau trở đi mới cập nhật đè được.

> Muốn giữ dữ liệu đang có trước khi gỡ: mở Cài đặt → **Copy thông tin kết nối**, lưu lại URL và mã cặp đôi. Cài bản mới xong nhập lại đúng hai dòng đó là toàn bộ dữ liệu trên Firebase (cảm xúc, quiz, tin nhắn, wishlist, kỷ niệm) tự tải về. Chỉ mất ảnh gốc độ phân giải cao lưu cục bộ; bản thu nhỏ vẫn còn.

## Quy trình cập nhật từ giờ

1. Em gửi file `.dart` mới → anh chép đè vào thư mục local → GitHub Desktop → Commit → Push.
2. Actions tự build, khoảng 8–10 phút.
3. Vào tab **Releases**, tải `LoveSync-arm64.apk`.
4. Mở file → bấm **Cập nhật** → xong, dữ liệu nguyên vẹn.
5. Gửi file đó cho bạn gái, cô ấy cũng bấm Cập nhật.
