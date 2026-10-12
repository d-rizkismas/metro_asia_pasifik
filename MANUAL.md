# Manual Kairos — Manajemen Proyek Waterfall & Agile

**Bahasa:** Indonesia · **Aplikasi:** `index.html` · **Backend kolaborasi:** Supabase (opsional untuk demo lokal)  
**Status deployment:** kode sudah menyediakan frontend, integrasi Supabase, dan SQL awal. URL/key Supabase dan repository GitHub milik pengguna belum diberikan; database belum dijalankan dan situs belum dipublikasikan. Ikuti langkah setup sebelum mengandalkan data cloud.

---

## 1. Gambaran singkat

Kairos mengelola proyek dengan dua cara kerja yang sengaja dipisahkan:

- **Waterfall** — perencanaan berfase, baseline, WBS, dependensi, milestone, requirement, dokumen, dan persetujuan.
- **Agile** — product backlog, sprint, Scrum board, story point, kapasitas, stand-up, retrospective, dan rencana release.

Di luar dua modul tersebut ada dashboard portofolio, detail proyek, daftar risiko/isu, tim dan kapasitas, governance, laporan, dan ekspor.

### 1.1 Cara penyimpanan bekerja

```text
Browser pengguna
  ├─ index.html (HTML/CSS/JavaScript statis; bisa di-host di GitHub Pages)
  ├─ Mode lokal: localStorage browser/perangkat itu saja
  └─ Mode tim: Supabase Auth → PostgreSQL + Row Level Security (RLS)
```

GitHub Pages **hanya mengirim file frontend**; Pages bukan server database atau tempat menjalankan PHP/Node. Untuk akun dan data tim, Kairos berkomunikasi langsung dengan project Supabase menggunakan **Project URL** dan **anon/public key**. Aturan RLS di PostgreSQL—bukan key yang disembunyikan di HTML—yang membatasi data per workspace.

### 1.2 Mode lokal vs mode cloud

| Mode | Data terlihat oleh | Penggunaan yang sesuai |
|---|---|---|
| Lokal/demo | Browser dan profil browser yang sedang dipakai | Mencoba aplikasi, presentasi, atau penggunaan pribadi pada satu perangkat |
| Cloud/workspace | Anggota yang memiliki membership pada workspace Supabase yang sama | Kerja bersama lintas Project Manager/anggota tim dan lintas perangkat |

Mode lokal menyimpan data dengan `localStorage` key `kairos.pm.v1`. Menghapus data browser, memakai profil browser lain, atau pindah perangkat dapat membuat data lokal tidak terlihat. Data lokal **tidak otomatis dipindahkan** ketika menghubungkan Supabase.

---

## 2. Persiapan dan menjalankan aplikasi

### 2.1 Demo lokal

1. Buka `index.html` langsung di browser, atau lebih baik jalankan server statis dari folder proyek:

   ```bash
   python3 -m http.server 8000 --bind 0.0.0.0
   ```

2. Buka `http://localhost:8000`.
3. Tanpa konfigurasi Supabase, Kairos langsung menampilkan data demo.
4. Perubahan tersimpan otomatis di browser tersebut.
5. Untuk mengembalikan seed/demo lokal, pilih **Pengaturan → Pulihkan demo lokal** dan konfirmasi. Tombol ini hanya untuk mode lokal; tombol ini tidak menghapus isi workspace cloud.

### 2.2 Berkas proyek

- `index.html` — aplikasi frontend satu berkas, termasuk UI dan klien REST sederhana.
- `supabase/schema.sql` — tabel, fungsi pemeriksaan role, grants, dan kebijakan RLS untuk Supabase.
- `README.md` — ringkasan proyek dan quick start.
- `MANUAL.md` — dokumen ini.

Tidak dibutuhkan paket npm atau build step untuk situs statis.

---

## 3. Menyiapkan Supabase untuk kerja bersama

> Lakukan pengujian awal dengan project Supabase non-produksi terlebih dahulu. Jangan menaruh password database, `service_role`, atau secret key di source code.

### 3.1 Buat project

1. Buat project baru di Supabase untuk organisasi/PMO Anda.
2. Pilih region yang sesuai dengan kebijakan organisasi dan mayoritas pengguna.
3. Simpan password database di password manager. Password tersebut **bukan** anon/public key dan tidak boleh dimasukkan ke Kairos.
4. Tunggu sampai database dan API project siap.

### 3.2 Buat skema dan aktifkan keamanan

1. Buka **SQL Editor** di Supabase Dashboard.
2. Buka berkas `supabase/schema.sql` dari proyek ini.
3. Salin seluruh isinya ke SQL Editor, lalu jalankan sebagai project/database owner.
4. Pastikan eksekusi selesai tanpa error. Skrip membuat tiga tabel:
   - `public.workspaces` — nama workspace dan user pemilik.
   - `public.workspace_members` — hubungan workspace–user dan role cloud.
   - `public.workspace_state` — payload data aplikasi berformat JSONB serta nomor versi.
5. Skrip mengaktifkan RLS, membuat policy per workspace, dan memberikan hak tabel kepada role `authenticated`. Jangan menonaktifkan RLS untuk “memperbaiki” error akses.
6. Jalankan ulang SQL hanya bila memahami perubahan. Skrip menggunakan `create table if not exists` dan mengganti policy bernama sama; tetap tinjau backup dan dampaknya pada data yang sudah ada.

**Prinsip izin skema:** anggota workspace dapat membaca data workspace mereka; hanya owner, Project Manager, dan anggota tim yang dapat mengubah payload. Stakeholder hanya dapat membaca. Owner mengelola metadata workspace dan membership. Data aplikasi disimpan sebagai satu JSONB payload per workspace, sedangkan membership dan kontrol akses tetap menjadi tabel relasional.

### 3.3 Konfigurasikan Supabase Auth

