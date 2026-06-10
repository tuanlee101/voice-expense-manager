# 🗣️ Voice Expense Manager

**Quản lý chi tiêu bằng giọng nói** — Flutter app cho phép bạn nhập và quản lý chi tiêu hàng ngày bằng giọng nói tiếng Việt.

## ✨ Tính năng

- 🎤 **Nhập chi tiêu bằng giọng nói** — Nói số tiền, danh mục, ghi chú, app tự động xử lý
- 🔐 **Bảo mật** — Master password + mã hoá AES-256 toàn bộ dữ liệu local
- 📊 **Báo cáo & Thống kê** — Biểu đồ chi tiêu theo ngày/tuần/tháng
- 💰 **Quản lý ngân sách** — Đặt ngân sách cho từng danh mục, nhận cảnh báo khi gần vượt
- 🗂 **Phân loại thông minh** — Tự động phân loại chi tiêu vào danh mục phù hợp
- 📱 **Đa nền tảng** — Android & iOS
- 🔄 **Đồng bộ** — Tuỳ chọn đồng bộ qua cloud

## 🏗 Kiến trúc

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── expense.dart
│   ├── budget.dart
│   ├── expense_category.dart
│   └── voice_command.dart
├── screens/                  # UI screens
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── expense_list_screen.dart
│   ├── report_screen.dart
│   └── settings_screen.dart
├── managers/                 # Business logic
│   ├── expense_manager.dart
│   ├── budget_manager.dart
│   ├── category_manager.dart
│   └── report_generator.dart
├── services/                 # Core services
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── app_state.dart
│   └── sync_service.dart
└── voice/                    # Voice processing
    ├── speech_recognition_engine.dart
    ├── voice_input_module.dart
    ├── nlp_processor.dart
    └── tts_engine.dart
```

## 🚀 Cài đặt & Chạy

```bash
# Clone
git clone https://github.com/tuanlee101/voice-expense-manager.git
cd voice-expense-manager

# Install deps
flutter pub get

# Run
flutter run
```

### Yêu cầu

- Flutter SDK ^3.12.1
- Dart SDK ^3.12.1

## 🛠 Công nghệ

- **Flutter** — UI framework
- **Provider** — State management
- **SQLite (sqflite)** — Local database
- **speech_to_text** — Nhận dạng giọng nói
- **flutter_tts** — Text-to-speech
- **fl_chart** — Biểu đồ & thống kê
- **flutter_secure_storage** — Mã hoá dữ liệu nhạy cảm
