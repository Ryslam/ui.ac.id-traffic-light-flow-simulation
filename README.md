# Simulasi Aliran Lalu Lintas di Lampu Merah

Proyek ini menyajikan simulasi interaktif untuk menganalisis aliran mobil yang mengantri di lampu merah.

## Konteks

Seringkali, antrian mobil di persimpangan begitu panjang sehingga pengemudi yang berada jauh di belakang melihat lampu lalu lintas berubah kembali menjadi merah bahkan sebelum mereka sempat bergerak maju. Fenomena ini kompleks dan bergantung pada banyak faktor. Proyek ini berfokus pada kasus jenuh (saturation case), di mana sudah ada antrian panjang mobil yang siap bergerak saat lampu berubah menjadi hijau.

## Pernyataan Masalah

**Berapa banyak mobil yang dapat melewati satu set lampu lalu lintas saat lampu tersebut berubah menjadi hijau selama periode 15 detik?**

## Formulasi Model

Untuk menjawab pertanyaan di atas, sebuah model simulasi dibangun berdasarkan serangkaian asumsi dan parameter.

#### Asumsi
- Persimpangan tidak terhalang.
- Semua mobil diasumsikan bergerak lurus melewati persimpangan.
- Semua kendaraan adalah mobil dengan ukuran yang sama: panjang **5 meter**.
- Terdapat jarak **2 meter** antara setiap mobil saat dalam keadaan diam.
- Semua mobil pada awalnya diam (`t=0`).
- Posisi setiap mobil diukur dari **bumper belakangnya**.

#### Parameter dan Variabel
- **Waktu Reaksi Pengemudi (`reaction_time`)**: Waktu yang dibutuhkan pengemudi untuk mulai bergerak setelah mobil di depannya bergerak. Parameter ini dapat diatur oleh pengguna.
- **Percepatan Mobil (`acceleration`)**: Nilai percepatan konstan yang sama untuk semua mobil setelah mulai bergerak. Parameter ini dapat diatur oleh pengguna.
- **Durasi Lampu Hijau**: Ditetapkan selama **15 detik**.
- **Posisi Awal**: Mobil pertama diposisikan sehingga bumper depannya berada tepat di garis lampu lalu lintas (`y=0`). Dengan panjang mobil 5m, posisi bumper belakangnya adalah `y=-5`.

#### Logika Model
1.  Simulasi berjalan dalam langkah waktu diskrit (`DT`).
2.  Pada `t=0`, lampu berubah hijau dan pengemudi pertama mulai bereaksi.
3.  Setelah `reaction_time` berlalu, mobil pertama mulai bergerak dengan percepatan konstan.
4.  Mobil di belakangnya (mobil `i`) baru akan mulai bereaksi ketika mobil di depannya (mobil `i-1`) mulai bergerak.
5.  Proses ini menciptakan reaksi berantai ke belakang antrian.
6.  Sebuah mobil dianggap telah "melewati" persimpangan jika posisi bumper belakangnya telah melewati garis lampu lalu lintas (`position > 0`).

## Solusi

Solusi diimplementasikan dalam bentuk **aplikasi web interaktif** yang dibangun menggunakan R Shiny.

-   **Interaktivitas**: Pengguna dapat secara dinamis mengubah parameter `Waktu Reaksi Pengemudi` dan `Percepatan Mobil` menggunakan slider.
-   **Visualisasi**: Aplikasi menampilkan plot posisi setiap mobil terhadap waktu, memberikan gambaran visual yang jelas tentang bagaimana gelombang gerakan menyebar melalui antrian.
-   **Kontrol Simulasi**: Tombol disediakan untuk menjalankan simulasi langkah-demi-langkah, langsung ke akhir, atau mengatur ulang ke kondisi awal.
-   **Output**: Sebuah *value box* secara eksplisit menampilkan jumlah total mobil yang telah berhasil melewati persimpangan.

Untuk menjalankan aplikasi:
1.  Buka file `app.R` di RStudio.
2.  Klik tombol "Run App".

## Analisis untuk Menjawab Pernyataan Masalah

Untuk menjawab pertanyaan "Berapa banyak mobil yang bisa lewat dalam 15 detik?", pengguna dapat mengikuti langkah-langkah berikut menggunakan aplikasi:

1.  Atur nilai `Waktu Reaksi Pengemudi` dan `Percepatan Mobil` pada slider sesuai dengan skenario yang ingin dianalisis (misalnya, gunakan nilai default: reaksi 1.5 detik dan percepatan 2.5 m/s²).
2.  Tekan tombol **"Finish"** untuk menjalankan simulasi secara penuh selama 15 detik.
3.  Amati angka yang ditampilkan di kotak **"Total Car Passed"**.

Angka inilah jawaban dari pernyataan masalah untuk parameter yang diberikan. Dengan mengubah parameter, pengguna dapat menganalisis bagaimana waktu reaksi dan kemampuan akselerasi mobil memengaruhi throughput (jumlah mobil yang lewat) di sebuah persimpangan.