1. Buka pengaturan **Authentication / Providers** dan aktifkan provider email/password.
2. Tentukan apakah konfirmasi email wajib. Untuk production, pertahankan konfirmasi email dan siapkan pengiriman email/SMTP sesuai kebijakan organisasi.
3. Pada pengaturan URL Auth, isi **Site URL** dengan URL situs yang akan dipakai pengguna. Untuk GitHub Pages biasanya berbentuk `https://NAMA-AKUN.github.io/NAMA-REPOSITORY/`.
4. Tambahkan URL tersebut ke daftar **Redirect URLs** yang diizinkan. Tambahkan URL development terpisah bila Anda menguji di `http://localhost:8000/`.
5. Jika email konfirmasi diarahkan ke alamat yang salah, periksa Site URL, Redirect URLs, dan template email Supabase.

Nama menu di dashboard Supabase dapat berubah. Pastikan URL publik yang dipakai pengguna benar-benar masuk daftar redirect yang diizinkan.

### 3.4 Ambil kredensial browser yang aman

1. Buka **Project Settings → API / API Keys**.
2. Salin **Project URL**.
3. Salin **anon/public key** (pada project/key versi baru dapat bernama publishable/public key).
4. Jangan memakai `service_role`, `sb_secret_...`, database password, atau access token admin. Key rahasia memberi akses istimewa dan tidak boleh ada dalam file frontend, GitHub, screenshot, atau pesan.

Anon/public key memang dapat terlihat di jaringan browser. Itu aman hanya jika RLS dan grants sudah benar; RLS wajib tetap aktif.

### 3.5 Sambungkan aplikasi

1. Buka Kairos lalu pilih **Pengaturan → Database & akses**.
2. Tempelkan Project URL dan anon/public key.
3. Tekan **Simpan konfigurasi & hubungkan**. Konfigurasi disimpan di `localStorage` browser itu, bukan ditulis kembali ke file `index.html`.
4. Buat akun email/password atau masuk menggunakan akun yang ada.
5. Jika alamat email perlu dikonfirmasi, konfirmasikan dahulu, lalu masuk kembali.
6. Akun yang belum menjadi anggota workspace akan melihat halaman pembuatan workspace. Masukkan nama workspace.
7. Pilih **Isi dengan data demo untuk mencoba** hanya bila ingin workspace baru berisi data contoh. Bila tidak dicentang, workspace dimulai kosong dengan satu anggota resource yang mewakili owner.
8. Akun pembuat workspace menjadi **Owner**.

Untuk memakai mode lokal tanpa cloud, pilih **Coba mode lokal / demo di browser ini** pada layar login. Preferensi mode lokal diingat pada browser itu.

### 3.6 Tambahkan anggota dan berikan role

Kairos tidak memakai `service_role` untuk membuat undangan email. Alur yang tersedia adalah menambahkan **akun Supabase yang sudah terdaftar**:

1. Minta rekan membuat akun di layar Kairos (menggunakan Project URL/key project yang sama) dan menyelesaikan konfirmasi email jika diwajibkan.
2. Owner membuka **Pengaturan → Database & akses → Anggota & role workspace**.
3. Di Supabase Dashboard, buka **Authentication → Users**, temukan akun rekan, lalu salin **User ID/UUID**. Jangan mengandalkan email sebagai ID.
4. Tempel UUID ke kolom User ID Supabase, pilih role, lalu tambahkan.
5. Pengguna tersebut masuk kembali ke Kairos. Workspace bersama akan muncul pada akun mereka.
6. Owner dapat mengubah role atau mengeluarkan user dari workspace. Owner tidak dapat menghapus dirinya sendiri dari roster lewat UI ini.

Jika roster menampilkan hanya satu orang, pastikan UI menggunakan build yang sudah memiliki policy RLS dan query roster; owner harus berada pada workspace yang sama dengan pengguna yang ditambahkan.

### 3.7 Arti role cloud

| Role | Dapat melihat data | Dapat mengubah data aplikasi | Dapat mengelola anggota/role |
|---|---:|---:|---:|
| **Owner** | Ya | Ya | Ya |
| **Project Manager** | Ya | Ya | Tidak; owner yang mengelola roster |
| **Anggota tim** | Ya | Ya | Tidak; owner yang mengelola roster |
| **Stakeholder** | Ya | Tidak (baca saja) | Tidak |

“Anggota tim” di role cloud berarti **editor workspace**. Kolom role pada halaman **Tim & kapasitas** adalah peran operasional untuk resource planning—misalnya Developer atau QA—dan bukan pengganti role keamanan Supabase. Tab **Role & permission** adalah matriks dokumentasi/konfigurasi aplikasi; kebijakan cloud yang benar-benar berlaku tetap role membership dan RLS.

---

## 4. Publikasikan sebagai situs statis GitHub Pages

### 4.1 Persiapan repository

1. Buat repository GitHub untuk proyek.
2. Letakkan `index.html` di root repository. Sertakan juga folder `supabase/`, README, dan manual.
3. Commit dan push perubahan ke branch utama (contoh: `main`).
4. Tidak perlu membuat server backend di GitHub Pages.

### 4.2 Aktifkan GitHub Pages

1. Buka repository → **Settings → Pages**.
2. Pilih **Deploy from a branch**.
3. Pilih branch utama dan folder root (`/`), kemudian simpan.
4. Tunggu proses publikasi. GitHub menampilkan URL situs, biasanya `https://NAMA-AKUN.github.io/NAMA-REPOSITORY/`.
5. Buka URL itu di browser dan pastikan halaman dapat dimuat.
6. Tambahkan URL GitHub Pages tersebut ke Site URL/Redirect URLs di Supabase Auth seperti pada bagian 3.3.

### 4.3 Bagaimana tiap browser mendapatkan konfigurasi

Ada dua pilihan:

