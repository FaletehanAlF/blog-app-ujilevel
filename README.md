# NARATA — Aplikasi Blog

NARATA merupakan aplikasi mobile untuk mengelola dan menampilkan artikel secara terstruktur. Aplikasi ini dikembangkan sebagai bagian dari **Uji Level Kompetensi Keahlian Rekayasa Perangkat Lunak (RPL)**.

NARATA memungkinkan pengguna untuk melihat, menambahkan, mengedit, dan menghapus artikel serta mengelola kategori artikel.

## Features

- Menampilkan daftar artikel
- Melihat detail artikel
- Menambahkan, mengedit, dan menghapus artikel
- Mengelola kategori artikel
- Menampilkan artikel berdasarkan kategori
- Upload gambar artikel
- Validasi data
- Integrasi REST API

## Tech Stack

- **Flutter & Dart** — Mobile App
- **Node.js & Express.js** — Backend REST API
- **MySQL** — Database
- **Dio** — HTTP Client
- **Multer** — Image Upload
- **Zod** — Data Validation
- **Git & GitHub** — Version Control

## Architecture

```text
Flutter Mobile
      ↓
 REST API
      ↓
Node.js + Express.js
      ↓
    MySQL

Aplikasi mobile berkomunikasi dengan backend melalui REST API untuk mengambil dan mengelola data.

Installation

Clone repository:

git clone https://github.com/FaletehanAlF/blog-app-ujilevel.git
cd blog-app-ujilevel

Install dependencies:

flutter pub get

Buat file assets/.env:

API_URL=http://YOUR_IP_ADDRESS:8000

Kemudian jalankan aplikasi:

flutter run

Pastikan backend REST API sudah berjalan pada port 8000.

Project Information

Project: NARATA — Aplikasi Blog
Category: Uji Level Kompetensi Keahlian RPL
School: SMK Taruna Bhakti
Major: Rekayasa Perangkat Lunak
Academic Year: 2026/2027

Developer

Faletehan Al Farabi

GitHub: @FaletehanAlF
Instagram: @faalen_portofolio

Made for Uji Level Kompetensi Keahlian RPL 2026/2027.
