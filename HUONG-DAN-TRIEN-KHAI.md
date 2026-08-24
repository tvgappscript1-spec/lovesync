# Cách đưa bản này lên GitHub (làm 1 lần, sau đó không lo lỗi Gradle nữa)

## Vì sao đổi cách làm

Trước đây workflow chạy `flutter create` để sinh thư mục `android/` mỗi lần build, rồi dùng script vá cấu hình. Cách đó mong manh: mỗi lần Flutter cập nhật là một lớp lỗi mới (compileSdk, NDK, desugaring, thứ tự `afterEvaluate`...).

Giờ thư mục `android/` nằm cố định trong repo, đã cấu hình sẵn đúng. Workflow chỉ còn việc tải thư viện và build.

---

## Bước 1 — Xoá sạch repo cũ

Vào `github.com/tvgappscript1-spec/lovesync` → **Settings** (của repo, không phải tài khoản) → kéo xuống cuối → **Delete this repository** → gõ tên repo để xác nhận.

Tạo lại repo mới cùng tên `lovesync`. Làm vậy nhanh hơn nhiều so với sửa từng file, và tránh sót file cũ gây lỗi.

> Nếu không muốn xoá: chỉ cần upload đè, nhưng phải **xoá thủ công** file `.github/workflows/build.yml` cũ trước.

## Bước 2 — Upload toàn bộ

Cách nhanh nhất, làm trên máy tính:

1. Tải file `lovesync-v2.zip`, giải nén ra một thư mục.
2. Vào repo mới → **uploading an existing file**.
3. Kéo thả **toàn bộ nội dung bên trong** thư mục vừa giải nén (không kéo cả thư mục cha).
4. Commit.

Kiểm tra sau khi upload — repo phải có đủ:

```
.github/workflows/build.yml
android/          <- 20 file cấu hình
lib/              <- 5 file Dart
pubspec.yaml
```

> Lưu ý: GitHub web không upload được thư mục rỗng và đôi khi bỏ qua file ẩn. Nếu thiếu `.github/`, tạo tay bằng **Create new file** với đường dẫn `.github/workflows/build.yml`.

Nếu dùng máy tính có Git thì nhanh hơn:

```bash
cd lovesync-v2
git init && git add -A && git commit -m "LoveSync v2 - android co dinh"
git branch -M main
git remote add origin https://github.com/tvgappscript1-spec/lovesync.git
git push -u origin main --force
```

## Bước 3 — Cấp quyền cho Actions

Repo → **Settings → Actions → General** → *Workflow permissions* → **Read and write permissions** → Save.

## Bước 4 — Chạy build

Tab **Actions** → *Build LoveSync APK* → **Run workflow**. Khoảng 8–12 phút cho lần đầu.

Tải APK ở tab **Releases** hoặc mục **Artifacts** trong lần chạy.

---

## Cấu hình đã đặt sẵn trong `android/`

| Mục | Giá trị | Lý do |
|---|---|---|
| `compileSdk` | 36 | AndroidX mới đòi tối thiểu 36 |
| `minSdk` | 23 | `geolocator`, `image_picker` yêu cầu ≥21 |
| `targetSdk` | 35 | mức ổn định hiện tại |
| AGP | 8.11.1 | hỗ trợ compileSdk 36 |
| Gradle | 8.13 | khớp AGP 8.11 |
| Kotlin | 2.1.20 | |
| Java | 11 (source/target) | tránh xung đột jvmTarget với plugin |
| desugaring | bật, `desugar_jdk_libs 2.1.4` | cho API Java 8+ trên máy cũ |
| `ndkVersion` | không khai báo | để Flutter tự chọn, tránh lệch phiên bản |
| Ký release | dùng debug key | cài trực tiếp, không lên Play Store |

Trong `android/build.gradle.kts` có khối `subprojects` kéo `compileSdk` của mọi plugin lên 36 — cần thiết vì nhiều plugin hardcode mức thấp hơn. Khối này đặt **trước** `evaluationDependsOn(":app")`, nếu đảo thứ tự sẽ lỗi *project is already evaluated*.

## Hai file cố tình không commit

- `android/gradlew` và `gradle-wrapper.jar`: workflow tự sinh bằng lệnh `gradle wrapper`. File `.jar` là binary, upload qua web hay hỏng.
- `android/local.properties`: chứa đường dẫn SDK riêng của từng máy, Flutter tự tạo lúc build.

## Muốn sửa cấu hình sau này

Sửa thẳng `android/app/build.gradle.kts` trên GitHub rồi chạy lại workflow. Cấu hình giờ thuộc về bạn, không bị ghi đè nữa.
