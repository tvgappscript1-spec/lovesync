# LoveSync — Hướng dẫn khi mới cài app

Làm 1 lần duy nhất, khoảng 5 phút. Cả hai máy đều phải làm.

---

## Phần 1 — Lấy thông tin kết nối (chỉ Vương làm)

### 1.1. Lấy Database URL từ Firebase

1. Vào https://console.firebase.google.com → chọn project **lovesync**
2. Cột trái: **Databases & Storage → Realtime Database**
3. Tab **Data**, dòng trên cùng là URL, dạng:
   ```
   https://lovesync-xxxxx-default-rtdb.asia-southeast1.firebasedatabase.app
   ```
4. Copy nguyên dòng đó. **Không lấy dấu `/` ở cuối.**

> Nếu chưa tạo Database: bấm **Create Database** → chọn location **Singapore (asia-southeast1)** → **Start in locked mode** → Enable.

### 1.2. Dán Rules (bắt buộc, không làm sẽ báo "Firebase từ chối truy cập")

Vào tab **Rules**, xoá hết và dán đoạn này rồi bấm **Publish**:

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

### 1.3. Lấy Gemini API key (để bật AI Coach)

1. Vào https://aistudio.google.com/apikey
2. Bấm **Create API key** → copy chuỗi bắt đầu bằng `AIza...`

Miễn phí. Một key dùng chung cho cả hai máy được.

---

## Phần 2 — Thiết lập trên máy Vương

Mở app → màn hình **Cảm xúc** → bấm biểu tượng ⚙️ góc trên bên phải.

### 2.1. Mục "Hai chúng mình"

| Ô | Điền gì |
|---|---|
| Ảnh đại diện | Chạm vòng tròn → chọn 1 trong 36 emoji |
| Tên bạn | Tên Vương |
| Tên người ấy | Tên bạn gái (sau khi ghép đôi sẽ tự cập nhật) |
| Ngày bắt đầu yêu | Chạm để chọn trên lịch |

Bấm **Lưu thông tin**.

### 2.2. Mục "Ghép đôi (đồng bộ tự động)"

1. **Firebase Database URL**: dán URL ở bước 1.1
2. **Mã cặp đôi**: bấm biểu tượng 🎲 để app tự sinh mã 16 ký tự
3. Bấm **Kết nối & đồng bộ ngay**
4. Bấm **Copy thông tin kết nối** → dán vào Zalo gửi bạn gái

Thấy dòng "Đã tạo phòng mới" hoặc "Đã đồng bộ" là đúng.

### 2.3. Mục "AI Coach (Gemini)"

Dán API key ở bước 1.3 → kéo lên bấm lại **Lưu thông tin**.

> Lưu ý: ô API key nằm ở mục riêng nhưng nút lưu là nút **Lưu thông tin** ở mục "Hai chúng mình". Nhớ bấm sau khi dán key.

---

## Phần 3 — Thiết lập trên máy bạn gái

1. Cài file `LoveSync-arm64.apk` (Vương gửi qua Zalo, chọn *Gửi file* chứ không phải ảnh)
2. Mở file → bật **Cho phép cài từ nguồn này** → nếu báo cảnh báo, chọn **Vẫn cài đặt**
3. Mở app → ⚙️ Cài đặt
4. Mục "Hai chúng mình": chọn emoji, điền tên mình → **Lưu thông tin**
5. Mục "Ghép đôi": dán **đúng 2 dòng** Vương gửi:
   - Firebase Database URL
   - Mã cặp đôi
6. Bấm **Kết nối & đồng bộ ngay**
7. Muốn dùng AI Coach thì dán thêm API key → **Lưu thông tin**

Thấy "Đã đồng bộ với [tên Vương]" là xong.

---

## Phần 4 — Kiểm tra đã kết nối chưa

Mỗi người ghi cảm xúc hôm nay: màn hình **Cảm xúc** → chọn mức 1–5 → chọn thẻ ảnh hưởng → viết vài dòng → **Lưu cảm xúc hôm nay**.

Chờ tối đa 30 giây, hoặc kéo màn hình xuống để đồng bộ ngay.

Nếu thấy avatar và tâm trạng của người kia hiện lên, kèm vòng tròn **% đồng điệu** → đã kết nối thành công.

---

## Bốn tính năng chính

| Tab | Làm gì |
|---|---|
| 💗 **Cảm xúc** | Ghi tâm trạng mỗi ngày, xem % đồng điệu, biểu đồ 7 ngày |
| 🧩 **Duo Quiz** | 3 câu mới mỗi ngày, vuốt để trả lời, so đáp án, xem lịch sử |
| ✨ **AI Coach** | Đọc cảm xúc cả hai rồi gợi ý cách quan tâm, chủ đề trò chuyện |
| 📦 **Của mình** | Kỷ niệm có ảnh, Wishlist, Ngày quan trọng, Quỹ chung |

---

## Lỗi thường gặp

| Thông báo | Cách xử lý |
|---|---|
| Firebase từ chối truy cập | Chưa Publish Rules ở bước 1.2 |
| Sai Database URL | Copy lại từ tab Data, bỏ dấu `/` cuối |
| Đã đồng bộ, chưa thấy người ấy | Máy kia chưa bấm Kết nối, hoặc mã lệch ký tự — so lại từng ký tự |
| Mã cặp đôi phải từ 12 ký tự | Bấm 🎲 sinh mã mới |
| AI Coach báo mã 400 | API key sai hoặc dư khoảng trắng, dán lại |
| AI Coach báo mã 429 | Vượt hạn mức miễn phí, chờ vài phút |
| Cài APK báo "ứng dụng có hại" | Chọn *Vẫn cài đặt* — do APK ký debug, không qua Play Store |

---

## Vài điều nên biết

- **Đồng bộ**: tự chạy mỗi 30 giây và mỗi lần mở lại app. Muốn ngay thì kéo màn hình xuống.
- **Mất mạng**: app vẫn ghi bình thường, có mạng lại sẽ tự gửi đi.
- **Ảnh kỷ niệm**: ảnh gốc nằm trên máy chụp, máy kia nhận bản thu nhỏ. Đây là cách tránh phải trả phí Firebase Storage.
- **Bảo mật**: ai biết mã cặp đôi là đọc được dữ liệu. Chỉ gửi qua tin nhắn riêng, đừng đăng lên nhóm hay mạng xã hội. Cũng đừng ghi số tài khoản hay mật khẩu vào ghi chú.
- **Đổi tên/avatar**: sửa xong bấm Lưu, máy kia thấy trong vòng 30 giây.
