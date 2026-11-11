import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Foto barang layar penuh: pinch untuk zoom, geser saat diperbesar, ketuk dua kali
/// untuk zoom cepat. Latar gelap dipakai di kedua tema agar foto terlihat jelas.
class PhotoViewerView extends StatefulWidget {
  final String url;
  final String heroTag;
  final String title;

  const PhotoViewerView({
    super.key,
    required this.url,
    required this.heroTag,
    required this.title,
  });

  @override
  State<PhotoViewerView> createState() => _PhotoViewerViewState();
}

class _PhotoViewerViewState extends State<PhotoViewerView> {
  final _controller = TransformationController();
  TapDownDetails? _doubleTapAt;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed || _doubleTapAt == null) {
      _controller.value = Matrix4.identity();
      return;
    }
    final p = _doubleTapAt!.localPosition;
    const scale = 2.5;
    _controller.value = Matrix4.identity()
      ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // expand: tanpa ini tinggi Stack ikut baris judul (~56px) dan foto ikut sekecil itu.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapAt = d,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 5,
                // Foto mengisi seluruh layar dengan proporsi asli (contain), bukan ukuran pikselnya.
                child: SizedBox.expand(
                  child: Hero(
                    tag: widget.heroTag,
                    child: Image.network(
                      widget.url,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                      semanticLabel: 'Foto ${widget.title}, layar penuh',
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const Center(
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                      // FittedBox: tetap muat walau ruangnya kecil (mis. saat animasi Hero).
                      errorBuilder: (_, __, ___) => Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image_outlined,
                                  color: Colors.white70, size: 48),
                              const SizedBox(height: 8),
                              Text('Foto gagal dimuat',
                                  style: AppTypography.body(Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Tooltip(
                      message: 'Tutup foto',
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.maybePop(context),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.close_rounded,
                                color: Colors.white,
                                semanticLabel: 'Tutup foto'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
