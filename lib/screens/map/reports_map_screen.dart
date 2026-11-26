import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/report_map_service.dart';
import '../../services/report_location_service.dart';
import '../../theme/khota_colors.dart';
import '../../utils/report_labels.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/report_map_marker.dart';
import '../../widgets/report_explanation_icon.dart';
import '../../widgets/report_status_widgets.dart';

class ReportsMapScreen extends StatefulWidget {
  const ReportsMapScreen({
    super.key,
    this.locationProvider = const GpsReportLocationProvider(),
    this.service,
  });

  final ReportLocationProvider locationProvider;
  final ReportMapService? service;

  @override
  State<ReportsMapScreen> createState() => _ReportsMapScreenState();
}

class _ReportsMapScreenState extends State<ReportsMapScreen> {
  static const _riyadh = LatLng(24.7136, 46.6753);
  static const _initialZoom = 11.0;
  final _controller = MapController();
  String? _selectedReportId;
  LatLng? _myLocation;
  bool _locating = false;
  bool _showLegend = false;
  bool _mapReady = false;

  void _zoom(double change) {
    final camera = _controller.camera;
    _controller.move(camera.center, (camera.zoom + change).clamp(8.0, 19.0));
  }

  void _recenter() {
    _controller.move(_riyadh, _initialZoom);
  }

