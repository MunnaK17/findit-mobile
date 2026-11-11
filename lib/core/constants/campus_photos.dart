/// Foto gedung tiap cabang yang di-bundle di assets/images/Kampus,
/// dikunci dengan `campuses.kode_kampus`. Dipakai bila `foto_url` kosong.
const Map<String, String> campusPhotoAssets = {
  'BSD': 'assets/images/Kampus/bsd.png',
  'CKG': 'assets/images/Kampus/ckg.png',
  'CPT': 'assets/images/Kampus/cpt.jpg',
  'CTM': 'assets/images/Kampus/ctm.png',
  'FTW': 'assets/images/Kampus/ftw.png',
  'KLB': 'assets/images/Kampus/klb.png',
  'KRM': 'assets/images/Kampus/krm.jpg',
  'KRW': 'assets/images/Kampus/krw.png',
  'MGD': 'assets/images/Kampus/mgd.jpg',
  'PMD': 'assets/images/Kampus/pmd.png',
  'SLP': 'assets/images/Kampus/slp.png',
};

String? campusPhotoAsset(String kodeKampus) =>
    campusPhotoAssets[kodeKampus.trim().toUpperCase()];
