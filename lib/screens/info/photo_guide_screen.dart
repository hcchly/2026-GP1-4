
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';

/// Photo guide: four swipeable cards with correct and wrong examples.
class PhotoGuideScreen extends StatefulWidget {
  const PhotoGuideScreen({super.key});

  static const _tips = [
    (
      'زاوية التصوير',
      'صوّر الرصيف من زاوية تُظهر الضرر كاملًا.',
      'angle_good.jpg',
      'angle_bad.jpg',
      'زاوية واضحة تُظهر العيب.',
      'زاوية غير مناسبة تخفي العيب.',
    ),
    (
      'المسافة المناسبة',
      'صوّر من مسافة تُظهر المشكلة وتفاصيلها بوضوح.',
      'distance_good.jpg',
      'distance_bad.jpg',
      'مسافة مناسبة تُظهر التفاصيل.',
      'الصورة بعيدة أو قريبة أكثر من اللازم.',
    ),
    (
      'الإضاءة والوضوح',
      'صوّر بإضاءة كافية وثبّت الهاتف لتظهر التفاصيل.',
      'lighting_good.jpg',
      'lighting_bad.jpg',
      'إضاءة جيدة وتفاصيل واضحة.',
      'الإضاءة الضعيفة تخفي المشكلة.',
    ),
    (
      'إظهار المنطقة المحيطة',
      'أظهر المشكلة والرصيف المحيط بها لتوضيح موقع الضرر.',
      'context_good.jpg',
      'context_bad.jpg',
      'المشكلة والمنطقة المحيطة واضحتان.',
      'الصورة لا تُظهر السياق المحيط بالمشكلة.',
    ),
  ];

  @override
  State<PhotoGuideScreen> createState() => _PhotoGuideScreenState();
}

class _PhotoGuideScreenState extends State<PhotoGuideScreen> {
  final _controller = PageController();
  int _page = 0;

  static int get _count => PhotoGuideScreen._tips.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isLast = _page == _count - 1;

    return Scaffold(
      appBar: const GradientAppBar(title: 'دليل التصوير'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'اسحب البطاقات لتتعرّف على $_count قواعد لصورة واضحة.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: context.khota.muted(0.7),
                ),
              ),
            ),

            // Swipeable cards with RTL support.
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _count,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _TipCard(
                    number: i + 1,
                    count: _count,
                    tip: PhotoGuideScreen._tips[i],
                  ),
                ),
              ),
            ),

            _PageDots(count: _count, current: _page),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _page == 0
                        ? null
                        : () => _goTo(_page - 1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('السابق'),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLast
                          ? () => Navigator.of(context).maybePop()
                          : () => _goTo(_page + 1),
                      iconAlignment: IconAlignment.end,
                      icon: Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.chevron_right_rounded,
                      ),
                      label: Text(isLast ? 'فهمت' : 'التالي'),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 18,
                    color: context.khota.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'احمِ خصوصية الآخرين: تجنّب تصوير الوجوه ولوحات السيارات.',
                      style: text.bodySmall,
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

/// One photography rule with correct and wrong examples.
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.number,
    required this.count,
    required this.tip,
  });

  final int number;
  final int count;
  final (String, String, String, String, String, String) tip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      label: 'القاعدة $number من $count',
      child: InfoCard(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.khota.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '$number',
                      style: text.titleSmall?.copyWith(
                        color: context.khota.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      tip.$1,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                tip.$2,
                style: text.bodyMedium,
              ),

              const SizedBox(height: 14),

              _ExampleCard(
                good: true,
                imageName: tip.$3,
                subtitle: tip.$5,
              ),

              const SizedBox(height: 12),

              _ExampleCard(
                good: false,
                imageName: tip.$4,
                subtitle: tip.$6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page position indicators.
class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;

    return Semantics(
      label: 'البطاقة ${current + 1} من $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == current ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == current
                      ? colors.primary
                      : colors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Displays one correct or incorrect photography example.
class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.good,
    required this.imageName,
    required this.subtitle,
  });

  final bool good;
  final String imageName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final color = good
        ? context.khota.primary
        : AppColors.error;

    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            child: Row(
              children: [
                Icon(
                  good
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: color,
                  size: 20,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    good ? 'تصوير صحيح' : 'تصوير خاطئ',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        FractionallySizedBox(
          widthFactor: 0.75,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.asset(
                'assets/images/$imageName',

                fit: BoxFit.cover,
                alignment: switch (imageName) {
                  'angle_good.jpg' => const Alignment(0, 0.55),
                  'distance_good.jpg' => const Alignment(0, 0.30),
                  'context_good.jpg' => const Alignment(0, 0.65),
                  _ => Alignment.center,
                },

                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: context.khota.background,
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'الصورة لم تُضف بعد',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          subtitle,
          style: text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
