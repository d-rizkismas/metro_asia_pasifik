# Kairos — Manajemen Proyek Waterfall & Agile

Kairos adalah aplikasi manajemen portofolio proyek satu berkas (`index.html`) berbahasa Indonesia. Aplikasi menyediakan modul Waterfall dan Agile yang terpisah, dashboard KPI, pengelolaan proyek/tugas, EVM, risiko dan isu, tim/kapasitas, governance, laporan, dan ekspor.

## Jalankan demo lokal

1. Buka `index.html` di browser, atau jalankan server statis dari folder proyek:

   ```bash
   python3 -m http.server 8000 --bind 0.0.0.0
   ```

2. Buka `http://localhost:8000`.
3. Tanpa konfigurasi Supabase, aplikasi berjalan dalam **Mode lokal / demo**. Data disimpan di `localStorage` browser dengan kunci `kairos.pm.v1`; data ini tidak otomatis terlihat di browser atau perangkat lain.

Untuk mengembalikan data contoh lokal, buka **Pengaturan → Pulihkan demo lokal**. Tombol ini tidak menghapus workspace cloud.

## Mode tim bersama (Supabase)

GitHub Pages hanya menyajikan frontend statis. Login dan database bersama disediakan oleh project Supabase milik organisasi Anda.

1. Buat project Supabase.
2. Jalankan `/supabase/schema.sql` sekali melalui Supabase SQL Editor.
3. Di Kairos, buka **Pengaturan → Database & akses**, masukkan Project URL dan **anon/public key**, lalu simpan.
4. Buat akun email/password. Akun pertama tanpa membership dapat membuat workspace dan menjadi owner.
5. Owner menambahkan pengguna yang sudah mendaftar menggunakan User ID dari Supabase Dashboard → Authentication → Users.

Jangan pernah menaruh `service_role` atau secret key di HTML, GitHub, browser, maupun chat. RLS pada skema membatasi akses per workspace; stakeholder hanya dapat membaca. Sinkronisasi menggunakan pemeriksaan versi dan polling sekitar 12 detik, bukan realtime/WebSocket.

> Proyek ini belum dikonfigurasi dengan URL/key Supabase tertentu dan belum di-deploy ke repository GitHub pengguna. Ikuti petunjuk lengkap pada **[MANUAL.md](MANUAL.md)**.

## Fitur utama

- **Dashboard:** ringkasan jumlah proyek, progres aktual vs rencana, kesehatan portofolio, anggaran terpakai, pekerjaan terlambat, risiko kritis, isu terbuka, dan tenggat mendatang.
- **Portfolio proyek:** buat, ubah, arsipkan/pulihkan, filter, cari, dan hapus proyek; metode Waterfall dan Agile dapat dipilih.
- **Waterfall:** fase proyek, Work Breakdown Structure (WBS), dependensi, critical path, timeline/Gantt, milestone, requirements/approval, dokumen dan sign-off.
- **Agile:** product backlog, sprint, Scrum board drag-and-drop, story points, kapasitas sprint, burndown/velocity, daily stand-up, retrospective, impediment, dan release plan.
- **Kontrol proyek:** risk register (probabilitas × dampak), issue log, change request, decision log, stakeholder communication, audit trail, dan resource workload.
- **EVM:** PV, EV, AC, CV, SV, CPI, SPI, serta EAC berbasis baseline budget dan progres proyek.
- **Laporan:** filter proyek, periode, status, anggota, sprint, dan fase; ekspor CSV dan XLSX; PDF melalui dialog cetak browser.
- **Backup praktis:** unduh snapshot payload JSON dari Pengaturan → Database & akses. Snapshot JSON tidak menyediakan impor/pemulihan satu klik; gunakan backup database Supabase untuk pemulihan produksi.

## Deploy ke GitHub Pages

Buat repository, commit `index.html`, folder `supabase/`, `README.md`, dan `MANUAL.md`, lalu pilih **Settings → Pages → Deploy from a branch** dan folder root pada branch utama. Setelah situs aktif, tambahkan URL GitHub Pages ke konfigurasi Site URL/Redirect URLs pada Supabase Auth. Langkah rinci dan pengaturan keamanan terdapat di manual.

## Berkas

- `index.html` — aplikasi frontend, demo lokal, autentikasi Supabase, dan UI workspace.
- `supabase/schema.sql` — skema PostgreSQL, helper role, grants, dan Row Level Security.
- `MANUAL.md` — petunjuk instalasi, deployment, penggunaan, definisi setiap item/KPI, backup, dan pemecahan masalah.
