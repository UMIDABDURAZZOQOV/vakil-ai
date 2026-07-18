import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api/api_exception.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  XFile? _captured;
  bool _processing = false;
  bool _flashOn = false;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      setState(() {
        _captured = file;
        _processing = true;
      });

      final bytes = await file.readAsBytes();
      final doc = await ref.read(documentsRepositoryProvider).upload(
            bytes: bytes,
            filename: file.name,
            contentType: file.mimeType,
          );
      ref.invalidate(documentsListProvider);
      if (!mounted) return;
      context.pushReplacement('/analysis/${doc.id}');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serverga ulanib bo\'lmadi. Backend ishga tushirilganini tekshiring.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.tr;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackdrop(),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  Text(t('document_scanner'), style: AppTextStyles.body(Colors.white, weight: FontWeight.w600)),
                  IconButton(
                    onPressed: () => setState(() => _flashOn = !_flashOn),
                    icon: Icon(_flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (!_processing)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Viewfinder(),
                      const SizedBox(height: 18),
                      Text(
                        t('point_camera_hint'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(Colors.white70, size: 13),
                      ),
                    ],
                  ),
                ),
              ),
            if (_processing) _ProcessingOverlay(t: t),
            if (!_processing)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundIconButton(
                      icon: Icons.photo_library_rounded,
                      label: t('gallery'),
                      onTap: () => _pick(ImageSource.gallery),
                    ),
                    GestureDetector(
                      onTap: () => _pick(kIsWeb ? ImageSource.gallery : ImageSource.camera),
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.emerald, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdrop() {
    if (_captured == null) {
      return Container(color: const Color(0xFF10131C));
    }
    if (kIsWeb) {
      return Image.network(_captured!.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Image.file(File(_captured!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
  }
}

class _Viewfinder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: CustomPaint(painter: _CornerBracketsPainter()),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 28.0;
    final w = size.width;
    final h = size.height;

    void corner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, paint);
      canvas.drawLine(origin, origin + dy, paint);
    }

    corner(const Offset(0, 0), const Offset(len, 0), const Offset(0, len));
    corner(Offset(w, 0), const Offset(-len, 0), const Offset(0, len));
    corner(Offset(0, h), const Offset(len, 0), const Offset(0, -len));
    corner(Offset(w, h), const Offset(-len, 0), const Offset(0, -len));
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) => false;
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption(Colors.white70)),
        ],
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  final String Function(String) t;
  const _ProcessingOverlay({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(color: AppColors.emerald, strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            Text('Summarizing Document...', style: AppTextStyles.body(Colors.white, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(t('clause_identified'), style: AppTextStyles.caption(Colors.white60)),
          ],
        ),
      ),
    );
  }
}
