import 'package:flutter/material.dart';

/// Press-scale global: semua area klik dibungkus widget ini.
/// Tekan → mengecil ke [scale] dalam 150ms, lepas → kembali.
/// Menghormati reduced-motion (pengaturan aksesibilitas OS):
/// bila nonaktif animasinya, child tampil tanpa perubahan.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.behavior = HitTestBehavior.deferToChild,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  /// Perilaku hit-test [GestureDetector]-nya. Default deferToChild supaya area
  /// transparan tidak ikut kena; set [HitTestBehavior.opaque] untuk target
  /// penuh (nav bar, dsb).
  final HitTestBehavior behavior;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return GestureDetector(
          behavior: widget.behavior, onTap: widget.onTap, child: widget.child);
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
            behavior: widget.behavior, onTap: widget.onTap, child: widget.child),
      ),
    );
  }
}
