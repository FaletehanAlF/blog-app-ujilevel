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