- **Konfigurasi manual per browser:** setiap pengguna membuka Pengaturan → Database & akses, memasukkan URL dan anon/public key satu kali. Praktis untuk uji coba atau penggunaan internal kecil.
- **Konfigurasi publik di file situs:** untuk menghindari input berulang, administrator dapat mengisi object konfigurasi pada source **sebelum script aplikasi utama** di `index.html`:

  ```html
  <script>
    window.KAIROS_SUPABASE_CONFIG = {
      url: "https://PROJECT-REF.supabase.co",
      anonKey: "ANON-ATAU-PUBLISHABLE-KEY"
    };
  </script>
  ```

  Ganti kedua nilai contoh. Letakkan script itu sebelum script aplikasi yang membaca `window.KAIROS_SUPABASE_CONFIG`. Hanya masukkan public key. Jika repository publik, nilai public key akan terlihat oleh siapa pun—ini normal **hanya** dengan RLS yang sudah diperiksa. Jangan menulis database password, refresh token, `service_role`, atau secret key di file.

Jika mengubah `index.html`, commit/push ulang dan tunggu GitHub Pages selesai deploy. Setiap anggota tetap perlu akun sendiri; mengisi URL/key tidak otomatis menambah membership.

---

## 5. Panduan navigasi aplikasi

### 5.1 Bilah sisi

- **Dashboard** — ikhtisar portofolio, KPI, isu penting, dan tenggat.
- **Proyek** — daftar semua proyek yang tidak diarsipkan; Waterfall dan Agile bisa difilter.
- **Waterfall** — modul hanya untuk proyek dengan metodologi Waterfall.
- **Agile** — modul hanya untuk proyek dengan metodologi Agile.
- **Tim & kapasitas** — direktori resource, beban kerja, dan jam kerja.
- **Laporan** — laporan lintas proyek dengan filter dan ekspor.
- **Pengaturan** — database/akses, workflow, kalender, matriks role, template, dan arsip.

Klik nama workspace di sisi kiri untuk memilih workspace lain yang diikuti akun. Di bagian profil kiri bawah, pengguna cloud dapat keluar dari workspace.

### 5.2 Bar atas

- **Pencarian** mencari proyek, pekerjaan/tugas, dan risiko. Pilih hasil untuk membuka item/proyek terkait.
- **Tanggal** menunjukkan tanggal lokal hari ini.
- **Notifikasi** merangkum sebagian tugas terlambat dan risiko kritis.
- **Proyek baru** membuka formulir proyek.
- **Lencana sinkronisasi** menunjukkan status cloud: Lokal/Mode lokal, Belum masuk, Menyimpan, Tersinkron, Offline, atau Konflik.
- Tombol **sinkronkan** memaksa aplikasi mencoba mengirim perubahan tertunda lalu memuat state terbaru.

---

## 6. Dashboard dan KPI

Dashboard dihitung dari proyek dan data yang sedang terlihat dalam workspace.

| Kartu/area | Arti dan cara membacanya |
|---|---|
| **Proyek aktif** | Jumlah proyek yang tidak diarsipkan. Status lifecycle Completed/On Hold tetap dihitung selama proyek belum diarsipkan. |
| **Waterfall / Agile** | Jumlah proyek tidak diarsipkan per metodologi. |
| **Progres portofolio** | Rata-rata aritmetika progres aktual seluruh proyek tidak diarsipkan, bukan rata-rata berbobot anggaran. Dibandingkan dengan rata-rata progres rencana. |
| **Proyek sesuai jalur** | Jumlah dan persentase proyek yang hasil aturan kesehatan internalnya “On track”. Bukan penilaian otomatis dari seluruh detail jadwal. |
| **Anggaran terpakai** | Total biaya aktual ÷ total anggaran proyek × 100%. Perbarui biaya aktual dan anggaran agar angkanya bermakna. |
| **Progres rencana vs aktual** | Grafik membandingkan progres proyek. Nilai progres rencana dan aktual merupakan input proyek/hasil agregasi pekerjaan, bukan kurva otomatis berbasis tanggal. |
| **Kesehatan portofolio** | Sebaran On track, At risk, Delayed; proyek yang sudah Completed ditampilkan sebagai selesai pada konteks detail. |
| **Butuh perhatian** | Contoh tugas terlambat, risiko dengan skor tinggi/kritis, dan isu yang belum selesai. Buka item untuk meninjau proyeknya. |
| **Jatuh tempo 7 hari ke depan** | Tugas belum selesai dengan tanggal jatuh tempo antara hari ini dan 7 hari mendatang. |
| **Proyek yang sedang berjalan** | Tabel ringkas proyek dengan metodologi, kesehatan, prioritas, progres, target, dan anggaran. |

**Aturan kesehatan proyek pada aplikasi:**

1. `Completed` bila lifecycle proyek Completed atau progres aktual mencapai 100%.
2. `Delayed` bila progres aktual tertinggal sekurangnya 10 poin persentase dari rencana, atau SPI < 0,80.
3. `At risk` bila ketertinggalan sekurangnya 4 poin persentase, CPI < 0,90, atau SPI < 0,90. Lifecycle On Hold juga ditandai berisiko.
4. Selain kondisi di atas, statusnya `On track`.

Nilai ini adalah indikator bantu, bukan pengganti penilaian PM dan tidak otomatis membuat recovery plan.

---

## 7. Membuat dan mengelola proyek

Pilih **Proyek baru** dari Dashboard atau halaman Proyek. Formulir proyek memuat:

