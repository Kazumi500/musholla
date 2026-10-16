# Absensi Sholat: Arah Desain Aplikasi Android

Aplikasi pemindai untuk petugas OSIS di pintu musholla. Klien dari server absensi yang sudah jalan (`/s/{token}`), dipakai berdiri, satu tangan, menghadapi antrean yang harus cepat.

Dibaca sebagai: alat kerja harian untuk petugas OSIS remaja, dalam bahasa visual hangat yang berwibawa (hijau tua + emas), dial **ENERGY 2 / RHYTHM 1 / MOTION 2**.

## Identitas & Karakter

- Hangat dan ramah, tapi tetap cekatan dan menarik. Bukan kaku, bukan juga meriah.
- Identitas baru, tidak mengikuti tampilan web admin. Web tetap teal modern; aplikasi ini dunia visualnya sendiri.
- Rasa campuran: fase memindai adalah alat kerja (cepat, senyap, kata pendek); momen jeda dan keadaan tidak biasa dibuat ramah dan menenangkan.

## Referensi Pola

Layar utama mengikuti pola aplikasi e-wallet (arahan pemilik): nama petugas tampil di atas (diisi sekali, tersimpan lokal), dan pintu masuk pemindaian berupa **ikon QR scan di dalam bilah navigasi bawah**, bukan tombol besar terpisah.

- Ini inspirasi pola interaksi, bukan meniru visual aplikasi tertentu.
- Nama yang tampil adalah nama yang sama dengan "name-gate" di web: tersimpan per hari.

## Warna

Hijau tua berwibawa + aksen emas (pilihan pemilik).

| Peran | Warna | Alasan |
| --- | --- | --- |
| Primary, hijau tua | `#0F4C3A` | identitas utama; tombol besar dan kepala layar; kontras aman dengan teks putih |
| Secondary, hijau segar | `#1E7A5A` | pendukung, keadaan positif |
| Aksen emas | `#C6A15B` (aksen besar), `#755720` (teks emas di latar terang), `#E0C288` (teks di atas hijau kepala) | aksen pilihan pemilik; tiga tingkat supaya tetap aman dibaca |
| Latar | `#FAF7F0` kertas hangat, kartu `#FFFFFF` | kehangatan datang dari latar dan tinta, bukan dari banyak warna |
| Teks | `#222B26` utama, `#4A574F` lemah | tinta hangat, bukan hitam pekat |
| Kepala hijau | teks utama putih, teks pendukung `#CFE0D8`, aksen titik `#E0C288` | kepala layar pakai primary; tiap teks dihitung kontrasnya |

Garis: `#DCD6C5` halus (pemisah), `#B3BFB7` tegas (bingkai, garis kolom isian).

Status operasional (fungsional, terpisah dari identitas):

| Status | Latar | Garis | Teks |
| --- | --- | --- | --- |
| Hadir | `#E8F5EF` | `#1E7A5A` | `#0B4A36` |
| Duplikat | `#EAF2FB` | `#2E6FB7` | `#1D4E89` |
| Tidak terdaftar | `#FCEDEE` | `#C0392B` | `#8E2318` |
| Non-Muslim | `#F1EEFB` | `#6D5BD0` | `#463A8E` |
| Antrean offline | `#FBF3E4` | `#B7791F` | `#7A5310` |
| Sesi ditutup | `#F1F3F2` | `#C7CFCA` | `#45514A` |

## Tipografi

- **Judul dan momen besar: Manrope.** Alasan: geometris-humanis, terasa hangat tapi tegas; cocok untuk nama siswa dan angka besar.
- **Isi dan data: Inter dengan `tabular-nums`.** Alasan: paling terbaca di ukuran kecil; angka NISN dan waktu tidak goyang lebarnya.
- **Ikon: Material Symbols (Rounded, weight sedang).** Alasan: menyatu dengan Android dan Flutter, familiar untuk anak OSIS, tanpa aset tambahan.
- **Skala huruf: enam langkah saja.** 12 (keterangan, chip, label navbar, jam), 14 (isi kecil dan baris keterangan), 16 (isi, judul baris, tombol, kolom isian, judul lembar), 20 (judul bagian dan kepala), 26 (judul layar dan nama), 40 (angka besar). Tidak ada ukuran setengah piksel.
- **Berat huruf.** w800 hanya untuk nama dan angka besar; judul w700; label, chip, dan tombol w600; isi w400 atau w500.
- **Sudut: empat nilai saja.** 12 (kontrol kecil dan badge), 16 (tombol dan kolom isian), 24 (kartu, lembar, dialog, bingkai kamera), 999 (kapsul dan chip).

## Nada Bicara (contoh kanon)

Rasa hangat diwujudkan lewat kata. Contoh nada berikut patokan rasa, bukan kalimat final:

- Pembuka: "Assalamualaikum, [nama petugas]"
- Belum ada pindaian: "Arahkan kamera ke kartu siswa. Tidak perlu terlalu dekat."
- Offline: "Jaringan lepas sebentar. Semua simpanan aman, terkirim otomatis."
- NISN tak dikenal: "NISN ini belum terdaftar. Periksa kartunya, atau ketik manual, ya."
- Penutup: "Selesai! [n] siswa tercatat hari ini. Terima kasih, [nama]."

Larangan nada: kalimat menghakimi ("SALAH"), huruf kapital semua untuk kesalahan, dan istilah teknis mentah di layar petugas.

## Dial dan Gerak

**ENERGY 2 / RHYTHM 1 / MOTION 2.**

- ENERGY 2: ramah dan menarik, tapi tidak pernah berisik.
- RHYTHM 1: tata letak konsisten dan mudah diprediksi; ini alat harian.
- MOTION 2: gerak mikro yang punya makna (kartu hasil, denyut antrean); tidak ada gerakan di jalur cepat yang menambah waktu.

## Keputusan yang Sengaja Ditunda

- **Ikon aplikasi:** dibuat setelah arah ini disetujui, dengan konfirmasi bentuk dan warna lebih dulu.
- **Mode gelap:** belum masuk v1; ditinjau sebelum rilis apakah perlu.
- **Layar guru dan siswa:** belum ada di v1; dokumen ini diperluas saat gilirannya tiba.