  Future<void> _locateMe() async {
    if (_locating || !_mapReady) return;
    setState(() => _locating = true);
    try {
      final location = await widget.locationProvider.currentLocation();
      if (!mounted) return;
      if (location == null || !location.isValid) {
        _locationMessage();
        return;
      }
      final point = LatLng(location.latitude, location.longitude);
      setState(() => _myLocation = point);
      _controller.move(point, 16);
    } catch (_) {
      if (mounted) _locationMessage();
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _locationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تعذّر تحديد موقعك. تأكّد من تشغيل الموقع والسماح لخُطى بالوصول إليه، ثم حاول مجددًا.',
        ),
      ),
    );
  }

  Timer? _viewportTimer;
  late final _mapService = widget.service ?? ReportMapService();
  Stream<List<MapReport>>? _markers;

  @override
  void dispose() {
    _viewportTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _loadMarkers(LatLngBounds bounds) {
    final markers = _mapService.watchInBounds(
      south: bounds.south,
      north: bounds.north,
      west: bounds.west,
      east: bounds.east,
    );
    setState(() => _markers = markers);
  }

  void _queueLoad(MapCamera camera, bool _) {
    _viewportTimer?.cancel();
    _viewportTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadMarkers(camera.visibleBounds);
    });
  }

  Future<void> _showReport(MapReport report) async {
    setState(() => _selectedReportId = report.id);
    final issueClass = issueClassLabel(report.issueClass);
    final severity = severityLabel(report.severity);
    final status = switch (report.reportStatus) {
      'pending' => ReportStatusLabels.pending,
      'in_progress' => ReportStatusLabels.inProgress,
      'resolved' => ReportStatusLabels.resolved,
      _ => 'غير متاحة',
    };

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.65,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ملخص البلاغ',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق الملخص',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.report_outlined,
                    color: context.khota.primary,
                  ),
                  title: const Text('نوع المشكلة'),
                  subtitle: Text(issueClass),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.priority_high_rounded,
                    color: context.khota.primary,
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('الشدة'),
                      ReportInfoIcon.severity(value: report.severity),
                    ],
                  ),
                  subtitle: Text(severity),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.assignment_outlined,
                    color: context.khota.primary,
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('حالة البلاغ'),
                      ReportInfoIcon.status(value: report.reportStatus),
                    ],
                  ),
                  subtitle: Text(status),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _selectedReportId = null);
  }

  Marker _marker(MapReport report) {
    return Marker(
      key: ValueKey(report.id),
      point: report.point,
      width: 48,
      height: 48,
      // Coloured by report status; warning icon and red border when severe.
      child: ReportMapMarker(
        reportStatus: report.reportStatus,
        severity: report.severity,
        selected: _selectedReportId == report.id,
        onPressed: () => _showReport(report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'خريطة خُطى', compact: true),
      body: StreamBuilder<List<MapReport>>(
        stream: _markers,
        builder: (context, snapshot) {
          final loading =
              !snapshot.hasError &&
              (_markers == null ||
                  snapshot.connectionState == ConnectionState.waiting);
          final markers = loading || snapshot.hasError
              ? const <Marker>[]
              : (snapshot.data ?? []).map(_marker).toList();

          return Stack(
            fit: StackFit.expand,
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: _riyadh,
                  initialZoom: _initialZoom,
                  minZoom: 8,
                  maxZoom: 19,
                  onMapReady: () {
                    _mapReady = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {});
                        _loadMarkers(_controller.camera.visibleBounds);
                      }
                    });
                  },
                  onPositionChanged: _queueLoad,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'sa.edu.ksu.khota_app',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      ...markers,
                      if (_myLocation != null)
                        Marker(
                          point: _myLocation!,
                          width: 28,
                          height: 28,
                          child: IgnorePointer(
                            child: Tooltip(
                              message: 'موقعك الحالي',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1769AA),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (loading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                )
              else if (snapshot.hasError || markers.isEmpty)
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  end: 12,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: snapshot.hasError
                            ? TextButton(
                                onPressed: () => _loadMarkers(
                                  _controller.camera.visibleBounds,
                                ),
                                child: const Text(
                                  'تعذّر تحميل البلاغات. إعادة المحاولة',
                                ),
                              )
                            : const Text(
                                'لا توجد بلاغات في الجزء الظاهر من الخريطة',
                              ),
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                bottom: 44,
                start: 12,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width - 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showLegend) const ReportMapLegend(),
                      const SizedBox(height: 6),
                      Material(
                        color: context.khota.surface,
                        borderRadius: BorderRadius.circular(14),
                        child: IconButton(
                          tooltip: _showLegend
                              ? 'إخفاء دليل العلامات'
                              : 'دليل العلامات',
                          onPressed: () =>
                              setState(() => _showLegend = !_showLegend),
                          icon: Icon(
                            _showLegend
                                ? Icons.close_rounded
                                : Icons.info_outline_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                end: 12,
                bottom: 44,
                child: _MapTools(
                  onZoomIn: _mapReady ? () => _zoom(1) : null,
                  onZoomOut: _mapReady ? () => _zoom(-1) : null,
                  onLocate: _locating || !_mapReady ? null : _locateMe,
                  onRecenter: _mapReady ? _recenter : null,
                  locating: _locating,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: context.khota.surface,
                    minimumSize: const Size(0, 26),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    await launchUrl(
                      Uri.https('www.openstreetmap.org', '/copyright'),
                    );
                  },
                  child: const Text(
                    '© OpenStreetMap contributors',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapTools extends StatelessWidget {
  const _MapTools({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocate,
    required this.onRecenter,
    required this.locating,
  });

  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onLocate;
  final VoidCallback? onRecenter;
  final bool locating;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    final style = IconButton.styleFrom(
      fixedSize: const Size(48, 48),
      foregroundColor: colors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'تكبير الخريطة',
                  onPressed: onZoomIn,
                  style: style,
                  icon: const Icon(Icons.add_rounded, size: 24),
                ),
                SizedBox(
                  width: 22,
                  child: Divider(
                    height: 1,
                    color: colors.primary.withValues(alpha: 0.14),
                  ),
                ),
                IconButton(
                  tooltip: 'تصغير الخريطة',
                  onPressed: onZoomOut,
                  style: style,
                  icon: const Icon(Icons.remove_rounded, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          IconButton.filled(
            tooltip: 'موقعي',
            onPressed: onLocate,
            style: style.copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.primary,
              ),
              foregroundColor: WidgetStateProperty.all(colors.onPrimary),
            ),
            icon: locating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : const Icon(Icons.my_location_rounded, size: 22),
          ),
          const SizedBox(height: 2),
          IconButton(
            tooltip: 'إعادة التمركز على الرياض',
            onPressed: onRecenter,
            style: style,
            icon: const Icon(Icons.center_focus_strong_rounded, size: 22),
          ),
        ],
      ),
    );
  }
}