| Item | Makna | Cara mengisi |
|---|---|---|
| **Nama proyek** | Nama yang mudah dikenali tim. | Gunakan nama resmi/tujuan proyek. |
| **Kode proyek** | ID singkat untuk task/WBS dan laporan. | Buat kode yang unik, misalnya `ERP-26`; aplikasi tidak mengganti aturan penomoran organisasi Anda. |
| **Metodologi** | Menentukan modul dan bentuk pekerjaan. | Pilih Waterfall atau Agile. Proyek tidak tampil pada modul metode yang lain. |
| **Project Manager** | Pemilik operasional proyek. | Pilih anggota dari direktori Tim & kapasitas. |
| **Prioritas** | Kepentingan relatif proyek. | Tinggi, Sedang, atau Rendah. |
| **Status siklus proyek** | Lifecycle administratif proyek. | Aktif, Ditahan, atau Selesai. Ini berbeda dari kesehatan On track/At risk/Delayed. |
| **Tanggal mulai / target selesai** | Rentang baseline proyek. | Gunakan tanggal rencana yang disetujui. |
| **Anggaran** | Budget yang dipakai kartu budget dan persentase terpakai. | Masukkan angka rupiah tanpa pemisah. |
| **Baseline budget (BAC)** | Budget at Completion untuk perhitungan EVM. | Isi baseline yang disepakati. Jika kosong/nol, aplikasi menggunakan nilai anggaran. |
| **Biaya aktual** | Actual Cost (AC) proyek. | Perbarui secara berkala sesuai data finance. |
| **Progres aktual** | Estimasi porsi pekerjaan yang sudah diselesaikan. | Isi 0–100. Perubahan status tugas yang termasuk progres dapat menghitung ulang nilai ini. |
| **Progres rencana** | Porsi pekerjaan yang seharusnya selesai pada titik pelaporan. | Isi 0–100 secara manual sesuai baseline/rencana. |
| **Tujuan** | Alasan/hasil bisnis proyek. | Tulis tujuan yang bisa dipahami sponsor. |
| **Scope** | Batas pekerjaan yang termasuk/tidak termasuk. | Catat batasan penting. |
| **Deliverables** | Hasil kerja yang harus diserahkan. | Sebutkan deliverable dan bukti penerimaan. |
| **Stakeholder** | Pihak yang terdampak atau menyetujui proyek. | Cantumkan nama/kelompok stakeholder. |

Saat proyek dibuat, Kairos menambahkan beberapa starter task; proyek Agile juga mendapat Sprint 1 awal. Hapus/edit starter item yang tidak relevan. Untuk mengedit, buka proyek lalu gunakan tombol edit. Arsip menyembunyikan proyek dari tampilan aktif tetapi mempertahankan datanya; pulihkan melalui Pengaturan → Arsip. Penghapusan permanen proyek menghapus seluruh record terkait—gunakan dengan sangat hati-hati.

### Detail proyek

Tab detail proyek:

- **Ringkasan** — progres, kesehatan, budget/resources, EVM, charter, risiko prioritas, audit trail.
- **Tugas & WBS** — daftar pekerjaan, PIC, status, deadline, poin, dependensi, edit/hapus.
- **Timeline** — baseline, target, milestone, dan tampilan Gantt.
- **Risiko & issue** — risk register dan issue/defect log proyek.
- **Governance** — change request, decision log, catatan komunikasi stakeholder, audit; proyek Waterfall juga menampilkan tautan requirements dan dokumen.

---

## 8. Modul Waterfall

Masuk ke **Waterfall**. Pilih proyek dari daftar proyek Waterfall di dropdown.

### 8.1 WBS & tugas

Fase standar yang tersedia adalah **Inisiasi, Perencanaan, Perancangan, Pengembangan, Pengujian, Peluncuran, Penutupan**. `Work Breakdown Structure (WBS)` memecah scope menjadi aktivitas yang bisa ditugaskan dan dipantau.

Pada pekerjaan Waterfall:

- Buat tugas dengan nama, fase, PIC, prioritas, status, deadline, estimasi/jam aktual, dan deskripsi.
- Tandai **Critical path** secara manual pada aktivitas yang dianggap kritis.
- Tambahkan **Dependensi** bila sebuah pekerjaan baru dapat dimulai setelah pekerjaan lain selesai.
- Perbarui status melalui dropdown. Status `Selesai` memberi progres 100%; status antara memberi nilai indikator progres sementara.
- Progres aktual proyek dihitung sebagai rata-rata progres pekerjaan yang disertakan (bukan pembobotan effort). Jika task baru dibuat atau status task berubah, nilai proyek dapat berubah.

Dependensi dicatat untuk dibaca tim, tetapi Kairos **tidak menjalankan algoritme CPM lengkap** untuk menghitung ulang seluruh tanggal otomatis. Bar Gantt adalah visualisasi sederhana; PM tetap mengelola baseline dan tanggal.

### 8.2 Timeline/Gantt dan milestone

- Timeline memperlihatkan aktivitas dan milestone terhadap rentang tanggal proyek.
- Gunakan **Milestone** untuk checkpoint atau hasil yang harus dicapai pada tanggal tertentu.
- Status milestone: Direncanakan, Sedang dikerjakan, Selesai, atau Berisiko.
- Ubah target/status dengan tombol edit atau dropdown yang tersedia.
- **Critical path** adalah penanda manual; pastikan penandaan tetap valid setelah scope/jadwal berubah.

### 8.3 Requirement dan dokumen

**Requirement** menyimpan ID, judul, owner, acceptance criteria, status, dan approver. Status umumnya Draf → Dalam peninjauan → Disetujui/Ditolak. Tombol persetujuan mengisi approver sesuai pengguna demo saat ini; pada cloud, gunakan proses governance internal untuk memastikan orang yang tepat menyetujui.

**Dokumen/notulen** mencatat judul, kategori, owner, tanggal, URL/lokasi, dan status persetujuan. URL hanya tautan; file tidak diunggah ke database Kairos. Simpan file aslinya di DMS/Drive organisasi dan catat tautannya di sini.

---

## 9. Modul Agile

Masuk ke **Agile**. Modul ini menampilkan hanya proyek metodologi Agile.

### 9.1 Tab papan Scrum

- Papan mengelompokkan item sprint menurut kolom workflow: default **Belum dikerjakan → Sedang dikerjakan → Tinjauan kode → Pengujian → Selesai**. Item Blocked dapat menambahkan kolom **Terhambat**.
- Tarik kartu ke kolom lain atau edit status untuk memperbarui status.
- Kartu menunjukkan ID, tipe, judul, prioritas, deadline, PIC, dan story point.
- **User story/backlog item** dapat berupa Epic, Story, Task, Bug, atau Subtask.
- Perubahan workflow di **Pengaturan → Workflow** mengubah daftar kolom bersama; status yang sudah tersimpan tidak otomatis dihapus jika kolomnya dihilangkan.

### 9.2 Product backlog

