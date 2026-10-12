# Tích hợp chatbot vào Flutter

Project mẫu mở chatbot trong popup bằng `flutter_inappwebview`, với hai cách tích hợp:

| | V1 — Direct link | V2 — Widget script + iframe |
|---|---|---|
| Widget Flutter | `ChatbotPopup` | `ChatbotPopupV2` |
| Nội dung WebView | Tải trực tiếp `/embed?...` | Tải HTML cha, chạy `widget.js` để tạo iframe |
| Token và thông tin người dùng | Chưa tích hợp auth bridge | Có getter qua JavaScript bridge |
| Trường hợp sử dụng | Chat public, không cần truyền token từ app | Chat cần token, employeeCode, ngôn ngữ và renew token |

App mẫu trong `lib/main.dart` đang mở **V2**. V2 hiện có dữ liệu xác thực thử nghiệm trong code; cần thay bằng auth service của app trước khi sử dụng thực tế. Luồng refresh trong bản mẫu vẫn trả token giả.

## 1. Chuẩn bị project

Thêm dependency vào `pubspec.yaml` của app:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_inappwebview: ^6.1.5
```

Chạy:

```bash
flutter pub get
```

Để chạy nguyên project mẫu, dùng Flutter SDK đáp ứng khai báo Dart `^3.13.5` trong `pubspec.yaml`. Khi copy sang app khác, kiểm tra khả năng tương thích với SDK và plugin của app đó.

### Android

Thêm quyền Internet vào `android/app/src/main/AndroidManifest.xml`, bên ngoài thẻ `<application>` để áp dụng cả bản release:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application ...>
        ...
    </application>
</manifest>
```

Giữ `android:hardwareAccelerated="true"` và `android:windowSoftInputMode="adjustResize"` trên activity để WebView và bàn phím hoạt động đúng.

Project mẫu dùng AGP 9.1.0, Gradle 9.3.1 và Kotlin 2.4.0. Plugin Android `flutter_inappwebview_android` 1.1.3 có cấu hình ProGuard không tương thích AGP 9, nên project dùng bản local đã sửa hai dòng ProGuard.

Nếu app của bạn cũng gặp lỗi `getDefaultProguardFile('proguard-android.txt')`, copy thư mục `third_party/flutter_inappwebview_android` vào app và thêm:

```yaml
dependency_overrides:
  flutter_inappwebview_android:
    path: third_party/flutter_inappwebview_android
```

Chi tiết tại [PATCH.md](third_party/flutter_inappwebview_android/PATCH.md). Không cần đổi bộ SDK/Gradle đang chạy tốt chỉ để copy các widget Flutter.

### iOS

Chạy `flutter pub get`, sau đó build/run bằng Flutter như thông thường để cài plugin native. Các URL mẫu dùng HTTPS. Bản tích hợp script/iframe đã được thử trên Android emulator; cần kiểm tra thêm trên iOS, đặc biệt origin của HTML cha và hành vi bàn phím. Ví dụ hiện tại chưa triển khai quyền camera/microphone hoặc upload file.

## 2. Cấu hình server và URL params

Copy `lib/chatbot_config.dart` vào app. Chỉnh domain tại một nơi:

```dart
const chatbotBaseUrl = 'https://chat.antt.tech';
```

Dùng origin có scheme, không thêm path hoặc dấu `/` cuối. Cả hai phiên bản dùng cấu hình này cho URL và kiểm tra origin của bridge.

| Tham số | Ý nghĩa |
|---|---|
| `id` | ID bot cần mở |
| `mode` | Cả V1 và V2 dùng `mobile` để chat phủ kín WebView |
| `client_id` | Mã app tích hợp |
| `session_id` | Phiên hội thoại; app nên cung cấp theo người dùng/phiên hiện tại |
| `color` | Màu chủ đạo dạng hex, không có `#` |
| `language` | Ngôn ngữ ban đầu, ví dụ `en` hoặc `vi` |
| `position` | Vị trí widget trên web |
| `auto_open` | `mode=mobile` tự mở chat; mode widget dùng `true` để mở ngay |
| `auto_init` | V2 đặt `false` để đợi native bridge rồi gọi `ChatWidget.init()` một lần |
| `v` | Giá trị version/cache busting của URL script hoặc trang |

V1 sửa `chatbotUrl` trong `lib/chatbot_popup.dart`. V2 sửa `chatbotWidgetScriptUrl` trong `lib/chatbot_widget_host.dart`. Hai URL hiện có `session_id` mẫu riêng; hãy thay cả hai nếu dùng cả V1 và V2.

