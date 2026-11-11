import 'package:flutter/material.dart';
import '../../../core/constants/campus_photos.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/findit_widgets.dart';
import '../../../models/campus_model.dart';

/// Hasil pemilihan cabang. [campus] null berarti "Semua Cabang UBSI".
class CampusSelection {
  final CampusModel? campus;
  const CampusSelection(this.campus);
}

/// Bottom sheet pemilih cabang dengan foto gedung dari `campuses.foto_url`.
/// Mengembalikan null bila sheet ditutup tanpa memilih.
Future<CampusSelection?> showCampusPicker(
  BuildContext context, {
  required List<CampusModel> campuses,
  required CampusModel? selected,
}) {
  return showModalBottomSheet<CampusSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    builder: (context) => _CampusPickerSheet(
      campuses: campuses,
      selected: selected,
    ),
  );
}

class _CampusPickerSheet extends StatelessWidget {
  final List<CampusModel> campuses;
  final CampusModel? selected;

  const _CampusPickerSheet({required this.campuses, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.space5, 0, AppColors.space5, AppColors.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih Cabang Kampus',
                    style: AppTypography.titleMedium(c.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Laporan di Beranda akan disaring sesuai cabang.',
                  style: AppTypography.body(c.textSecondary),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppColors.space5, 0, AppColors.space5, AppColors.space5),
              itemCount: campuses.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: AppColors.space2),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CampusTile(
                    title: 'Semua Cabang UBSI',
                    subtitle: campuses.isEmpty
                        ? 'Tampilkan laporan dari semua cabang'
                        : 'Tampilkan laporan dari ${campuses.length} cabang',
                    leading: const CampusLogo(size: 56),
                    selected: selected == null,
                    onTap: () => Navigator.pop(context, const CampusSelection(null)),
                  );
                }
                final campus = campuses[index - 1];
                return _CampusTile(
                  title: campus.namaKampus,
                  subtitle: [campus.kota, if ((campus.alamat ?? '').isNotEmpty) campus.alamat!]
                      .join(' · '),
                  leading: _CampusPhoto(campus: campus),
                  selected: selected?.id == campus.id,
                  onTap: () => Navigator.pop(context, CampusSelection(campus)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final bool selected;
  final VoidCallback onTap;

  const _CampusTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: selected ? c.brandSoftBg : c.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          side: BorderSide(
            color: selected ? AppColors.brandPrimary : c.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppColors.space2 + 2),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppColors.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall(c.textPrimary)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(c.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: AppColors.space2),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? c.amberText : c.iconMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Foto gedung cabang. Tanpa `foto_url` (atau gagal dimuat): kode kampus
/// di atas bg/muted sebagai placeholder yang jujur.
class _CampusPhoto extends StatelessWidget {
  final CampusModel campus;
  const _CampusPhoto({required this.campus});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final fallback = Container(
      width: 56,
      height: 56,
      color: c.mutedBg,
      alignment: Alignment.center,
      child: Text(
        campus.kodeKampus.isEmpty ? '?' : campus.kodeKampus,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: AppTypography.label(c.textSecondary),
      ),
    );
    final label = 'Foto gedung ${campus.namaKampus}';
    // Urutan: foto_url dari database, lalu foto bawaan aplikasi, lalu kode kampus.
    final assetPath = campusPhotoAsset(campus.kodeKampus);
    final local = assetPath == null
        ? fallback
        : Image.asset(
            assetPath,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            cacheWidth: 168,
            semanticLabel: label,
            errorBuilder: (_, __, ___) => fallback,
          );
    final url = campus.fotoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      child: url == null || url.isEmpty
          ? local
          : Image.network(
              url,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              semanticLabel: label,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : local,
              errorBuilder: (_, __, ___) => local,
            ),
    );
  }
}