Backlog menampung ide/pekerjaan Agile yang belum atau belum sedang berada di sprint terpilih. Buat backlog item, beri deskripsi/acceptance criteria, tipe, prioritas, poin, PIC, dan target. Tombol **Ke sprint** memasukkan item ke sprint terpilih. Item backlog yang belum dimasukkan ke sprint tidak dihitung sebagai progres sprint; progress portfolio menghitung task yang memang disertakan.

### 9.3 Sprint

Buat sprint dengan:

- **Nama sprint** — label urutan/periode, misalnya Sprint 4.
- **Sprint goal** — hasil/tujuan yang ingin dicapai selama sprint.
- **Tanggal mulai dan selesai** — timebox.
- **Kapasitas story point** — jumlah poin realistis yang dapat diterima tim.

Sprint baru menjadi sprint aktif proyek tersebut. Sebelum memulai, rapikan backlog, tentukan goal, cek kapasitas, assign PIC, dan pilih item yang akan dikerjakan. Saat mengakhiri sprint, review item yang benar-benar Done dan pindahkan sisa item sesuai proses tim.

### 9.4 Sprint insights

- **Completion** = jumlah user story/tugas Done ÷ jumlah item sprint.
- **Story points selesai** = total point item yang Done dari total point sprint.
- **Capacity utilization** = committed story point ÷ kapasitas sprint. Angka >100% berarti tim berisiko mengambil terlalu banyak pekerjaan.
- **Burndown** membandingkan garis ideal dengan sisa poin pada kondisi saat ini. Kurva aktual merupakan estimasi dari snapshot item sekarang; aplikasi belum menyimpan riwayat harian point tersisa, sehingga grafik bukan rekaman timeseries aktual.
- **Velocity** menampilkan jumlah poin selesai per sprint yang tercatat di proyek. Pakai beberapa sprint aktual sebagai dasar perkiraan, bukan target individu.
- **Cumulative flow** adalah snapshot jumlah item per status saat ini, bukan histori harian.
- **Impediment/defect** dicatat sebagai issue dengan severity, owner, target, status, dan deskripsi.

### 9.5 Stand-up, retrospective, release

- **Daily stand-up**: pilih proyek, sprint, anggota, tanggal; isi kemarin, hari ini, dan blocker. Catatan ini membantu koordinasi, bukan penilaian performa individu.
- **Retrospective**: tulis hal yang berjalan baik, hal yang perlu ditingkatkan, dan action item untuk sprint berikutnya.
- **Release plan**: catat nama release, target date, status, dan tujuan release.

---

## 10. Arti formulir dan record lainnya

| Item | Arti | Penggunaan yang disarankan |
|---|---|---|
| **Task / pekerjaan** | Unit pekerjaan yang ditugaskan dan dilacak. | Satu record per aktivitas yang dapat memiliki PIC, status, tanggal, dan estimasi yang jelas. |
| **Jenis pekerjaan** | Task, Epic, Story, Bug, atau Subtask. | Gunakan sesuai struktur tim; tipe ini label pengelompokan, bukan workflow approval. |
| **Status tugas** | Belum dikerjakan, Sedang dikerjakan, Tinjauan kode, Pengujian, Selesai, Terhambat. | Ubah status saat pekerjaan benar-benar berpindah tahap. `Done`/Selesai menandai progres 100%. |
| **Prioritas** | Tinggi, Sedang, Rendah. | Prioritaskan relatif terhadap item lain; bukan pengganti severity risiko/isu. |
| **PIC / assignee** | Orang yang mengerjakan atau bertanggung jawab atas item. | Pilih nama yang sama persis dengan direktori Tim agar beban kerja terbaca. |
| **Story points** | Ukuran relatif kompleksitas/effort untuk Agile. | Gunakan skala tim yang konsisten; jangan disamakan langsung dengan jam kerja. |
| **Estimasi / aktual / sisa jam** | Perkiraan total jam, jam terpakai, dan jam tersisa. | Perbarui saat pekerjaan berjalan untuk resource workload. |
| **Risiko** | Kejadian potensial yang belum tentu terjadi tetapi dapat memengaruhi tujuan. | Isi probabilitas, dampak, mitigasi, owner, tanggal review, dan status. |
| **Issue/isu** | Masalah yang sudah terjadi atau blocker yang memerlukan tindakan. | Catat severity, owner, target penyelesaian, status, dan detail blocker. |
| **Change request** | Permintaan mengubah scope, jadwal, biaya, atau baseline. | Catat requester, tanggal, status peninjauan, dan dampak. Jangan mengubah baseline diam-diam. |
| **Decision log** | Keputusan penting yang telah dibuat. | Catat keputusan, pemilik/forum, tanggal, rasional, dan tindak lanjut. |
| **Stakeholder communication** | Bukti komunikasi dengan audience/pihak terkait. | Catat channel, ringkasan, audience, dan follow-up/owner. |
| **Anggota tim/resource** | Direktori perencanaan kapasitas operasional. | Isi nama, peran kerja, email, kapasitas jam per minggu, skills/tanggung jawab. Ini terpisah dari keanggotaan login Supabase. |
| **Requirement** | Kebutuhan/acceptance yang perlu ditinjau atau disetujui. | Beri key unik, owner, kriteria penerimaan, approver, dan status. |
| **Dokumen** | Referensi dokumen, notulen, bukti test, runbook, atau sign-off. | Simpan URL aman ke DMS; aplikasi hanya mencatat metadata/link. |
| **Milestone** | Checkpoint atau deliverable pada tanggal target. | Gunakan untuk steering review, handover, cutover, sign-off, atau release gate. |
| **Kalender kerja** | Hari kerja dan tanggal libur yang dipakai sebagai referensi jadwal/kapasitas. | Pilih hari kerja tim dan tambahkan hari libur. Fitur ini tidak otomatis menghitung ulang semua tanggal task. |
| **Arsip proyek** | Menyembunyikan proyek dari daftar aktif tanpa menghapus record. | Arsipkan proyek selesai/tidak aktif. Pulihkan dari Pengaturan → Arsip. |
| **Audit trail** | Catatan aktivitas/perubahan terbaru di aplikasi. | Gunakan untuk memahami perubahan terbaru; ini bukan audit log compliance yang immutable. |

