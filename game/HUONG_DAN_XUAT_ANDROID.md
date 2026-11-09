# The Little Bookshop – Sprint 0: chạy thử và xuất bản Android

Bản thử này có: một căn phòng 3D nhìn chéo, 3 kệ sách, quầy thu ngân, khách đi vào tiệm, nút "Bán sách" để nhận tiền, và bộ đếm FPS (số khung hình mỗi giây – càng cao càng mượt).

Điều khiển: kéo một ngón để di chuyển camera · chụm hai ngón (hoặc lăn chuột) để phóng to/thu nhỏ · nút "Xoay phòng" · chạm vào kệ sách để chọn.

## A. Chạy thử trên Mac (khoảng 15 phút)

1. Vào godotengine.org > Download > macOS, tải bản **Godot 4 Standard** (không lấy bản .NET).
2. Mở file .dmg, kéo Godot vào Applications. Nếu macOS chặn: chuột phải vào Godot > Open.
3. Trong Godot bấm **Import**, chọn file `game/project.godot` trong thư mục này > **Import & Edit**. Nếu Godot hỏi chuyển đổi phiên bản thì đồng ý.
4. Bấm nút **▶ (Run Project)** ở góc trên bên phải. Dùng chuột để thử: kéo, lăn chuột, bấm vào kệ, chờ khách tới quầy rồi bấm "Bán sách".

## B. Chuẩn bị xuất Android (cài một lần, khoảng 1 giờ – phần lớn là chờ tải)

5. **Cài Java 17:** vào adoptium.net, tải **Temurin 17 (LTS)** cho macOS, chọn bản **x64 .pkg** (máy MacBook Air 2018 dùng chip Intel), rồi cài như phần mềm bình thường.
6. **Cài Android SDK** (bộ công cụ Android): cách dễ nhất là cài **Android Studio** từ developer.android.com. Mở Android Studio > More Actions > **SDK Manager**, đánh dấu Android SDK Platform và Android SDK Build-Tools đúng phiên bản mà trang "Exporting for Android" của Godot yêu cầu cho bản Godot bạn đang dùng. Ghi lại đường dẫn "Android SDK Location" (thường là `/Users/singuyen/Library/Android/sdk`).
7. Trong Godot: **Editor > Editor Settings > Export > Android**
   - Java SDK Path: `/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`
   - Android SDK Path: đường dẫn ở bước 6.
8. Trong Godot: **Editor > Manage Export Templates > Download and Install** (gói khá nặng, chờ tải xong).

## C. Xuất file APK và cài lên điện thoại

9. **Project > Export > Add… > Android.**
10. Ở mục Package, điền **Unique Name**: `com.trungnguyen.littlebookshop`. Nếu phía dưới còn dòng chữ đỏ báo lỗi, làm theo lỗi đó (thường là thiếu đường dẫn ở bước 7).
11. Bấm **Export Project…**, để nguyên "Export With Debug", đặt tên `TheLittleBookshop.apk`, lưu vào thư mục này.
12. Gửi file APK sang điện thoại (cáp, Google Drive hoặc Zalo), mở file, cho phép **cài ứng dụng từ nguồn không xác định**, rồi cài.

Cách nhanh hơn từ lần thứ hai: bật **Tùy chọn nhà phát triển > Gỡ lỗi USB** trên điện thoại, cắm cáp vào Mac, rồi bấm biểu tượng Android ở góc trên bên phải Godot để chạy thẳng lên máy.

## D. Kiểm tra trên điện thoại (cổng 1 của Sprint 0)

- [ ] FPS luôn từ 30 trở lên, kể cả khi xoay phòng
- [ ] Kéo, chụm hai ngón, xoay phòng đều hoạt động, không bị giật
- [ ] Chạm trúng kệ sách dễ dàng, không chạm nhầm
- [ ] Khách đi tới quầy, bấm "Bán sách" thì tiền tăng 15
- [ ] Chữ tiếng Việt hiển thị đúng dấu

Ghi lại tên điện thoại bạn thử và số FPS thấp nhất bạn thấy.
