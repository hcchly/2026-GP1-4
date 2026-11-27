
import 'package:flutter/material.dart';

import '../../theme/khota_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/brand_surface.dart';
import '../../widgets/info_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bodyStyle = text.bodyLarge?.copyWith(
      color: context.khota.muted(0.76),
      height: 1.65,
    );

    return Scaffold(
      appBar: const GradientAppBar(title: 'عن خُطى'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          const BrandIntro(
            title: 'خُطى',
            description: 'أرصفة أفضل تبدأ بخطوة',
            icon: Icons.directions_walk_rounded,
          ),
          const SizedBox(height: 12),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خطوة أقرب لمدينة تمشي',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'خُطى يساعد سكان الرياض على الإبلاغ عن تضرّر الأرصفة '
                  'ومنحدراتها ومتابعة حالة بلاغاتهم.',
                  style: bodyStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'مشروع تخرج · جامعة الملك سعود',
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الإصدار ١٫٠٫٠',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              color: context.khota.muted(0.62),
            ),
          ),
        ],
      ),
    );
  }
}
