# NARATA - Aplikasi Blog

NARATA merupakan aplikasi mobile untuk mengelola dan menampilkan artikel secara terstruktur. Aplikasi ini dibuat sebagai bagian dari **Uji Level Kompetensi Keahlian Rekayasa Perangkat Lunak (RPL)**.

Aplikasi dibangun menggunakan **Flutter** sebagai client, **Node.js + Express.js** sebagai backend REST API, dan **MySQL** sebagai database.

## ✨ Features

- Menampilkan daftar artikel
- Melihat detail artikel
- Menambahkan artikel
- Mengedit artikel
- Menghapus artikel
- Menampilkan kategori artikel
- Menambahkan kategori
- Mengedit kategori
- Menghapus kategori
- Menampilkan artikel berdasarkan kategori
- Upload gambar artikel
- Validasi data
- Komunikasi dengan REST API
- Response API menggunakan JSON

## 🛠️ Tech Stack

### Mobile App
- Flutter
- Dart
- Dio
- Image Picker
- Flutter Dotenv
- Cached Network Image

### Backend
- Node.js
- Express.js
- TypeScript
- REST API
- Zod
- Multer

### Database
- MySQL

### Tools
- Visual Studio Code
- Postman / Thunder Client
- Git
- GitHub

## 🏗️ Architecture

NARATA menggunakan arsitektur client-server.

```text
┌─────────────────────────┐
│     Flutter Mobile      │
│        (Client)          │
└────────────┬────────────┘
             │
             │ HTTP / REST API
             ▼
┌─────────────────────────┐
│   Node.js + Express.js  │
│        (Backend)         │
└────────────┬────────────┘
             │
             │ SQL
             ▼
┌─────────────────────────┐
│         MySQL           │
│      db_blog_app        │
└─────────────────────────┘

📱 Application Flow

User
  ↓
Flutter App
  ↓
REST API
  ↓
Backend
  ↓
MySQL Database
  ↓
Backend
  ↓
JSON Response
  ↓
Flutter App
  ↓
User

📂 Project Structure

lib/
├── main.dart
│
├── models/
│   └── post.dart
│
├── pages/
│   ├── main_shell.dart
│   ├── home_page.dart
│   ├── articles_page.dart
│   ├── category_page.dart
│   ├── category_articles_page.dart
│   ├── add_post_page.dart
│   ├── detail_post_page.dart
│   ├── edit_post_page.dart
│   ├── about_page.dart
│   ├── settings_page.dart
│   └── profile_page.dart
│
├── services/
│   └── api_service.dart
│
└── widgets/
    ├── app_theme.dart
    └── app_ui.dart

⚙️ Installation
1. Clone Repository
git clone https://github.com/FaletehanAlF/blog-app-ujilevel.git
Masuk ke folder project:
cd blog-app-ujilevel
2. Install Dependencies
flutter pub get
3. Environment Configuration
Buat file:
assets/.env
Isi dengan URL backend:
API_URL=http://YOUR_IP_ADDRESS:8000
Sesuaikan IP address dengan alamat IP komputer yang menjalankan backend.
4. Jalankan Backend

Pastikan backend NARATA sudah berjalan pada port:

8000
5. Jalankan Flutter

Hubungkan perangkat Android atau gunakan emulator, kemudian jalankan:

flutter run
🔐 Environment Variables

File .env tidak disimpan di repository karena dapat berisi konfigurasi environment.

Gunakan:

assets/.env.example

sebagai contoh konfigurasi.

Contoh:

API_URL=http://YOUR_IP_ADDRESS:8000
🌿 Git Branching

Pengembangan aplikasi menggunakan Git untuk version control.

Branch utama:

main

Branch pengembangan Flutter:

feature/flutter

Alur pengembangan:

main
  ↓
feature/flutter
  ↓
Development
  ↓
Pull Request
  ↓
main
🎓 Project Information

Project: NARATA - Aplikasi Blog
Category: Uji Level Kompetensi Keahlian RPL
School: SMK Taruna Bhakti
Major: Rekayasa Perangkat Lunak
Academic Year: 2026/2027

👨‍💻 Developer

Faletehan Al Farabi

GitHub: @FaletehanAlF
Instagram: @faalen_portofolio

Made for Uji Level Kompetensi Keahlian RPL 2026/2027.


### Catatan kecil

README ini sengaja **tidak memasukkan fitur login, search, payment, komentar, atau fitur lain yang tidak ada di NARATA**, supaya isi GitHub tetap konsisten dengan aplikasi dan SRS kamu.

Kalau mau dibuat lebih profesional untuk recruiter, bagian **screenshot aplikasi + demo 
