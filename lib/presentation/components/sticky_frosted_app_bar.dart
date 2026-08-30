import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StickyFrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double height;
  final Widget? bottom;
  final double bottomHeight;

  const StickyFrostedAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.height = 64,
    this.bottom,
    this.bottomHeight = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height + bottomHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCanvas.withValues(alpha: 0.85),
            border: const Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle,
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: height - 1.0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (leading != null) leading! else const SizedBox(width: 4),
                      if (title != null) Expanded(child: title!) else const Spacer(),
                      if (actions != null) Row(mainAxisSize: MainAxisSize.min, children: actions!),
                    ],
                  ),
                ),
                if (bottom != null) bottom!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
