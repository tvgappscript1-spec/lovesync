# Bật thông báo khi app đã đóng

Làm một lần trên **mỗi máy**, khoảng 3 phút.

---

## Vì sao dùng ntfy.sh chứ không phải FCM

| | Firebase Cloud Messaging | ntfy.sh |
|---|---|---|
| Cần `google-services.json` | Có | Không |
| Cần plugin native + sửa Gradle | Có | Không |
| Cần server giữ khoá để gửi tin | Có | Không |
| Cài thêm app trên máy | Không | Có (app ntfy) |
| Chi phí | Miễn phí nhưng cần Blaze plan cho Cloud Functions | Miễn phí hoàn toàn |

FCM đòi đúng nhóm cấu hình đã gây ra chuỗi lỗi Gradle trước đây, lại còn cần một server giữ khoá service account để gửi tin. ntfy chỉ cần app gọi một HTTP POST — đổi lại mỗi người phải cài thêm một app nhỏ.

---

## Các bước

### 1. Cài app ntfy

Vào CH Play, tìm **ntfy** (biểu tượng chuông xanh lá, của Philipp Heckel). Miễn phí, không cần đăng ký tài khoản.

### 2. Lấy tên kênh trong LoveSync

Mở LoveSync → ⚙️ **Cài đặt** → kéo xuống mục **Thông báo khi app đã đóng** → bấm **Copy tên kênh**.

Tên kênh có dạng `lovesync-a7k2m9x4p1qr3wtz`, mỗi máy một kênh khác nhau.

### 3. Đăng ký kênh trong app ntfy

Mở app ntfy → bấm dấu **+** ở góc dưới phải → dán tên kênh vào ô **Topic name** → **Subscribe**.

Để nguyên server mặc định `ntfy.sh`, không cần đổi.

### 4. Kiểm tra

Quay lại LoveSync → **Gửi thông báo thử**. Trong vài giây app ntfy phải hiện thông báo "Thông báo hoạt động rồi 💕".

Không thấy gì thì kiểm tra: app ntfy có bị Android chặn chạy nền không (Cài đặt máy → Ứng dụng → ntfy → Pin → chọn *Không giới hạn*).

### 5. Người kia làm y hệt

Bạn gái cũng cài ntfy và đăng ký **kênh của máy cô ấy** (lấy trong LoveSync trên máy cô ấy, không phải kênh của bạn).

Sau đó mở LoveSync, chờ một vòng đồng bộ (tối đa 30 giây) để hai máy trao đổi tên kênh cho nhau. Từ đó nhắn tin là bên kia nhận được thông báo, kể cả khi LoveSync đã tắt hẳn.

---

## Hai công tắc trong Cài đặt

**Bật thông báo** — tắt thì người ấy không nhận báo khi bạn nhắn.

**Hiện nội dung tin trong thông báo** — mặc định **tắt**, thông báo chỉ ghi "Mở LoveSync để đọc nhé".

Nên để tắt. Kênh ntfy công khai với bất kỳ ai biết tên kênh, nên nội dung tin nhắn không nên đi qua đó. Tên kênh dài 16 ký tự ngẫu nhiên nên rất khó đoán, nhưng đừng đăng nó lên chỗ công khai.

---

## Hạn chế cần biết

- Thông báo do **máy người gửi** bắn đi. Nếu máy bạn mất mạng lúc gửi, tin vẫn lưu nhưng thông báo không đi được.
- ntfy.sh là dịch vụ miễn phí của bên thứ ba, không cam kết uptime. Thỉnh thoảng chậm vài giây là bình thường.
- Chỉ thông báo cho tin nhắn. Cảm xúc mới, kỷ niệm mới thì vẫn phải mở app xem.
- Android có thể ngủ đông app ntfy nếu lâu không dùng. Nếu thấy thông báo hay trễ, vào phần Pin của máy chọn *Không giới hạn* cho ntfy.

## Muốn riêng tư hơn

ntfy cho phép tự dựng server riêng hoặc đặt mật khẩu cho kênh (gói ntfy Pro). Với hai người dùng thì kênh ngẫu nhiên 16 ký tự và tắt hiện nội dung là đủ an toàn.
