/// Daftar program studi Universitas Bina Sarana Informatika (UBSI)
/// dan unit kerja untuk staff, dipakai sebagai pilihan (tanpa input manual).
class ProdiOptions {
  static const Map<String, List<String>> mahasiswa = {
    'Fakultas Teknik & Informatika': [
      'S1 - Informatika',
      'S1 - Sistem Informasi',
      'S1 - Teknologi Informasi',
      'S1 - Rekayasa Perangkat Lunak',
      'S1 - Teknik Industri',
      'S1 - Teknik Elektro',
      'D3 - Sistem Informasi',
      'D3 - Teknologi Komputer',
    ],
    'Fakultas Ekonomi & Bisnis': [
      'S1 - Manajemen',
      'S1 - Akuntansi',
      'S1 - Pariwisata',
      'D3 - Akuntansi',
      'D3 - Sistem Informasi Akuntansi',
      'D3 - Administrasi Bisnis',
      'D3 - Administrasi Perkantoran',
      'D3 - Perhotelan',
    ],
    'Fakultas Komunikasi & Bahasa': [
      'S1 - Ilmu Komunikasi',
      'S1 - Sastra Inggris',
      'S1 - Desain Komunikasi Visual',
    ],
    'Fakultas Hukum': [
      'S1 - Ilmu Hukum',
      'S1 - Hukum Bisnis',
      'S1 - Hubungan Internasional',
    ],
    'Fakultas Ilmu Kesehatan': [
      'S1 - Psikologi',
    ],
    'Pascasarjana': [
      'S2 - Magister Teknik & Informatika',
      'S2 - Magister Manajemen',
      'S2 - Magister Teknologi Informasi',
    ],
  };

  static const Map<String, List<String>> staff = {
    'Unit Kerja': [
      'Rektorat',
      'BAAK (Administrasi Akademik)',
      'BAUK (Administrasi Umum & Keuangan)',
      'Perpustakaan',
      'UPT Teknologi Informasi',
      'Kemahasiswaan',
      'Keamanan & Umum (Security)',
    ],
  };

  /// Staff/dosen dapat memilih unit kerja atau prodi tempat mengajar.
  static Map<String, List<String>> forRole(String role) {
    if (role == 'staff') {
      return {
        ...staff,
        for (final e in mahasiswa.entries)
          'Dosen - ${e.key}': e.value,
      };
    }
    return mahasiswa;
  }
}
