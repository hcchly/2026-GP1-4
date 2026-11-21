import 'package:flutter/material.dart';

import '../../theme/khota_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';
import '../../widgets/brand_surface.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'الخصوصية'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          const BrandIntro(
            eyebrow: 'خصوصية ووضوح',
            title: 'بلاغك في أيدٍ أمينة',
            description:
                'نعرض بيانات المشكلة اللازمة على الخريطة، '
                'ونحمي صور بلاغك وبيانات حسابك.',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 12),
          // Feedback 16: plain answers to the questions a citizen asks
          // about their photos, location and data.
          const _SectionTitle('صورك'),
          const _PrivacyItem(
            icon: Icons.visibility_outlined,
            title: 'من يستطيع رؤية صور البلاغ؟',
            body: 'أنت فقط، ومسؤول النظام الذي يراجع البلاغ.',
          ),
          const _PrivacyItem(
            icon: Icons.public_off_outlined,
            title: 'هل تظهر الصور للعامة؟',
            body:
                'لا. لا تظهر صورك على الخريطة ولا لمستخدمي التطبيق الآخرين.',
          ),
          const _PrivacyItem(
            icon: Icons.face_retouching_off_outlined,
            title: 'هل تُخفى الوجوه ولوحات السيارات؟',
            body:
                'لا يخفيها التطبيق تلقائيًا حاليًا، لذلك نرجو تجنّب تصوير '
                'الوجوه ولوحات السيارات قدر الإمكان.',
          ),
          const _PrivacyItem(
            icon: Icons.model_training_outlined,
            title: 'هل تُستخدم صوري لتدريب النموذج؟',
            body:
                'قد نستخدم صور البلاغات لتحسين دقة النموذج مستقبلًا، '
                'بعد مراجعتها من فريق خُطى واستبعاد الصور التي تظهر فيها '
                'وجوه أو لوحات سيارات بوضوح. لا تُربط الصور باسمك أو '
                'بريدك عند التدريب.',
          ),
          const _SectionTitle('الخريطة والموقع'),
          const _PrivacyItem(
            icon: Icons.map_outlined,
            title: 'ماذا يظهر على الخريطة؟',
            body:
                'موقع المشكلة ونوعها ومستوى خطورتها وحالة البلاغ فقط، '
                'دون صورة أو اسم أو وصف.',
          ),
          const _PrivacyItem(
            icon: Icons.location_on_outlined,
            title: 'من يستطيع الوصول للموقع؟',
            body:
                'يظهر موقع البلاغ كنقطة على الخريطة للمستخدمين المسجّلين. '
                'يُستخدم موقعك فقط عند إنشاء البلاغ، ولا نتتبّع موقعك بعد ذلك.',
          ),
          const _SectionTitle('بياناتك'),
          const _PrivacyItem(
            icon: Icons.lock_outline,
            title: 'من يستطيع الوصول لبلاغاتي؟',
            body:
                'أنت ومسؤول النظام فقط. لا يستطيع المستخدمون الآخرون '
                'فتح بلاغك أو رؤية بياناتك.',
          ),
          const _PrivacyItem(
            icon: Icons.verified_user_outlined,
            title: 'موافقتك',
            body:
                'بإنشاء حسابك توافق على هذه السياسة، ومنها استخدام صور '
                'البلاغات لتحسين النموذج. يمكنك طلب استبعاد صورك من '
                'التدريب في أي وقت من فريق خُطى.',
          ),
          const _PrivacyItem(
            icon: Icons.shield_outlined,
            title: 'كيف نحمي بياناتك؟',
            body:
                'تُحفظ الصور والبلاغات في خوادم محمية لا يصل إليها إلا '
                'صاحب البلاغ ومسؤول النظام، وتُفصل الصور عن اسمك وبريدك '
                'قبل أي استخدام للتدريب.',
          ),
          const _PrivacyItem(
            icon: Icons.schedule_outlined,
            title: 'كم تُحفظ البيانات؟',
            body:
                'تُحفظ بلاغاتك وصورها ما دام حسابك قائمًا، '
                'حتى تتمكن من متابعة حالتها.',
          ),
          const _PrivacyItem(
            icon: Icons.delete_outline,
            title: 'هل أستطيع حذف بلاغ أو حسابي؟',
            body:
                'غير متاح من داخل التطبيق في هذا الإصدار، '
                'ويمكنك طلب ذلك من فريق خُطى.',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InfoCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon: icon, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: text.bodyMedium?.copyWith(
                      color: context.khota.muted(0.7),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
