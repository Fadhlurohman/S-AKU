# SakuFlow - Personal Finance Tracker PWA

**SakuFlow** adalah aplikasi pencatat keuangan pribadi modern yang berbasis *Progressive Web App* (PWA). Aplikasi ini dirancang agar dapat digunakan secara offline (*offline-first*), cepat, responsif di layar handphone maupun desktop, serta memiliki tampilan visual premium berbasis *glassmorphism* dengan mode terang (*light mode*) dan mode gelap (*dark mode*).

---

## 🌟 Fitur Utama

1. **Dashboard Finansial Lengkap**:
   - **Kartu Ringkasan**: Menampilkan total saldo, total pemasukan, dan total pengeluaran secara akumulatif.
   - **Batas Anggaran Bulanan**: Atur batas anggaran bulanan Anda. Bilah kemajuan (*progress bar*) akan terisi secara otomatis berdasarkan pengeluaran bulan berjalan dan berubah warna menjadi merah jika anggaran melebihi batas.
   - **Visualisasi Grafik**:
     - *Donut Chart*: Menampilkan distribusi pengeluaran berdasarkan kategori.
     - *Bar Chart*: Tren perbandingan pemasukan vs pengeluaran selama 6 bulan terakhir.

2. **Pencatatan Transaksi Simpel (Bebas Ribet)**:
   - Form pencatatan transaksi pemasukan dan pengeluaran yang cepat.
   - Menggunakan kategori umum yang rapi (Pemasukan: *Gaji, Investasi, Kado, Lain-lain*; Pengeluaran: *Makanan & Minuman, Transportasi, Hiburan, Tagihan, Belanja, Kesehatan, Lain-lain*). Transaksi dengan kategori di luar daftar akan dikelompokkan ke **Lain-lain**.

3. **Riwayat & Filter Canggih**:
   - **Pencarian Real-Time**: Cari riwayat transaksi berdasarkan catatan atau kategori secara langsung saat Anda mengetik.
   - **Filter Tanggal & Bulan**: Saring daftar transaksi berdasarkan rentang tanggal tertentu atau bulan tertentu dengan cepat.
   - **Aksi Hapus**: Hapus riwayat transaksi dengan satu klik tombol hapus.

4. **Cadangan Data Mandiri (Ekspor & Impor)**:
   - **Unduh Backup (JSON)**: Simpan seluruh data transaksi dan batas anggaran Anda ke berkas JSON lokal untuk dicadangkan.
   - **Ekspor Excel (CSV)**: Ekspor data transaksi ke format CSV yang siap dibuka langsung di Microsoft Excel atau Google Sheets.
   - **Unggah Backup (JSON)**: Impor berkas cadangan JSON Anda untuk memulihkan seluruh data transaksi secara instan.

5. **Instalasi PWA & Offline Support**:
   - Berfungsi penuh tanpa koneksi internet (*offline-first*) menggunakan *Service Worker* untuk menyimpan aset web.
   - Dapat diinstal langsung ke layar utama (*home screen*) HP atau desktop Anda dengan tombol **Instal Aplikasi**.

---

## 🛠️ Teknologi yang Digunakan

- **Struktur & Tata Letak**: HTML5 (Elemen semantik SEO, meta viewport mobile).
- **Desain & Gaya (Styling)**: Vanilla CSS3 (Custom Variables, Flexbox, CSS Grid, Glassmorphic effects, animasi mikro, Google Fonts Inter).
- **Logika Aplikasi**: Vanilla Javascript (Event listeners, LocalStorage untuk persistensi data, Service Worker untuk PWA caching).
- **Pustaka Visualisasi**: [Chart.js](https://www.chartjs.org/) (dimuat secara asinkron via CDN).

---

## 🚀 Cara Menjalankan Aplikasi Secara Lokal

Aplikasi ini dirancang sebagai aplikasi web murni yang tidak membutuhkan kompilasi atau backend berat. Cukup jalankan menggunakan server HTTP lokal:

### Cara 1: Menggunakan Python (Direkomendasikan)
1. Buka terminal atau Command Prompt (CMD) di dalam direktori folder projek (`SakuFlow`).
2. Jalankan perintah berikut:
   ```bash
   python -m http.server 8000
   ```
3. Buka browser Anda dan akses alamat:
   👉 **`http://localhost:8000/`**

### Cara 2: Menggunakan VS Code Extension (Live Server)
1. Buka folder projek di VS Code.
2. Klik kanan pada file `index.html` dan pilih **Open with Live Server**.
3. Aplikasi akan otomatis terbuka di browser Anda (biasanya di alamat `http://127.0.0.1:5500/`).

### Cara 3: Menjalankan Langsung (Double-Click)
- Anda dapat langsung mengeklik dua kali file `index.html` untuk membukanya di browser. Namun, **fitur PWA (Service Worker dan instalasi) tidak akan berfungsi** karena PWA mewajibkan protokol `http://` atau `https://` (localhost diperbolehkan).

---

## 📲 Panduan Instalasi (PWA)

### Di Laptop / Desktop (Google Chrome / Microsoft Edge)
1. Jalankan aplikasi menggunakan Server HTTP Lokal (Alamat `localhost`).
2. Klik tombol **Instal Aplikasi** yang muncul di bagian kanan atas *header* aplikasi.
3. Klik **Install** pada pop-up konfirmasi browser.
4. Aplikasi akan terbuka di jendela khusus tanpa bilah alamat browser, mirip seperti aplikasi asli komputer.

### Di Handphone (Android - Google Chrome)
1. Buka aplikasi browser Chrome di HP Anda dan ketikkan alamat server lokal (misalnya `http://192.168.x.x:8000/` atau alamat staging online jika di-deploy).
2. Klik tombol **Instal Aplikasi** di bagian atas, atau buka menu titik tiga Chrome dan pilih **Tambahkan ke Layar Utama** (*Add to Home Screen*).
3. Aplikasi SakuFlow akan muncul sebagai ikon aplikasi di menu HP Anda dan dapat diakses secara offline.

### Di Handphone (iOS - Safari)
1. Buka Safari dan buka alamat aplikasi.
2. Klik tombol **Share** (ikon persegi dengan panah ke atas) di bagian bawah Safari.
3. Gulir ke bawah dan pilih **Add to Home Screen** (*Tambahkan ke Layar Utama*).

---

## 🧹 Cara Memaksa Pembaruan Aset (Bypass Cache)
Karena aplikasi menggunakan *Service Worker* untuk menyimpan aset secara offline, jika ada perubahan kode (HTML, CSS, JS), Anda harus memaksa pembersihan cache sekali dengan membuka alamat berikut di browser Anda:
👉 **`http://localhost:8000/?reset=1`**
Hal ini akan menghapus cache dan mendaftarkan ulang Service Worker dengan kode terbaru.
