# NARATA — Aplikasi Blog

**NARATA** merupakan aplikasi mobile untuk mengelola dan menampilkan artikel secara terstruktur. Aplikasi ini dikembangkan sebagai bagian dari **Uji Level Kompetensi Keahlian Rekayasa Perangkat Lunak (RPL)**.

NARATA menggunakan **Flutter** sebagai client, **Node.js + Express.js** sebagai backend REST API, dan **MySQL** sebagai database.

---

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
- Integrasi REST API
- Response API dalam format JSON

---

## 🛠️ Tech Stack

### Mobile App

- **Flutter**
- **Dart**
- **Dio**
- **Image Picker**
- **Flutter Dotenv**
- **Cached Network Image**

### Backend

- **Node.js**
- **Express.js**
- **TypeScript**
- **REST API**
- **Zod**
- **Multer**

### Database

- **MySQL**

### Development Tools

- **Visual Studio Code**
- **Postman / Thunder Client**
- **Git**
- **GitHub**

---

## 🏗️ System Architecture

NARATA menggunakan arsitektur **client-server**, dengan aplikasi Flutter sebagai client yang berkomunikasi dengan backend melalui REST API.

```text
┌─────────────────────────┐
│     Flutter Mobile      │
│        Client           │
└────────────┬────────────┘
             │
             │ HTTP / REST API
             ▼
┌─────────────────────────┐
│   Node.js + Express.js  │
│        Backend          │
└────────────┬────────────┘
             │
             │ SQL
             ▼
┌─────────────────────────┐
│         MySQL           │
│      db_blog_app        │
└─────────────────────────┘
