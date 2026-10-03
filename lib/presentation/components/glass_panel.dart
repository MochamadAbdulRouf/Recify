import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'pressable.dart';

/// App-level atmospheric backdrop. Without a non-uniform layer behind them,
/// [BackdropFilter] panels read as flat fills — "the glass did nothing".
/// Cheaper than a blur filter: soft radial gradients, no GPU pass.
class MeshBackdrop extends StatelessWidget {
  const MeshBackdrop({super.key, this.intensity = 1.0});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top-centre ellipse glow (verbatim from the Stitch v2 body layer).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1.1),
                  radius: 1.1,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.22 * intensity),
                    AppColors.bgCanvas.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom-left cool counterweight so the nav island has something to blur.
          Positioned(
            left: -80,
            bottom: -60,
            child: _Blob(
              size: 260,
              color: AppColors.meshCyan.withValues(alpha: 0.10 * intensity),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Frosted panel. Recipe from the Stitch v2 HTML:
/// `rounded-[28px] bg-[#151926]/60 backdrop-blur-2xl border border-white/[0.12]`
/// plus an `inset 0 1px 1px rgba(255,255,255,0.15)` top highlight, which has no
/// Flutter equivalent — approximated with a 1px overlay line.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding,
    this.fill,
    this.borderColor,
    this.blur = 16,
    this.glowBlobs = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  /// Defaults to a flat [AppColors.glassFill]; pass a gradient for the hero.
  final Gradient? fill;

  /// Null = ikut tema ([AppColors.glassBorder]).
  final Color? borderColor;
  final double blur;

  /// Two soft accent blobs behind the panel (hero / stat card only).
  final bool glowBlobs;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: fill ??
                  LinearGradient(colors: [AppColors.glassFill, AppColors.glassFill]),
              borderRadius: r,
              border: Border.all(color: borderColor ?? AppColors.glassBorder),
            ),
            child: Stack(
              children: [
                if (glowBlobs) ...[
                  Positioned(
                    top: -48,
                    right: -48,
                    child: _Blob(
                      size: 192,
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  Positioned(
                    bottom: -56,
                    left: -56,
                    child: _Blob(
                      size: 176,
                      color: AppColors.meshCyan.withValues(alpha: 0.15),
                    ),
                  ),
                ],
                // Sheen: from-white/[0.04] to-transparent.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: r,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.glassSheen,
                            AppColors.bgCanvas.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 1px top highlight standing in for the CSS inset shadow.
                Positioned(
                  top: 0,
                  left: radius,
                  right: radius,
                  child: IgnorePointer(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: AppColors.glassHighlight,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented pill used for period tabs:
/// `p-1 bg-surface-container/60 backdrop-blur-md border border-white/10`.
class GlassSegmentedTabs extends StatelessWidget {
  const GlassSegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.activeColor,
    this.activeGlow,
    this.activeTextColor = Colors.white,
    this.inactiveTextColorBuilder,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Warna pill terpilih — default biru ([AppColors.primaryContainer]);
  /// layar mode (expense/income) mengirim merah/hijau.
  final Color? activeColor;
  final Color? activeGlow;
  final Color activeTextColor;
  final Color? Function(int index)? inactiveTextColorBuilder;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: PressableScale(child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: i == index
                            ? (activeColor ?? AppColors.primaryContainer)
                            : null,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: i == index
                            ? [
                                BoxShadow(
                                  color: (activeGlow ?? AppColors.primary)
                                      .withValues(alpha: 0.40),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              i == index ? FontWeight.w600 : FontWeight.w500,
                          color: i == index
                              ? activeTextColor
                              : (inactiveTextColorBuilder?.call(i) ??
                                  AppColors.onSurfaceVariant),
                        ),
                      ),
                    ),
                  )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
