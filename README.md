# 📱 Todo App dengan SQLite & SharedPreferences

Aplikasi Todo lokal berbasis Flutter dengan fitur autentikasi dan penyimpanan data offline menggunakan SQLite dan SharedPreferences.

## 🚀 Fitur Utama

- ✅ **Autentikasi Pengguna** - Register, Login, Logout
- ✅ **CRUD Todo** - Create, Read, Update, Delete todo items
- ✅ **Prioritas** - Low, Medium, High priority system
- ✅ **Filter & Pencarian** - Filter by status (All/Active/Completed) dan search
- ✅ **Penyimpanan Lokal** - SQLite untuk data, SharedPreferences untuk preferences
- ✅ **State Management** - Menggunakan BLoC/Cubit
- ✅ **Offline-First** - Bekerja sepenuhnya offline

## 📋 Prasyarat

- Flutter SDK 3.0.0 atau lebih baru
- Dart SDK
- Android Studio / VS Code dengan Flutter extension
- Emulator Android/iOS atau physical device

## 📦 Instalasi Dependencies

### **1. Tambahkan dependencies ke `pubspec.yaml`:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  
  # Database & Storage
  sqflite: ^2.3.0          # SQLite database
  path_provider: ^2.1.0    # File system paths
  shared_preferences: ^2.2.2 # Local preferences
  
  # Utilities
  equatable: ^2.0.5        # Value equality
  intl: ^0.19.0            # Internationalization
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### **2. Install dependencies:**

```bash
# Bersihkan cache terlebih dahulu
flutter clean

# Install semua dependencies
flutter pub get

# Jika ada error, coba repair cache
flutter pub cache repair
```

### **3. Links ke dokumentasi packages:**

| Package | Dokumentasi | Versi |
|---------|-------------|-------|
| **flutter_bloc** | [pub.dev/packages/flutter_bloc](https://pub.dev/packages/flutter_bloc) | ^8.1.3 |
| **sqflite** | [pub.dev/packages/sqflite](https://pub.dev/packages/sqflite) | ^2.3.0 |
| **shared_preferences** | [pub.dev/packages/shared_preferences](https://pub.dev/packages/shared_preferences) | ^2.2.2 |
| **path_provider** | [pub.dev/packages/path_provider](https://pub.dev/packages/path_provider) | ^2.1.0 |
| **equatable** | [pub.dev/packages/equatable](https://pub.dev/packages/equatable) | ^2.0.5 |
| **intl** | [pub.dev/packages/intl](https://pub.dev/packages/intl) | ^0.19.0 |

## 🏗️ Struktur Project

```
lib/
├── blocs/
│   ├── auth_cubit.dart        # Logic autentikasi
│   ├── auth_state.dart        # State autentikasi
│   ├── todo_cubit.dart        # CRUD todo logic
│   └── todo_state.dart        # Todo state
├── models/
│   ├── user_model.dart        # Model User
│   └── todo_model.dart        # Model Todo
├── database/
│   ├── database_helper.dart   # SQLite operations
│   └── preferences_helper.dart # SharedPreferences
├── pages/
│   ├── login_page.dart        # Halaman login
│   ├── register_page.dart     # Halaman register
│   ├── todo_page.dart         # Halaman utama todo
│   └── add_edit_todo_page.dart # Form todo
├── widgets/
│   ├── todo_item.dart         # Item todo
│   └── loading_indicator.dart # Loading widget
└── main.dart                  # Entry point
```

## 🚀 Menjalankan Aplikasi

### **1. Development mode:**

```bash
# Untuk Android emulator
flutter run -d emulator

# Untuk iOS simulator (macOS only)
flutter run -d simulator

# Untuk web browser
flutter run -d chrome

# Untuk physical device (pastikan USB debugging aktif)
flutter run
```

### **2. Build untuk production:**

```bash
# Build APK Android
flutter build apk --release

# Build App Bundle Android
flutter build appbundle --release

# Build untuk Web
flutter build web --release

# Build untuk Windows
flutter build windows --release

# Build untuk Linux
flutter build linux --release
```

## 🧪 Testing

```bash
# Run semua test
flutter test

# Run test dengan coverage
flutter test --coverage

# Generate lcov report
genhtml coverage/lcov.info -o coverage/html
```

## 🔧 Troubleshooting

### **Issue 1: Dependencies error**
```bash
# Clear semua cache
flutter clean
flutter pub cache repair
flutter pub get
```

### **Issue 2: Flutter tidak dikenali**
```bash
# Tambahkan Flutter ke PATH
# Windows:
set PATH=%PATH%;C:\src\flutter\bin

# macOS/Linux:
export PATH="$PATH:$HOME/flutter/bin"
```

### **Issue 3: Emulator tidak terdeteksi**
```bash
# Buka Android Studio
# Tools > AVD Manager > Create Virtual Device
# Atau jalankan emulator manual:
emulator -avd Pixel_4_API_30
```

### **Issue 4: SQLite permission error**
Tambahkan permission di `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

## 📚 Dokumentasi Lengkap

### **Package Links:**
- **Flutter Bloc**: [bloclibrary.dev](https://bloclibrary.dev/)
- **SQFlite**: [github.com/tekartik/sqflite](https://github.com/tekartik/sqflite)
- **Shared Preferences**: [flutter.dev/docs/cookbook/persistence/key-value](https://flutter.dev/docs/cookbook/persistence/key-value)

### **Tutorial:**
- [SQLite dengan Flutter](https://flutter.dev/docs/cookbook/persistence/sqlite)
- [SharedPreferences Guide](https://pub.dev/packages/shared_preferences)
- [BLoC Pattern](https://bloclibrary.dev/#/gettingstarted)

## 🤝 Kontribusi

1. Fork repository
2. Buat feature branch: `git checkout -b feature/namafitur`
3. Commit changes: `git commit -m 'Add some feature'`
4. Push ke branch: `git push origin feature/namafitur`
5. Buat Pull Request

## 📄 License

MIT License - lihat [LICENSE](LICENSE) untuk detail.

## 📞 Support

Jika mengalami masalah:
1. Cek `flutter doctor -v`
2. Pastikan semua dependencies terinstall: `flutter pub deps`
3. Buat issue di repository dengan detail error