### 10.1 Status penting

- **Lifecycle proyek:** Aktif, Ditahan, Selesai.
- **Kesehatan proyek:** Sesuai rencana (On track), Berisiko (At risk), Terlambat (Delayed), atau Selesai (Completed).
- **Risiko:** Terbuka (Open), Dalam mitigasi (Mitigating), Ditutup (Closed).
- **Issue:** Terbuka, Sedang dikerjakan, Terselesaikan, Ditutup.
- **Requirement:** Draf, Dalam peninjauan, Disetujui, Ditolak.
- **Dokumen:** Draf, Dalam peninjauan, Disetujui.
- **Change request:** Dalam peninjauan, Menunggu, Disetujui, Ditolak.
- **Milestone:** Direncanakan, Sedang dikerjakan, Selesai, Berisiko.

Nilai internal status disimpan dalam kode Inggris agar konsisten dengan data dan workflow; label utama pada interface ditampilkan dalam bahasa Indonesia.

---

## 11. Risiko, isu, tim, dan kapasitas

### 11.1 Risk register

Isi **Probability/Probabilitas (1–5)** dan **Impact/Dampak (1–5)**. Skor = probabilitas × dampak, rentang 1–25.

- 1–9: moderat/rendah.
- 10–15: tinggi.
- 16–25: kritis.

Isi rencana mitigasi yang berisi tindakan, trigger, owner, dan tanggal review. Skor tidak menggantikan penilaian konteks; risiko legal, keselamatan, atau keamanan bisa perlu eskalasi walau skor angka lebih kecil.

### 11.2 Issue log

Gunakan issue untuk kondisi yang sudah terjadi, bukan kejadian potensial. Severity yang tinggi/kritis perlu owner, target date, status, dan tindak lanjut jelas. Status Teratasi/Closed menghilangkan item dari hitungan issue terbuka.

### 11.3 Tim & beban kerja

- Kapasitas anggota dimasukkan dalam **jam per minggu**.
- Beban kerja menghitung sisa jam task yang belum selesai terhadap kapasitas dua minggu (kapasitas mingguan × 2).
- Utilisasi = sisa estimasi jam ÷ kapasitas dua minggu × 100%.
- >100% menunjukkan potensi over-allocation; 80–100% diberi tanda peringatan.
- Jam aktual, estimasi, dan sisa jam perlu diperbarui secara konsisten. Story point tidak ditambahkan sebagai jam.

---

## 12. EVM (Earned Value Management)

Pada detail proyek, Kairos menampilkan nilai EVM berikut:

| Simbol | Istilah | Rumus di aplikasi | Cara menafsirkan |
|---|---|---|---|
| **BAC** | Budget at Completion | Baseline budget; jika kosong/nol memakai budget proyek | Total baseline budget proyek. |
| **PV** | Planned Value | BAC × progres rencana / 100 | Nilai pekerjaan yang menurut rencana seharusnya sudah selesai. |
| **EV** | Earned Value | BAC × progres aktual / 100 | Nilai budget untuk pekerjaan yang dilaporkan selesai. |
| **AC** | Actual Cost | Biaya aktual proyek | Uang yang benar-benar sudah dikeluarkan/dicatat. |
| **CV** | Cost Variance | EV − AC | Positif: nilai hasil lebih besar dari biaya; negatif: biaya melebihi earned value. |
| **SV** | Schedule Variance | EV − PV | Positif: nilai hasil di atas rencana; negatif: tertinggal dari rencana. |
| **CPI** | Cost Performance Index | EV ÷ AC | >1 umumnya lebih baik dari baseline biaya; <1 kurang efisien. Kosong bila AC=0. |
| **SPI** | Schedule Performance Index | EV ÷ PV | >1 di atas rencana; <1 di bawah rencana. Kosong bila PV=0. |
| **EAC** | Estimate at Completion | BAC ÷ CPI bila CPI tersedia; selain itu BAC | Proyeksi sederhana total biaya pada akhir proyek bila tren CPI berlanjut. |

**Contoh:** BAC Rp1.000.000.000, progres rencana 50%, progres aktual 40%, AC Rp450.000.000. Maka PV Rp500.000.000, EV Rp400.000.000, CV −Rp50.000.000, SV −Rp100.000.000, CPI sekitar 0,89, SPI 0,80, dan EAC sekitar Rp1.125.000.000.

> Perhitungan EVM di sini adalah estimasi ringkas berbasis progres proyek dan baseline budget; progres aktual bukan perhitungan earned value per WBS yang berbobot biaya. Validasi data, metode pengakuan EV, dan keputusan finance tetap harus mengikuti standar organisasi.

---

## 13. Laporan dan ekspor

Buka **Laporan**. Pilih jenis laporan, proyek, periode, status, anggota, sprint, dan fase. Filter tanggal laporan terutama memilih record berdasarkan tanggal jatuh tempo; review hasil sebelum dibagikan.

Jenis laporan yang tersedia:

- Ringkasan eksekutif.
- Status proyek.
- Progres mingguan/bulanan.
- Jadwal & Gantt.
- Laporan sprint.
- Anggaran & biaya.
- EVM.
- Risiko & isu.
- Pemanfaatan sumber daya.
- Milestone & hasil kerja.

Ekspor:

- **CSV** — cocok untuk analisis lanjutan di spreadsheet; file dikodekan UTF-8.
- **XLSX** — buku kerja Excel dengan lembar ringkasan, portofolio, tugas, risiko, isu, resource, dan milestone.
- **PDF** — tombol PDF membuka dialog cetak browser. Pilih printer **Save as PDF / Simpan sebagai PDF**.
- **Snapshot data JSON** — tersedia pada Pengaturan → Database & akses. Snapshot ini berisi payload data aplikasi dan metadata workspace/version. Perlakukan file sebagai data internal.

