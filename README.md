# Simulasi Aliran Mobil di Lampu Lalu Lintas

![Dashboard Preview](https://raw.githubusercontent.com/Ryslam/ui.ac.id-traffic-light-flow-simulation/main/assets/dashboard-screenshot.png)

**Dashboardnya bisa diakses di link berikut:**
➡️ [https://ardian.shinyapps.io/ui-ac-id-traffic-light-flow-simulation/](https://ardian.shinyapps.io/ui-ac-id-traffic-light-flow-simulation)

## ℹ️ Konteks

Manajemen arus lalu lintas di persimpangan perkotaan merupakan tantangan krusial dalam rekayasa transportasi. Salah satu masalah yang paling umum adalah **inefisiensi siklus lampu hijau**, di mana pengemudi dalam antrean panjang gagal melewati persimpangan sebelum lampu kembali merah. Fenomena ini, yang dikenal sebagai *kegagalan siklus (cycle failure)*, tidak hanya menyebabkan penundaan tetapi juga frustrasi bagi pengemudi.

Penyebabnya kompleks, namun seringkali berakar pada **waktu reaksi berantai** antar pengemudi dan **kapabilitas akselerasi** setiap kendaraan. Proyek ini berfokus untuk menganalisis skenario kasus jenuh (*saturation case*), yaitu kondisi di mana antrean kendaraan sudah terbentuk dan siap bergerak saat lampu lalu lintas berubah menjadi hijau.

Sistem yang disimulasikan adalah satu lajur tunggal yang mendekati persimpangan, dengan tujuan untuk menganalisis *throughput* (jumlah kendaraan yang melintas) dengan memodelkan bagaimana gelombang pergerakan merambat ke belakang melalui antrean.

Manajemen arus lalu lintas di persimpangan perkotaan merupakan tantangan krusial dalam rekayasa transportasi. Salah satu masalah yang paling umum adalah **inefisiensi siklus lampu hijau**, di mana pengemudi dalam antrean panjang gagal melewati persimpangan sebelum lampu kembali merah. Fenomena ini, yang dikenal sebagai *kegagalan siklus (cycle failure)*, tidak hanya menyebabkan penundaan tetapi juga frustrasi bagi pengemudi.

Penyebabnya kompleks, namun seringkali berakar pada **waktu reaksi berantai** antar pengemudi dan **kapabilitas akselerasi** setiap kendaraan. Proyek ini berfokus untuk menganalisis skenario kasus jenuh (*saturation case*), yaitu kondisi di mana antrean kendaraan sudah terbentuk dan siap bergerak saat lampu lalu lintas berubah menjadi hijau.

Sistem yang disimulasikan adalah satu lajur tunggal yang mendekati persimpangan, dengan tujuan untuk menganalisis *throughput* (jumlah kendaraan yang melintas) dengan memodelkan bagaimana gelombang pergerakan merambat ke belakang melalui antrean.

## 🎯 Pernyataan Masalah

Permasalahan utama yang ingin dipecahkan adalah kuantifikasi *throughput* persimpangan berdasarkan parameter fisika dan perilaku pengemudi. Secara spesifik, simulasi ini dirancang untuk menjawab pertanyaan-pertanyaan berikut:

1.  **Berapa banyak mobil yang dapat melewati satu set lampu lalu lintas saat lampu tersebut berubah menjadi hijau selama periode 15 detik?**
2.  Bagaimana **waktu reaksi** pengemudi (`reaction_time`) secara kuantitatif mempengaruhi jumlah total mobil yang berhasil melintas?
3.  Bagaimana **percepatan** mobil (`acceleration`) mempengaruhi kecepatan perambatan gelombang gerak dan pada akhirnya, *throughput* persimpangan?
4.  Bagaimana model fisika dari **Gerak Lurus Berubah Beraturan (GLBB)** dan **Gerak Lurus Beraturan (GLB)** dapat diterapkan untuk memprediksi posisi dan kecepatan setiap mobil dalam antrean secara akurat dari waktu ke waktu?

## ⚙️ Formulasi Model

Model simulasi ini dikembangkan sebagai **model simulasi berbasis waktu diskrit** (`discrete-time simulation`), di mana keadaan setiap mobil dievaluasi pada interval waktu tetap **`DT = 1` detik**, sesuai implementasi pada `app.R`.

*   **Entitas (Entities)**
    *   Objek utama adalah **Mobil**. Setiap mobil memiliki serangkaian atribut yang menentukan keadaannya: `id`, `position` (posisi bumper belakang), `velocity`, dan `status` ("diam", "reaksi", atau "bergerak").

*   **Parameter Input Model (Dapat Diatur Pengguna)**
    *   `reaction_time`: Waktu yang dibutuhkan pengemudi untuk bereaksi (default: **2 s**).
    *   `acceleration`: Nilai percepatan konstan mobil (default: **1.0 m/s²**). Nilai ini diambil dari asumsi kasar performa mobil keluarga yang mencapai 60 km/jam dalam 20 detik.
    *   `speed_limit`: Kecepatan maksimum yang bisa dicapai (default: **11 m/s**). Nilai ini merupakan konversi dari batas kecepatan umum di area urban, yaitu **40 km/jam**.
    *   `intersection_width`: Lebar persimpangan yang harus dilewati (default: **12 m**).

*   **Logika dan Model Fisika Gerakan**
    Gerakan dalam antrean dimodelkan sebagai **reaksi berantai (chain reaction)** yang logikanya diatur sebagai berikut:

    1.  **Fase Diam (`resting`)**: Mobil menunggu dengan `v = 0`.
    2.  **Pemicu Reaksi**: Fase 'Reaksi' untuk mobil `i` dimulai **tepat saat mobil di depannya (`i-1`) memasuki Fase Bergerak (`status == "moving"`)**. Ini adalah pemicu gelombang gerak.
    3.  **Fase Reaksi (`reacting`)**: Setelah terpicu, pengemudi mobil `i` menunggu selama `reaction_time` sebelum bergerak. Posisi dan kecepatan tetap nol.
    4.  **Fase Bergerak (`moving`)**: Fase ini menerapkan model fisika gerak lurus:
        *   **a. Sub-Fase Akselerasi (GLBB)**: Mobil berakselerasi dengan percepatan `a` hingga mencapai `speed_limit`.
            *   Kecepatan: `v(Δt) = a * Δt`
            *   Posisi: `p(Δt) = p₀ + (0.5 * a * Δt²)`
        *   **b. Sub-Fase Kecepatan Konstan (GLB)**: Setelah `v` mencapai `speed_limit`, mobil bergerak dengan kecepatan konstan.
            *   Posisi: `p(Δt) = p_akhir_glbb + speed_limit * (Δt - t_akhir_glbb)`
    
*   **Kriteria Lolos (Passed Criteria)**
    *   Sebuah mobil dianggap telah berhasil melewati persimpangan jika posisi bumper belakangnya telah melampaui atau sama dengan lebar persimpangan: `position >= intersection_width`.


## 💡 Solusi

Solusi diimplementasikan dalam bentuk **aplikasi web interaktif** yang dibangun menggunakan R dengan framework Shiny. Pendekatan ini dipilih untuk memungkinkan eksplorasi dinamis terhadap parameter model.

*   **Visualisasi Interaktif**: Aplikasi menampilkan plot posisi setiap mobil terhadap waktu. Garis pada plot diberi warna sesuai status mobil (diam, reaksi, bergerak), memberikan gambaran visual yang jelas tentang bagaimana gelombang gerakan menyebar melalui antrean dan bagaimana fase gerak (GLBB/GLB) terjadi.
*   **Kontrol Parameter Dinamis**: Pengguna dapat secara langsung mengubah parameter fisika (`acceleration`, `speed_limit`) dan faktor manusia (`reaction_time`) menggunakan slider. Setiap perubahan akan langsung me-reset simulasi, memungkinkan analisis "what-if" secara instan.
*   **Kontrol Simulasi**: Tombol disediakan untuk menjalankan simulasi langkah-demi-langkah (`Next`), langsung ke akhir (`Finish`), atau mengatur ulang (`Reset`), memberikan kontrol penuh kepada pengguna untuk menganalisis kejadian pada waktu tertentu.
*   **Output Kinerja**: Sebuah *value box* di bagian atas secara eksplisit menampilkan metrik kinerja utama: **Jumlah Total Mobil yang Telah Melewati Persimpangan** pada waktu saat itu.

## 📊 Analisis untuk Menjawab Pernyataan Masalah

Analisis dilakukan dengan menjalankan simulasi pada **parameter default** yang ditetapkan dalam `app.R`:
*   **Waktu Reaksi Pengemudi**: 2 detik
*   **Percepatan Mobil**: 1.0 m/s²
*   **Batas Kecepatan**: 11 m/s (~40 km/jam)
*   **Lebar Persimpangan**: 12 meter

**Hasil Utama: Hanya 3 Mobil yang Melintas**

Dengan parameter default, hasil simulasi menunjukkan bahwa hanya **3 mobil** yang berhasil melewati persimpangan (mencapai `posisi >= 12 meter`) dalam durasi lampu hijau 15 detik.

**Analisis Penyebab Kegagalan Siklus (Cycle Failure)**

Penyebab utama rendahnya *throughput* ini adalah **efek domino dari waktu reaksi pengemudi** yang bersifat kumulatif. Berikut adalah rinciannya:

1.  **Mobil Pertama**: Mulai bergerak pada `t = 2s`. Ia berhasil melewati persimpangan pada `t ≈ 7.8s`.
2.  **Mobil Kedua**: Baru bisa mulai bergerak pada `t = 4s`. Ia berhasil lewat pada `t ≈ 10.9s`.
3.  **Mobil Ketiga**: Baru bisa mulai bergerak pada `t = 6s`. Ia berhasil lewat pada `t ≈ 13.9s`.
4.  **Mobil Keempat**: Baru bisa mulai bergerak pada `t = 8s`. Pada saat simulasi berakhir (`t = 15s`), mobil ini belum berhasil melewati garis finis 12 meter.

**Insight Kunci:**

*   **Penundaan Bersifat Kumulatif**: Total waktu yang hilang sebelum sebuah mobil dapat bergerak adalah `jumlah mobil di depan * waktu reaksi`. Untuk mobil ke-4, ia sudah kehilangan `3 * 2s = 6s` hanya untuk menunggu giliran bereaksi.
*   **Faktor Manusia > Faktor Mesin**: Dalam skenario ini, **waktu reaksi pengemudi (faktor manusia) menjadi pembatas yang lebih dominan daripada percepatan mobil (faktor mesin)**. Gelombang pergerakan merambat terlalu lambat ke belakang antrean.

**Implikasi dan Rekomendasi**

Hasil simulasi ini secara kuantitatif menunjukkan bahwa durasi lampu hijau **15 detik tidak cukup** untuk melayani antrean yang sudah jenuh secara efektif. Lebih dari separuh durasi lampu hijau (`~8 detik`) habis hanya untuk mengatasi jeda reaksi dari empat mobil pertama.

Oleh karena itu, untuk meningkatkan *throughput* secara signifikan pada persimpangan dengan karakteristik serupa, **meningkatkan durasi lampu hijau** adalah rekomendasi yang paling logis. Berdasarkan data simulasi, menaikkan durasi menjadi **20 atau 25 detik** akan memberikan waktu yang cukup bagi setidaknya mobil ke-4 dan ke-5 untuk melewati persimpangan, sehingga dapat mengurangi panjang antrean secara lebih berarti setiap siklusnya dan mencegah penumpukan antrean yang semakin parah.

## 🚀 (Opsional) Jalankan Aplikasi Secara Lokal

### Prasyarat
- Sudah menginstal **R**
- Sudah menginstal **RStudio Desktop**

### 1. Clone Repository
```bash
git clone https://github.com/Ryslam/ui.ac.id-traffic-light-flow-simulation.git
cd ui.ac.id-traffic-light-flow-simulation
```

### 2. Instalasi Packages
Buka **RStudio**, lalu jalankan perintah berikut di **console** untuk menginstal package yang dibutuhkan:
```r
install.packages(c("shiny", "shinydashboard", "ggplot2", "dplyr"))
```

### 3. Clone Repository
```bash
shiny::runApp('app.R')
```
atau ctrl/command + shift + enter/return.

---
Jazakallah khairan, Ardian.
