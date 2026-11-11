---
name: findit-list-update
description: Tampilkan dan perbarui daftar fitur yang direncanakan untuk aplikasi FindIT (roadmap). Pakai saat pengguna mengetik /findit-list-update, menanyakan fitur apa yang belum dibuat, mau menandai fitur selesai, atau menambah ide fitur baru.
---

# FindIT: daftar fitur yang direncanakan

Sumber data tunggal: `roadmap.md` di folder skill ini. Jangan menulis daftar dari ingatan; selalu baca file itu.

## Saat dipanggil tanpa argumen

1. Baca `roadmap.md`.
2. Untuk tiap item berstatus `[ ]`, cek cepat di kode apakah sebenarnya sudah ada (grep nama fitur / file terkait yang disebut di kolom "Petunjuk cek"). Bila ternyata sudah ada, sebutkan, tapi jangan ubah status tanpa persetujuan pengguna.
3. Tampilkan ke pengguna, dalam bahasa Indonesia:
   - Bagian "Kurang (dasar)" dan "Unggulan", masing-masing dengan status `✅ selesai` / `⏳ dikerjakan` / `⬜ belum`.
   - Urutan prioritas yang tercatat.
   - Satu kalimat: item berikutnya yang disarankan.
4. Tutup dengan pertanyaan: mau mulai item mana, atau ada yang mau ditambah/dihapus.

## Saat diminta memperbarui

- "tandai X selesai" / "X sedang dikerjakan": ubah status di `roadmap.md` (`[x]`, `[~]`, `[ ]`) dan isi kolom tanggal dengan tanggal hari ini (format YYYY-MM-DD).
- "tambah fitur ...": tambahkan baris baru di bagian yang sesuai, status `[ ]`, sertakan satu kalimat alasan dan petunjuk cek.
- "hapus X": hapus barisnya, catat di bagian "Dibatalkan" beserta alasan singkat.
- Setelah mengubah file, tampilkan ringkasan perubahan saja, bukan seluruh daftar.

## Aturan

- Jangan mulai mengerjakan fitur hanya karena skill ini dipanggil. Skill ini untuk melihat dan merawat daftar.
- Saat pengguna memilih satu item untuk dikerjakan, tandai `[~]` lalu lanjutkan dengan alur kerja biasa (cek tabel Supabase dan kode terkait dulu, buat rencana, baru implementasi).