CSV/XLSX/PDF laporan **bukan** backup penuh untuk pemulihan workspace. Snapshot JSON juga belum menyediakan tombol impor/pulihkan otomatis.

---

## 14. Pengaturan aplikasi

### Database & akses

Mengatur URL/key Supabase lokal browser, status sinkronisasi, workspace ID/versi, roster, role cloud, sinkronisasi manual, mode lokal, serta snapshot JSON. Jangan memasukkan secret/service-role key.

### Workflow

Mengubah nama/urutan/kolom pada Scrum board bersama. Default: To Do, In Progress, Code Review, Testing, Done. Kolom Blocked dapat muncul bila ada task berstatus tersebut. Menghapus kolom tidak otomatis mengubah nilai status item yang sudah tersimpan.

### Kalender kerja

Pilih hari kerja Senin–Jumat (default) atau hari lain dan tambahkan tanggal libur. Ini membantu perencanaan, tetapi tidak menggeser tanggal task otomatis.

### Role & permission

Menampilkan matriks permission untuk dokumentasi kerja. Pada cloud, jangan menganggap kotak centang matriks ini sebagai ACL Supabase; akses nyata ditentukan role `workspace_members` dan RLS.

### Template

Template Waterfall membuat struktur awal berupa beberapa starter task; template Agile membuat struktur awal dan Sprint 1. Periksa, ubah, atau hapus item contoh sebelum menjadikannya baseline proyek sungguhan.

### Arsip

Memuat proyek yang diarsipkan. Owner/editor yang memiliki hak dapat memulihkan atau menghapus permanen proyek. Penghapusan permanen tidak dapat dibatalkan.

---

## 15. Sinkronisasi bersama dan konflik

- Setelah edit, data langsung ditulis ke cache lokal browser. Pada mode cloud, perubahan dijadwalkan untuk dikirim setelah jeda singkat.
- Penyimpanan cloud menggunakan pembaruan bersyarat terhadap nomor `version`; tujuannya mencegah perubahan terakhir diam-diam menimpa versi yang lebih baru.
- Aplikasi memeriksa state cloud berkala (sekitar 12 detik). Ini **bukan** realtime; pengguna lain mungkin perlu menunggu sebentar atau menekan **Sinkronkan sekarang**.
- Jika internet/API gagal, perubahan lokal tetap dicoba disimpan; lencana menunjukkan Offline. Coba sinkronkan lagi setelah koneksi kembali.
- Jika dua pengguna menyimpan pada versi yang sama, Kairos memuat versi cloud terbaru dan mempertahankan draft lokal yang gagal dikirim di browser tersebut. Buka **Pengaturan → Database & akses** untuk memilih **Gunakan draft lokal** atau **Buang draft**.
- **Gunakan draft lokal** mengirim seluruh payload lokal sebagai versi terbaru; perubahan orang lain setelah sinkron terakhir dapat tertimpa. Tinjau dengan anggota tim terlebih dahulu. Tidak ada penggabungan otomatis per-field.
- Draft konflik tersimpan di localStorage browser dan tidak berpindah ke perangkat lain. Jangan hapus data situs/browser sebelum memulihkannya.
- Hindari mengedit record yang sama secara bersamaan. Komunikasikan edit baseline, anggaran, atau keputusan besar di luar aplikasi.

---

## 16. Backup, pemulihan, dan keamanan

### Backup

1. Untuk snapshot cepat, buka **Pengaturan → Database & akses → Unduh snapshot data JSON**. Simpan di tempat organisasi yang aksesnya dibatasi.
2. Untuk backup produksi, atur backup PostgreSQL melalui fasilitas backup project Supabase sesuai paket/kebijakan Anda atau lakukan dump terjadwal menggunakan alat PostgreSQL. Contoh untuk operator yang sudah memiliki connection string aman:

   ```bash
   pg_dump "$DATABASE_URL" --format=custom --file kairos-backup.dump
   ```

   Simpan `DATABASE_URL` hanya di environment/secret manager operator; jangan kirim lewat chat dan jangan memasukkannya ke Git.
3. Uji pemulihan di project staging secara berkala.
4. XLSX/CSV/PDF adalah laporan; JSON snapshot adalah arsip payload. Untuk pemulihan database penuh, gunakan backup PostgreSQL. Kairos saat ini tidak menyediakan import JSON satu klik.

### Pengamanan dasar

- Pertahankan RLS pada tiga tabel dan jangan mengizinkan akses anon tanpa policy yang memang dirancang.
- Jangan gunakan `service_role` di frontend. Key publik boleh terlihat, tetapi bukan pengganti RLS.
- Batasi orang yang dapat menjadi Owner. Review roster secara berkala dan hapus akun yang tidak lagi perlu.
- Data yang ditulis ke `workspace_state.payload` dapat dibaca seluruh member workspace sesuai policy. Jangan menyimpan password, token, rahasia produksi, atau data sensitif yang tidak boleh dilihat semua anggota.
- Stakeholder memiliki akses baca ke seluruh payload workspace, termasuk bagian yang belum disembunyikan secara field-level. Jangan gunakan role stakeholder untuk data yang harus dirahasiakan dari mereka.
- Snapshot dan ekspor dapat memuat nama, email, anggaran, isu, atau data proyek. Simpan dan bagikan sesuai kebijakan organisasi.

---

## 17. Pemecahan masalah