Nếu tạo URL từ dữ liệu động, dùng `Uri` và `queryParameters` để encode giá trị đúng. Không truyền access token hoặc refresh token trong URL.

## 3. Tích hợp V1 — Direct link

Copy các file:

- `lib/chatbot_config.dart`
- `lib/chatbot_popup.dart`

Import và mở popup từ nút trong app:

```dart
import 'package:flutter/material.dart';
import 'chatbot_popup.dart';

Future<void> openChatbot(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: ChatbotPopup(),
    ),
  );
}
```

`ChatbotPopup` tải `/embed` trực tiếp, bật JavaScript/DOM storage, hiển thị tiến trình tải và nút thử lại khi lỗi. FE quản lý layout `mode=mobile`; Flutter không inject CSS vào trang.

Nút header của website phát `CHAT_CLOSE` và `TOGGLE_FULLSCREEN`; bridge chuyển chúng sang Flutter để đóng hoặc thay đổi kích thước popup. FE đang deploy phải hỗ trợ các nút/sự kiện này ở mode được chọn. Bản V1 không có nút X riêng của Flutter.

**V1 chưa truyền token, employeeCode hoặc xử lý renew token.** Chỉ ghi token vào `localStorage` hoặc header của request tải trang không tự cung cấp token cho các API request của FE. Nếu cần auth từ app, dùng V2 hoặc bổ sung native auth bridge vào FE.

## 4. Tích hợp V2 — Widget script + iframe

Copy các file:

- `lib/chatbot_config.dart`
- `lib/chatbot_widget_host.dart`
- `lib/chatbot_popup_v2.dart`

Mở popup giống V1, thay widget:

```dart
import 'package:flutter/material.dart';
import 'chatbot_popup_v2.dart';

Future<void> openChatbotV2(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: ChatbotPopupV2(),
    ),
  );
}
```

### Luồng hoạt động

```text
Flutter mở popup V2
→ WebView tải HTML cha từ initialData
→ HTML tải widget.js với URL params
→ đợi flutterInAppWebViewPlatformReady
→ gọi ChatWidget.init() với các getter
→ widget.js tạo iframe /embed
→ iframe phát CHATBOT_READY
→ widget.js gọi getter Flutter và gửi AUTH/LANGUAGE/EMPLOYEE_CODE vào iframe
→ FE dùng thông tin để gọi API
```

HTML cha được tải cục bộ với `baseUrl` và `historyUrl` là `$chatbotBaseUrl/flutter-chatbot-v2`; không cần tạo endpoint này trên server. Base URL cung cấp origin cho HTML cha. `widget.js` và FE phải cho phép hostname/origin tương ứng; khi đổi domain, kiểm tra lại allowlist phía FE.

URL params quyết định cấu hình widget. `ChatWidget.init()` chỉ truyền callback:

```javascript
const widget = await window.ChatWidget.init({
  getToken: () => callNative('getToken'),
  onTokenRefresh: () => callNative('onTokenRefresh'),
  getLanguage: () => callNative('getLanguage'),
  getEmployeeCode: () => callNative('getEmployeeCode'),
  onClose: () => callNative('chatbotV2Control', 'CHAT_CLOSE'),
  onFullscreenChange: data =>
    callNative('chatbotV2Control', 'TOGGLE_FULLSCREEN', data),
});
```

`callNative()` đợi bridge sẵn sàng và gọi `window.flutter_inappwebview.callHandler(...)`. Tên callback web và handler Flutter được giữ đồng bộ.

### Thay dữ liệu thử nghiệm bằng auth service

Trong `_registerBridge()` của `lib/chatbot_popup_v2.dart`, thay phần `return switch (name)` hiện tại bằng lời gọi service của app. Ví dụ dưới đây minh hoạ contract; `authService`, `settingsService` và `userService` là service bạn cần cung cấp, không có sẵn trong project:

```dart
return switch (name) {
  'getToken' => await authService.getValidAccessToken(),
  'onTokenRefresh' => await authService.renewAccessToken(),
  'getLanguage' => settingsService.languageCode,
  'getEmployeeCode' => userService.employeeCode,
  _ => null,
};
```

| Handler | Kết quả cần trả |
|---|---|
| `getToken` | Access token hiện tại; có thể renew trước khi trả nếu gần hết hạn |
| `onTokenRefresh` | Access token mới sau khi renew thành công |
| `getLanguage` | Mã ngôn ngữ, ví dụ `en`/`vi` |
| `getEmployeeCode` | Mã nhân viên của người dùng đang đăng nhập |

