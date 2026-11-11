# Roadmap fitur FindIT

Status: `[ ]` belum · `[~]` dikerjakan · `[x]` selesai
Dibuat: 2026-11-08 (setelah redesign Figma selesai)

## Urutan prioritas

1. Push notification di HP (email dan in-app sudah selesai)
2. Pencocokan otomatis hilang ↔ temuan
3. Serah terima digital dengan QR

## Kurang (dasar)

| Status | Fitur | Alasan | Petunjuk cek | Tanggal |
|---|---|---|---|---|
| [x] | Notifikasi email (Gmail SMTP): laporan diverifikasi/ditolak, klaim masuk, klaim disetujui/ditolak | Pengguna harus buka app untuk tahu status; ikon lonceng di mockup dihapus karena belum ada fungsinya | Edge Function `notify-email`, tabel `email_notifications`, supabase/email_notifications.sql | 2026-11-09 |
| [x] | Notifikasi in-app: lonceng + badge realtime di Beranda, halaman Notifikasi | Pengguna bisa melihat kabar laporan/klaim tanpa membuka email | tabel `app_notifications`, lib/views/notifications/, supabase/app_notifications.sql | 2026-11-09 |
| [~] | Push notification di HP (FCM): muncul di bar notifikasi walau app ditutup | In-app hanya terlihat saat app dibuka | `firebase_messaging` di pubspec.yaml, tabel `device_tokens`, `google-services.json` di android/app | 2026-11-11 |
| [x] | Edit / ganti foto laporan | Form edit di report_detail_view.dart hanya mengubah teks | `_showEditDialog` di lib/views/reports/report_detail_view.dart | 2026-11-09 |
| [x] | Masa berlaku laporan + tombol "Barang sudah ketemu" | Laporan lama menumpuk tanpa batas | kolom `expires_at`, RPC `extend_report`, supabase/report_lifecycle.sql | 2026-11-09 |
| [x] | Paginasi daftar laporan | `getReports` mengambil semua baris sekaligus | `.range(` di getReports, infinite scroll di search_view.dart | 2026-11-09 |
| [x] | Filter tanggal di halaman Cari | Orang mengingat "hilang minggu lalu" | lib/views/search/search_view.dart | 2026-11-09 |
| [x] | Bagikan laporan | Ada di mockup Detail tapi dihapus karena belum berfungsi | `share_plus`, buildShareText di report_detail_view.dart | 2026-11-09 |
| [x] | Audit web + sinkronisasi dengan mobile, temuan nomor 1–16 | Web (Laravel) memakai role `postgres` sehingga RLS mobile tidak berlaku; ada kebocoran data pribadi & regresi upload foto | `C:\laragon\www\findit\docs\audit-2026-11-09.md`, commit web `c74522d` | 2026-11-09 |
| [ ] | Sisa audit web nomor 17–21 (prioritas rendah): hapus akun sendiri selalu gagal, foto lama tidak terhapus di Storage, chatbot web berbeda dari FindBot, file dev di root + `APP_DEBUG=true`, `%`/`_` di pencarian tidak di-escape | Kebersihan & konsistensi sebelum production | `C:\laragon\www\findit\docs\audit-2026-11-09.md` bagian RENDAH | |

## Unggulan (pembeda)

| Status | Fitur | Alasan | Petunjuk cek | Tanggal |
|---|---|---|---|---|
| [ ] | Pencocokan otomatis hilang ↔ temuan, **diverifikasi admin dulu**: sistem menyaring (jenis berlawanan, kategori, cabang, rentang tanggal) dan memberi skor kemiripan → antrean admin di web (**Admin → Pencocokan**, tampilan dua laporan berdampingan, tombol Cocok / Bukan pasangan) → baru setelah dikonfirmasi admin, pemilik barang hilang diberi email + notifikasi in-app → klaim lewat alur biasa. Skor mentah hanya terlihat admin; penemu tidak diberi tahu. Mulai dengan `pg_trgm`, bisa ditingkatkan ke embedding AI. | Pembeda utama dari grup WhatsApp; pendataan tetap terpusat di admin | tabel `report_matches` (status menunggu_tinjau/dikonfirmasi/ditolak/selesai), ekstensi `pg_trgm`, halaman admin di `C:\laragon\www\findit` | |
| [ ] | Serah terima digital dengan QR (Berita Acara otomatis: waktu, petugas, foto) | Gantikan formulir kertas, cegah salah serah | tabel `handovers`, paket QR di pubspec.yaml | |
| [ ] | Pencarian dengan foto (kemiripan gambar) | Lebih akurat dari deskripsi teks | embedding gambar, Edge Function | |
| [ ] | Peta titik lokasi per gedung/lantai | Lokasi teks tidak seragam; membantu pencocokan | tabel `locations` / denah per cabang | |
| [ ] | Dasbor statistik admin (lokasi rawan, waktu rawan, tingkat kembali) | Berguna untuk keamanan kampus dan nilai jual ke institusi | biasanya di dashboard web admin | |

## Dibatalkan

_(kosong)_
