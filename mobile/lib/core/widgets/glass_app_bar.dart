import 'dart:ui';

import 'package:coopsol_mobile/core/theme/glass_tokens.dart';
import 'package:coopsol_mobile/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({super.key, this.actions});

  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      title: const BrandMark(),
      actions: actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.cardBackground,
              border: Border(bottom: BorderSide(color: tokens.cardBorder))
            ),
          ),
        ),
      ),
    );
  }
}
