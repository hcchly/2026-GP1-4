import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_user.dart';
import '../../models/citizen_report.dart';
import '../../services/profile_service.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../widgets/coming_soon.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/info_card.dart';
import '../../widgets/report_card.dart';
import '../info/about_screen.dart';
import '../info/photo_guide_screen.dart';
import '../reports/report_details_screen.dart';

/// Home tab.
///
/// A new report is started only from the "بلاغ جديد" button in the centre of
/// the navigation bar, so the home screen does not repeat that action.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    this.service,
    this.reports,
  });

  /// Switches the bottom navigation tab (1 = reports, 2 = map).
  final ValueChanged<int> onOpenTab;
  final ProfileService? service;
  final Stream<List<CitizenReport>>? reports;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProfileService _service =
      widget.service ?? FirestoreProfileService.instance;
  late final Future<AppUser> _profile = _service.getProfile();
  late Stream<List<CitizenReport>>? _reports =
      widget.reports ?? ReportService.watchOwnReports();
  final _servicesController = ScrollController();

  @override
  void dispose() {
    _servicesController.dispose();
    super.dispose();
  }

  void _retryReports() {
    setState(
      () => _reports = widget.reports ?? ReportService.watchOwnReports(),
    );
  }

  Widget _reportCard(CitizenReport report) {
    return ReportSummaryCard(
      key: ValueKey(report.id),
      title: report.description,
      locationText: report.address ?? '',
      latitude: report.latitude,
      longitude: report.longitude,
      dateText: report.dateText,
      reportStatus: report.reportStatus,
      analysisStatus: report.analysisStatus,
      reportNumber: ReportService.displayNumber(report.id),
      imageUrl: report.imageUrl,
      onTap: () => _open(ReportDetailsScreen(report: report)),
    );
  }

  Widget _emptyReports(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.khota.muted(0.65);
    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          const IconTile(icon: Icons.inbox_outlined, size: 56),
          const SizedBox(height: 14),
          Text(
            'لا توجد بلاغات بعد',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'اضغط «بلاغ جديد» في الأسفل لإرسال أول بلاغ، '
            'وستظهر بلاغاتك هنا.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: muted, height: 1.6),
          ),
        ],
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Plain page background under the status bar.
      value: context.khota.pageOverlayStyle,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          GradientHeader(
            bottomRadius: 34,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(22, 16, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<AppUser>(
                    future: _profile,
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.khota.headerBadge,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              user?.initial ?? '',
                              style: text.titleLarge?.copyWith(
                                color: context.khota.onHeaderBadge,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أهلًا بك في خُطى',
                                  style: text.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                Text(
                                  user?.fullName ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'الإشعارات',
                            onPressed: () => showComingSoon(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.notifications_none_rounded),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'أرصفة أفضل\nتبدأ بخطوة',
                    style: text.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'بلّغ عن المشكلة، وتابع أثر خطوتك.',
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Photo guide card.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GuideCard(onTap: () => _open(const PhotoGuideScreen())),
          ),
          const SizedBox(height: 28),

          // Services: one row the user slides through.
          const _SectionTitle('الخدمات'),
          SizedBox(
            height: 118,
            child: ListView(
              key: const ValueKey('home-services'),
              controller: _servicesController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _ServiceTile(
                  icon: Icons.assignment_outlined,
                  label: 'بلاغاتي',
                  onTap: () => widget.onOpenTab(1),
                ),
                _ServiceTile(
                  icon: Icons.directions_walk_rounded,
                  label: 'خريطة خُطى',
                  onTap: () => widget.onOpenTab(2),
                ),
                _ServiceTile(
                  icon: Icons.photo_camera_rounded,
                  label: 'دليل التصوير',
                  onTap: () => _open(const PhotoGuideScreen()),
                ),
                _ServiceTile(
                  icon: Icons.info_rounded,
                  label: 'عن خُطى',
                  onTap: () => _open(const AboutScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(child: _ServiceScrollRail(controller: _servicesController)),
          const SizedBox(height: 24),

          _SectionTitle(
            'آخر البلاغات',
            action: TextButton(
              onPressed: () => widget.onOpenTab(1),
              child: const Text('عرض الكل'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<CitizenReport>>(
              stream: _reports,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return InfoCard(
                    child: Column(
                      children: [
                        const Text(
                          'تعذّر تحميل آخر البلاغات. تحقّق من الاتصال.',
                        ),
                        TextButton.icon(
                          onPressed: _retryReports,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final reports = [...?snapshot.data]
                  ..sort(CitizenReport.newestFirst);
                if (reports.isEmpty) return _emptyReports(context);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final report in reports.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _reportCard(report),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 48), // space above the centre button
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        16,
        0,
        12,
        action == null ? 12 : 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Short tips before taking the photo; opens the photo guide.

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.khota;
    final radius = BorderRadius.circular(18);
    return Material(
      color: colors.isDark
          ? colors.surface
          : Color.alphaBlend(
              AppColors.mint.withValues(alpha: 0.12),
              Colors.white,
            ),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.mint.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  size: 22,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دليل تصوير المشكلة',
                      style: text.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'إرشادات تساعدك على تصوير المشكلة بوضوح.',
                      style: text.bodySmall?.copyWith(
                        color: colors.muted(0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_back_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    final radius = BorderRadius.circular(18);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10, bottom: 6),
      child: Material(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.divider),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            width: 104,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.mint.withValues(
                      alpha: colors.isDark ? 0.18 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: colors.primary, size: 25),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact, draggable scroll track with physical left/right arrow controls.
class _ServiceScrollRail extends StatefulWidget {
  const _ServiceScrollRail({required this.controller});
  final ScrollController controller;

  @override
  State<_ServiceScrollRail> createState() => _ServiceScrollRailState();
}

class _ServiceScrollRailState extends State<_ServiceScrollRail> {
  ScrollPosition? get _position =>
      widget.controller.hasClients &&
          widget.controller.position.hasContentDimensions
      ? widget.controller.position
      : null;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.sizeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _move(bool left) {
    final position = _position;
    if (position == null) return;
    final reverse = position.axisDirection == AxisDirection.left;
    final direction = left == reverse ? 1 : -1;
    widget.controller.animateTo(
      (position.pixels + direction * position.viewportDimension * 0.7).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    final position = _position;
    final extent = position?.maxScrollExtent ?? 0;
    final offset = position?.pixels.clamp(0.0, extent) ?? 0.0;
    final reverse = position?.axisDirection == AxisDirection.left;
    final progress = extent > 0 ? offset / extent : 0.0;
    final fraction = position == null
        ? 0.65
        : (position.viewportDimension / (position.viewportDimension + extent))
              .clamp(0.2, 1.0);
    final canLeft =
        extent > 0 && (reverse ? offset < extent - 0.5 : offset > 0.5);
    final canRight =
        extent > 0 && (reverse ? offset > 0.5 : offset < extent - 0.5);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'تحريك الخدمات لليسار',
            onPressed: canLeft ? () => _move(true) : null,
            iconSize: 18,
            color: colors.primary,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Semantics(
            label: 'شريط تمرير الخدمات',
            child: SizedBox(
              width: 112,
              height: 48,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final travel = constraints.maxWidth * (1 - fraction);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: extent > 0
                        ? (details) {
                            final ratio =
                                (details.localPosition.dx /
                                        constraints.maxWidth)
                                    .clamp(0.0, 1.0);
                            widget.controller.animateTo(
                              (reverse ? 1 - ratio : ratio) * extent,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        : null,
                    onHorizontalDragUpdate: extent > 0 && travel > 0
                        ? (details) {
                            widget.controller.jumpTo(
                              (widget.controller.offset +
                                      details.delta.dx /
                                          travel *
                                          extent *
                                          (reverse ? -1 : 1))
                                  .clamp(0.0, extent),
                            );
                          }
                        : null,
                    child: Center(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Align(
                          alignment: Alignment(
                            (reverse ? 1 - progress : progress) * 2 - 1,
                            0,
                          ),
                          child: FractionallySizedBox(
                            widthFactor: fraction,
                            heightFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'تحريك الخدمات لليمين',
            onPressed: canRight ? () => _move(false) : null,
            iconSize: 18,
            color: colors.primary,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