Trả token thuần, không thêm tiền tố `Bearer`; FE tự thêm vào header `Authorization`. Không trả refresh token sang WebView. Xoá dữ liệu xác thực hardcode và `_refreshCount` khi chuyển sang service thật.

`getLanguage()` ưu tiên hơn tham số `language` trong URL lúc `init()`. FE hiện gửi `EmployeeCode`/`x-employee-code` và `Accept-Language`/`x-language` trong các API request sau khi nhận dữ liệu bridge.

### Renew token

```text
API trả 401
→ FE gửi REFRESH_TOKEN với channel hiện tại
→ widget.js gọi onTokenRefresh()
→ Flutter renew bằng auth service
→ widget.js gửi AUTH với token mới
→ FE thử lại request
```

Handler refresh phải cập nhật token trong auth service để lần gọi `getToken` sau trả giá trị mới. Nếu nhiều thành phần của app có thể renew đồng thời, auth service nên dùng chung một tác vụ renew đang chạy.

Khi renew thất bại, xử lý hết phiên đăng nhập ở Flutter. Bản mẫu chưa triển khai đăng nhập lại; trả `null`/lỗi không tự chuyển người dùng sang màn hình login.

### Thu nhỏ, phóng to và trạng thái lỗi

- `CHAT_CLOSE`: đóng popup Flutter.
- `TOGGLE_FULLSCREEN`: phóng to hoặc trả popup về kích thước ban đầu.
- `widget.js` kiểm tra origin, source iframe, bot ID và channel trước khi gọi callback công khai `onClose` / `onFullscreenChange`. HTML cha chuyển callback sang native handler; Flutter tiếp tục kiểm tra URL host.
- `barrierDismissible: false` và `PopScope(canPop: false)` chặn bấm ngoài/Back. Không có nút X Flutter; dùng nút thu nhỏ trên website để đóng.
- V2 có nút thử lại và nút đóng khi xảy ra lỗi tải được phát hiện.

V2 dùng `widget.js?mode=mobile&auto_init=false`. FE tự mở chat, không tạo launcher/greeting bubble ngoài khung chat và cho iframe phủ kín WebView khi resize. Flutter chỉ quản lý kích thước Dialog, auth/context và trạng thái tải; HTML host không inject CSS vào iframe, không dùng `MutationObserver` hoặc truy cập `window.__chatWidget` / `_authBridge`.

Cần deploy bản FE có hỗ trợ mobile layout và callback công khai trước khi chạy bản Flutter này. Tham số `v` chỉ đổi cache key, không thay thế bước deploy. `initialized` nghĩa là `ChatWidget.init()` đã trả instance, chưa xác nhận hội thoại/API sẵn sàng.

## 5. Nút mở chatbot bằng avatar GIF

Có thể lấy phần `FloatingActionButton.large` trong `lib/main.dart`. Avatar tải từ `$chatbotBaseUrl/avatar.gif`, kích thước 96 px, nền trong suốt và không có bóng. Khi tải ảnh lỗi, app hiển thị icon chat dự phòng.

## 6. Chạy và kiểm tra

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Các widget test dùng WebView giả để kiểm tra getter, refresh mẫu và điều khiển popup; không xác nhận token hợp lệ hoặc API trả lời thành công. Muốn kiểm tra hội thoại có xác thực, cần token thật từ auth service.

Build APK debug riêng ARM64 để giảm kích thước khi thử trên emulator ARM64:

```bash
flutter build apk --debug --split-per-abi --target-platform android-arm64
```

APK ở `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`.

| Hiện tượng | Cần kiểm tra |
|---|---|
| API trả 401 | Token hết hạn/không hợp lệ; handler renew còn trả dữ liệu giả |
| V2 trống hoặc báo lỗi khởi tạo | URL script, Internet, origin HTML cha và allowlist FE |
| Không thấy nút thu nhỏ/phóng to | Mode và phiên bản FE đang deploy có hỗ trợ nút header |
| Có khoảng trắng trong popup | Kích thước iframe và CSS khung trang; phân biệt với inset của Dialog Flutter |
| Bàn phím che ô nhập | `adjustResize`, WebView và layout FE trên thiết bị thực |
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` | Dung lượng emulator; thử APK tách đúng ABI hoặc giải phóng bộ nhớ |
| Lỗi ProGuard với AGP 9 | Áp dụng bản local plugin theo phần Android |

Sau khi đổi domain, hằng số URL hoặc HTML host, nên hot restart rồi mở lại popup để tránh dùng các giá trị đã khởi tạo trước đó.
