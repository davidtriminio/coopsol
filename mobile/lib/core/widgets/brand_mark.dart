import 'package:coopsol_mobile/core/theme/glass_tokens.dart';
import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const Key('brand-mark'),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.fieldBackground,
            borderRadius: BorderRadius.circular(10)
          ),
          child: Text(
            'CS',
            style: textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(width: 10,),
        Text('CoopSol', style: textTheme.titleMedium)
      ],
    );
  }
}
