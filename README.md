# 📱 Flutter Todo App

**Login • Register • CRUD Todo**
(MockAPI + BLoC Cubit + Async/Await)

---

## 📌 Deskripsi Project

Project ini adalah aplikasi **Todo List berbasis Flutter** yang menerapkan:

* 🔐 **Login & Register (Email + Password)**
* 👤 Relasi **User → Todo**
* 🔄 **CRUD Todo (Create, Read, Update, Delete)**
* 🌐 **REST API menggunakan MockAPI**
* 🧠 **State Management: BLoC (Cubit)**
* ⏳ **Async / Await**
* 🔁 **JSON Parsing**

Project ini cocok digunakan untuk:

* Materi perkuliahan Flutter
* Praktikum API & State Management
* Mini Project / UTS / UAS
* Latihan arsitektur aplikasi mobile

---

## 🛠️ Teknologi & Library

| Teknologi    | Keterangan         |
| ------------ | ------------------ |
| Flutter      | Framework UI       |
| Dart         | Bahasa Pemrograman |
| MockAPI      | REST API Dummy     |
| flutter_bloc | State Management   |
| http         | HTTP Request       |

---

## 📦 Install Library (pub.dev)

Tambahkan dependency berikut di file `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  flutter_bloc: ^8.1.3
  http: ^1.2.0
```

Lalu jalankan:

```bash
flutter pub get
```

📚 Referensi pub.dev:

* [https://pub.dev/packages/flutter_bloc](https://pub.dev/packages/flutter_bloc)
* [https://pub.dev/packages/http](https://pub.dev/packages/http)

---

## 🌐 API Endpoint (MockAPI)

### 👤 Users

```
GET    /users
POST   /users
```

Contoh data user:

```json
{
  "id": "1",
  "name": "name 1",
  "email": "email 1",
  "password": "password 1"
}
```

---

### 📝 Todo (berdasarkan user)

```
GET    /users/{userId}/todo
POST   /users/{userId}/todo
PUT    /users/{userId}/todo/{todoId}
DELETE /users/{userId}/todo/{todoId}
```

Contoh data todo:

```json
{
  "id": "1",
  "title": "title 1",
  "description": "description 1",
  "status": false,
  "userId": "1"
}
```

---

## 📂 Struktur Folder

```
lib/
 ┣ blocs/
 ┃ ┣ auth_cubit.dart        # Login & Register logic
 ┃ ┗ todo_cubit.dart        # CRUD Todo logic
 ┣ models/
 ┃ ┣ user_model.dart        # User model & JSON parsing
 ┃ ┗ todo_model.dart        # Todo model & JSON parsing
 ┣ pages/
 ┃ ┣ login_page.dart        # Halaman login
 ┃ ┣ register_page.dart     # Halaman register
 ┃ ┗ todo_page.dart         # Halaman todo
 ┗ main.dart                # Entry point aplikasi
```

---

## 🔐 Alur Login & Register

```
Input Email & Password
        ↓
GET /users (MockAPI)
        ↓
Validasi email & password
        ↓
AuthCubit emit(User)
        ↓
Masuk ke TodoPage
```

---

## 🔄 Alur CRUD Todo

```
User Login
   ↓
Ambil userId
   ↓
GET /users/{id}/todo
   ↓
Create / Update / Delete Todo
   ↓
Fetch ulang data Todo
```

---

## 🧠 State Management (BLoC Cubit)

* `AuthCubit`

  * Menyimpan state user login
  * Handle login, register, logout

* `TodoCubit`

  * Menyimpan list todo
  * Handle fetch, add, update, delete todo

---

## ⚠️ Catatan Penting

⚠️ Project ini menggunakan **MockAPI**
⚠️ Password disimpan dalam bentuk **plaintext**
⚠️ Tidak menggunakan JWT / Token

❗ **JANGAN digunakan untuk production**

Project ini dibuat khusus untuk:

* Pembelajaran
* Simulasi autentikasi
* Latihan REST API & State Management

---

## 🚀 Pengembangan Selanjutnya

Beberapa pengembangan yang bisa ditambahkan:

* 🔐 Hash password
* 💾 Auto login (SharedPreferences)
* ⏳ Loading & Error State
* 🏗️ Clean Architecture (Repository Pattern)
* 🧪 Unit Test & Widget Test

---

## 👨‍🏫 Author

**Muhammad Ikhwan Fathulloh**
Software Engineer • Lecturer • AI & IoT Mentor

---

## 📄 License

Project ini bebas digunakan untuk **edukasi dan pembelajaran**.