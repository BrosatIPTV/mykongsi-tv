# MyKongsi TV Admin Panel

## Fail
- `index.html` — Admin Panel web.
- `storage-setup.sql` — bucket logo dan polisi akses Storage.

## 1. Konfigurasi Supabase
1. Buka `index.html` menggunakan editor teks.
2. Cari `SUPABASE_URL` dan `SUPABASE_ANON_KEY`.
3. Gantikan placeholder dengan Project URL dan anon/public key daripada Supabase > Project Settings > API.
4. Jangan sekali-kali masukkan `service_role` key dalam fail ini.

## 2. Storage logo
Jalankan kandungan `storage-setup.sql` di Supabase SQL Editor.

## 3. Admin login
Pastikan akaun Admin telah dicipta di Supabase Authentication > Users dan UUID akaun itu wujud dalam `public.admin_users`.
Admin log masuk menggunakan email dan password Supabase.

## 4. GitHub
Cipta repository `mykongsi-tv`, upload `index.html` dan `storage-setup.sql`.
Untuk deploy ke Vercel, import repository tersebut dan gunakan root directory.
Untuk laman statik, tiada build command diperlukan; output directory boleh dibiarkan kosong atau `.` mengikut tetapan Vercel.

## 5. Ciri versi awal
- Login Admin Supabase.
- Statistik saluran dan kategori.
- Tambah/edit/padam saluran.
- ON/OFF saluran.
- Tambah/edit/padam kategori.
- Import playlist M3U/M3U8.
- Upload logo saluran ke Supabase Storage.

Nota:
- APK belum disambungkan dalam pakej ini; ini ialah Admin Panel dahulu.
- M3U import menganggap URL selepas EXTINF sebagai satu stream dan menyimpan setiap entri sebagai saluran.
- Format MKV/FILE bergantung pada sokongan codec/peranti pemain.
- Gunakan hanya stream yang anda miliki atau mempunyai kebenaran untuk diedarkan.