| Gejala | Periksa / tindakan |
|---|---|
| **Failed to fetch / tidak dapat terhubung** | Periksa koneksi internet, Project URL lengkap (HTTPS dan tanpa typo), anon/public key, status project Supabase, serta kemungkinan proxy/firewall organisasi. Coba buka ulang halaman setelah project aktif. |
| **Invalid API key / 401** | Pastikan memakai key dari project yang sama dengan URL, bukan password database, bukan service-role secret, dan tidak ada spasi saat menempel. Jika sesi lama invalid, keluar lalu masuk kembali. |
| **Email/password salah** | Pastikan email sudah terdaftar dan konfirmasi email (jika diwajibkan) telah selesai. Auth provider email/password harus aktif di Supabase. |
| **Akun belum terhubung ke workspace** | Owner perlu membuat workspace atau menambahkan User ID akun Anda ke roster. Masukkan UUID Auth Users, bukan email. |
| **403 / permission denied / row-level security** | Pastikan `schema.sql` sudah dijalankan pada project yang benar dan semua tabel RLS/policy/grants ada. Pastikan user memiliki membership di workspace tersebut dan gunakan role yang benar. Jangan menyelesaikan error dengan menonaktifkan RLS. |
| **Gagal menambah anggota / foreign key** | User harus sudah mendaftar di project Supabase yang sama. Salin ulang UUID persis dari Authentication → Users. Hanya Owner yang dapat menambah/mengubah role. |
| **Roster tidak terlihat** | Periksa membership workspace yang aktif, query/list policy `workspace_members_select_member`, lalu keluar-masuk kembali. Pastikan owner dan anggota berada pada workspace yang sama. |
| **Status Offline / perubahan belum terkirim** | Coba **Sinkronkan sekarang** saat jaringan/API pulih. Draft lokal disimpan pada browser. Jangan hapus site data sebelum memeriksa snapshot/draft. |
| **Konflik versi** | Buka Pengaturan → Database & akses, bandingkan dengan anggota lain, lalu pilih apakah akan memakai draft lokal atau membuangnya. Mengirim draft dapat menimpa seluruh payload terbaru. |
| **Situs GitHub Pages menampilkan 404** | Pastikan Pages menunjuk branch dan folder yang benar, `index.html` berada pada folder tersebut, build/deploy selesai, dan URL memakai nama repository yang tepat. |
| **Halaman GitHub Pages terbuka tapi tetap mode lokal** | Masuk ke Pengaturan → Database & akses. Periksa URL/key browser atau pastikan object `window.KAIROS_SUPABASE_CONFIG` disisipkan sebelum script utama. Ubah project Supabase Auth redirect URL. |
| **Konfirmasi email kembali ke localhost atau URL salah** | Perbarui Site URL, Redirect URLs, dan email template Supabase ke URL GitHub Pages yang benar. |
| **PDF kosong/tidak rapi** | Gunakan tombol PDF dari laporan, tunggu dialog cetak, pilih Save as PDF, dan pastikan browser mengizinkan dialog cetak. Filter laporan sebelum mencetak. |
| **Progres/EVM terasa tidak sesuai** | Periksa actual progress, planned progress, BAC/budget, actual cost, status task, backlog inclusion, dan update data. EVM memakai progres proyek sederhana; bukan sistem akuntansi/CPM lengkap. |
| **Kapasitas menampilkan beban tidak realistis** | Pastikan nama assignee sama dengan nama anggota tim, isi capacity dalam jam per minggu, lalu perbarui remaining hours pada setiap task. |

---

## 18. Batasan yang perlu diketahui

1. Database cloud menyimpan payload aplikasi sebagai satu JSONB per workspace. Ini memudahkan penggunaan dan migrasi dari prototype, tetapi bukan desain ideal untuk query analytics skala besar.
2. Sinkronisasi adalah polling berkala dan optimistic locking, bukan realtime. Tidak ada merge otomatis field-per-field.
3. Tidak ada email invitation otomatis dari Kairos; Owner memasukkan UUID akun Supabase yang sudah terdaftar.
4. Role team_member dan project_manager sama-sama editor seluruh payload aplikasi. Belum ada izin granular per proyek atau per jenis data.
5. Stakeholder baca-saja pada payload, tetapi belum ada masking kolom/anggaran.
6. Fitur OAuth, MFA, pemulihan password melalui UI Kairos, upload file, komentar realtime, serta import/pemulihan snapshot JSON satu klik belum disediakan. Gunakan prosedur Supabase/organisasi untuk hal-hal tersebut.
7. Gantt, health indicator, resource utilization, dan EVM adalah alat bantu. Validasi baseline/progres dan keputusan akhir oleh Project Manager.
8. Velocity historis hanya bermakna jika proyek mencatat beberapa sprint nyata. Burndown dan cumulative flow adalah snapshot/perkiraan, bukan rekaman harian immutable.
9. Aplikasi belum dihubungkan ke project Supabase/repository GitHub tertentu. Deployment perlu dilakukan oleh pemilik kredensial dan diuji dengan akun/role nyata.

---

## 19. Glosarium ringkas

- **BAC** — Budget at Completion, baseline total biaya proyek.
- **Baseline** — rencana yang disetujui untuk dibandingkan dengan realisasi.
- **CPI** — Cost Performance Index; efisiensi biaya (EV/AC).
- **Critical path** — rangkaian aktivitas yang dianggap menentukan tanggal selesai; pada Kairos penanda diisi manual.
- **EAC** — Estimate at Completion, estimasi total biaya saat selesai.
- **EV** — Earned Value, nilai anggaran dari pekerjaan yang dilaporkan selesai.
- **Gantt** — diagram aktivitas terhadap kalender.
- **Issue/impediment** — hambatan atau masalah yang telah terjadi.
- **Milestone** — checkpoint/hasil penting pada tanggal target.
- **RLS** — Row Level Security; policy PostgreSQL yang menentukan user mana dapat membaca/mengubah baris.
- **SPI** — Schedule Performance Index; kinerja jadwal (EV/PV).
- **Story point** — ukuran relatif kompleksitas pekerjaan Agile.
- **Sprint** — timebox pendek untuk menyelesaikan sekumpulan item Agile.
- **Stakeholder** — pihak yang berkepentingan/terdampak proyek.
- **WBS** — Work Breakdown Structure, pemecahan pekerjaan proyek menjadi aktivitas yang dapat dikelola.
- **Workspace** — ruang kerja bersama yang menjadi batas akses data.

---

**Selesai.** Untuk penggunaan produksi, lakukan validasi keamanan RLS, backup/pemulihan, pengujian role, dan persetujuan IT/security sebelum memuat data sensitif.
