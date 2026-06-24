<p align="center">
  <img src="assets/images/logo.png" alt="DompetGweh Logo" width="150" />
</p>

<h1 align="center">DompetGweh</h1>

<p align="center">
  <i>"Catat masuknya dikit, keluarnya banyak."</i>
</p>

**DompetGweh** adalah aplikasi pencatatan keuangan pribadi modern berbasis **Flutter** yang didesain khusus untuk pengguna **Android** dan **iOS**, dengan dukungan platform **Web** & **Windows** untuk pengujian dan pengembangan secara lokal.

DompetGweh membantu Anda melacak keuangan harian secara mandiri, aman (offline-first), dan dengan antarmuka yang sangat nyaman di mata.

---

## ✨ Fitur Unggulan

* **💰 Set Saldo Awal Sesuka Anda**
  Mulailah pencatatan dari nol (`Rp 0`) atau sesuaikan saldo awal Anda kapan saja langsung dari dashboard utama sesuai dengan kondisi riil dompet Anda.

* **👁️ Mode Samaran (Hide/Show Nominal)**
  Privasi Anda terjaga sepenuhnya. Sembunyikan nominal Saldo Utama, Pemasukan, Pengeluaran, dan Anggaran Anda menjadi `Rp ••••••` hanya dengan satu ketukan ikon mata toggle.

* **🎯 Batasi Pengeluaran (Anti-Kebobolan)**
  Tetapkan anggaran belanja bulanan Anda. Aplikasi secara cerdas memberikan sinyal warna visual (**Hijau** / **Jingga** / **Merah**) sesuai persentase pemakaian agar Anda terhindar dari pengeluaran berlebih.

* **📊 Visualisasi Keuangan Interaktif**
  Dapatkan insight keuangan instan melalui diagram donat distribusi kategori pengeluaran dan grafik tren bulanan yang premium.

* **🖨️ Cetak & Bagikan Riwayat Instan**
  Dapatkan laporan bersih tanpa ribet. Cetak langsung dokumen fisik (Web) atau salin teks ringkasan rapi langsung ke clipboard (Mobile) dalam satu ketukan.

* **🎨 Tampilan Warm Mint Light**
  Nikmati kenyamanan visual dengan latar belakang putih-lembut (`#F5F8F6`) yang dipadukan dengan aksen warna mint yang segar dan teduh, tanpa membuat mata lelah.

---

## 🚀 Panduan Instalasi & Pengujian

### 📥 Unduh Langsung (Android)

Bagi Anda yang ingin langsung mencoba aplikasi di HP Android tanpa perlu melakukan build manual di laptop:
* **Link Download**: **[Unduh DompetGweh APK (via Diawi)](https://i.diawi.com/48WrnD)**
* *Buka tautan di atas melalui browser HP Anda atau pindai (scan) QR Code yang tersedia di halaman tersebut untuk menginstal aplikasi secara instan.*

---

### 📱 Penggunaan & Build Mandiri (Android & iOS)

* **Android (Build APK)**:
  Jalankan perintah berikut untuk membuat file instalasi APK siap pasang di HP Anda:
  ```bash
  flutter build apk --release
  ```
  File instalasi dapat diambil di:  
  `build/app/outputs/flutter-apk/app-release.apk`

* **iOS**:
  Jalankan perintah berikut untuk mempersiapkan build iOS:
  ```bash
  flutter build ipa
  ```

---

### 💻 Pengujian & Pengembangan Lokal (Web & Windows)

Untuk menjalankan dan mengedit aplikasi di laptop:

* **Web (Chrome)**:
  ```bash
  flutter run -d chrome
  ```

* **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```
