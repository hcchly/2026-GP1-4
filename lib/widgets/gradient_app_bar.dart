import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/khota_colors.dart';
import 'brand_surface.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    required this.title,
    this.compact = true,
    this.navigationDirection,
    this.leading,
  });

  final String title;
  final bool compact;
  final TextDirection? navigationDirection;
  final Widget? leading;

  double get _toolbarHeight => compact ? kToolbarHeight : 64;

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final text = Theme.of(context).textTheme;
    return Directionality(
      textDirection: navigationDirection ?? textDirection,
      child: AppBar(
        toolbarHeight: _toolbarHeight,
        title: Text(title, textDirection: textDirection),
        centerTitle: true,
        leading: leading,
        foregroundColor: Colors.white,
        backgroundColor: context.khota.isDark
            ? context.khota.background
            : AppColors.gradientTop,
        surfaceTintColor: Colors.transparent,
        // Patterned header: always light status bar icons.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: (compact ? text.titleMedium : text.titleLarge)
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        flexibleSpace: const BrandSurface(
          radius: 0,
          padding: EdgeInsets.zero,
          alignment: Alignment.topCenter,
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}
