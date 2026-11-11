import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../theme/app_theme.dart';

/// Tanda kecil FindIT: kotak amber dengan kaca pembesar, dipakai di
/// "Powered by FindIT" (Splash, Login, Profil).
class FinditMark extends StatelessWidget {
  final double size;
  const FinditMark({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.search_rounded,
        size: size * 0.66,
        color: AppColors.brandOnPrimary,
      ),
    );
  }
}

class PoweredByFindit extends StatelessWidget {
  const PoweredByFindit({super.key});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Semantics(
      label: 'Powered by FindIT',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Powered by', style: AppTypography.caption(c.textMuted)),
          const SizedBox(width: AppColors.space2),
          const FinditMark(),
          const SizedBox(width: 6),
          Text(
            'FindIT',
            style: AppTypography.label(c.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Logo kampus UBSI dari assets/images/ubsi_logo.png.
class CampusLogo extends StatelessWidget {
  final double size;
  const CampusLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: Image.asset(
        'assets/images/ubsi_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Logo Universitas Bina Sarana Informatika',
      ),
    );
  }
}

enum ReportBadgeKind { hilang, temuan, kembali }

ReportBadgeKind badgeKindFor({required bool isHilang, required String status}) {
  if (status == 'completed') return ReportBadgeKind.kembali;
  return isHilang ? ReportBadgeKind.hilang : ReportBadgeKind.temuan;
}

/// Badge status laporan: Hilang (amber), Temuan (biru), Kembali (hijau).
class StatusBadge extends StatelessWidget {
  final ReportBadgeKind kind;
  const StatusBadge({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final (String text, Color fg, Color bg) = switch (kind) {
      ReportBadgeKind.hilang => ('Hilang', c.amberText, c.amberBg),
      ReportBadgeKind.temuan => ('Temuan', c.blueText, c.blueBg),
      ReportBadgeKind.kembali => ('Kembali', c.successText, c.successBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppColors.radiusFull),
      ),
      child: Text(text, style: AppTypography.caption(fg)),
    );
  }
}

/// Kotak foto barang. Tanpa foto: ikon gambar abu di atas bg/muted.
class ReportThumb extends StatelessWidget {
  final String? url;
  final double size;
  final double? height;
  final double radius;
  final String semanticLabel;

  const ReportThumb({
    super.key,
    required this.url,
    required this.semanticLabel,
    this.size = 88,
    this.height,
    this.radius = AppColors.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final h = height ?? size;
    final placeholder = Container(
      width: size,
      height: h,
      color: c.mutedBg,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: h > 120 ? 40 : 28,
        color: c.iconMuted,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              width: size,
              height: h,
              fit: BoxFit.cover,
              semanticLabel: semanticLabel,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

/// Baris kartu laporan dengan foto kiri, badge, judul, lokasi, waktu.
class ReportListCard extends StatelessWidget {
  final String title;
  final String location;
  final String meta;
  final String? photoUrl;
  final ReportBadgeKind kind;
  final VoidCallback? onTap;

  const ReportListCard({
    super.key,
    required this.title,
    required this.location,
    required this.meta,
    required this.kind,
    this.photoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Semantics(
      button: onTap != null,
      label: '$title, $location, $meta',
      excludeSemantics: true,
      child: Material(
        color: c.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          side: BorderSide(color: c.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppColors.space4),
            child: Row(
              children: [
                ReportThumb(url: photoUrl, semanticLabel: 'Foto $title', size: 96),
                const SizedBox(width: AppColors.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusBadge(kind: kind),
                      const SizedBox(height: AppColors.space2),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall(c.textPrimary),
                      ),
                      const SizedBox(height: AppColors.space2),
                      _MetaRow(icon: Icons.location_on_outlined, text: location),
                      const SizedBox(height: AppColors.space1),
                      _MetaRow(icon: Icons.schedule_rounded, text: meta),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: c.iconMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(c.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Pill filter: aktif = gelap (text/primary), non-aktif = bg/muted.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final bg = selected ? c.textPrimary : c.mutedBg;
    final fg = selected ? c.scaffoldBg : c.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? bg : c.cardBorder),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppColors.space4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTypography.label(fg)),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 4),
                    Icon(trailingIcon, size: 16, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deret pill filter selebar layar: tiap pill sama lebar, rata kiri-kanan.
/// Label terlalu panjang mengecil (scaleDown) alih-alih terpotong.
class FilterPillBar extends StatelessWidget {
  final List<(String key, String label)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const FilterPillBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppColors.space2),
          Expanded(child: _pill(c, options[i].$1, options[i].$2)),
        ],
      ],
    );
  }

  Widget _pill(FinditColors c, String key, String label) {
    final isSelected = key == selected;
    final bg = isSelected ? c.textPrimary : c.mutedBg;
    final fg = isSelected ? c.scaffoldBg : c.textSecondary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filter $label',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: BorderSide(color: isSelected ? bg : c.cardBorder),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onSelected(key),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppColors.space2),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: AppTypography.label(fg)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon bulat 44px dengan bg/subtle dan border tipis (kembali, bagikan, tutup).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.isDark ? c.cardBg : AppColors.bgSubtle,
        shape: CircleBorder(side: BorderSide(color: c.cardBorder)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: c.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Status kosong / error yang konsisten di semua daftar.
class StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space6,
        vertical: AppColors.space8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: c.iconMuted),
          const SizedBox(height: AppColors.space3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleSmall(c.textPrimary),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.body(c.textSecondary),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppColors.space4),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
