# NARATA — Aplikasi Blog

NARATA merupakan aplikasi mobile untuk mengelola dan menampilkan artikel secara terstruktur. Aplikasi ini dikembangkan sebagai bagian dari **Uji Level Kompetensi Keahlian Rekayasa Perangkat Lunak (RPL)**.

Pengguna dapat melihat, menambahkan, mengedit, dan menghapus artikel serta mengelola kategori artikel melalui aplikasi mobile.

## Features

- Menampilkan daftar dan detail artikel
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
