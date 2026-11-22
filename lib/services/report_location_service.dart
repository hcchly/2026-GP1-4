
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/report_location.dart';
import '../widgets/gradient_app_bar.dart';

abstract class ReportLocationProvider {
  Future<ReportLocation?> currentLocation();

  Future<ReportLocation?> pickManually(
    BuildContext context,
    ReportLocation? initial,
  );

  Widget? buildMap(
    BuildContext context,
    ReportLocation? location,
  );

  Future<String?> addressFor(ReportLocation location);
}

class TemporaryReportLocationProvider
    implements ReportLocationProvider {
  const TemporaryReportLocationProvider();

  @override
  Future<ReportLocation?> currentLocation() async {
    return const ReportLocation(
      latitude: 24.7136,
      longitude: 46.6753,
      source: ReportLocation.sourceTemporary,
    );
  }

  @override
  Future<ReportLocation?> pickManually(
    BuildContext context,
    ReportLocation? initial,
  ) async => null;

  @override
  Widget? buildMap(
    BuildContext context,
    ReportLocation? location,
  ) => null;

  @override
  Future<String?> addressFor(
    ReportLocation location,
  ) async => null;
}

class GpsReportLocationProvider
    implements ReportLocationProvider {
  const GpsReportLocationProvider();

  static const _riyadh = LatLng(24.7136, 46.6753);

  @override
  Future<ReportLocation?> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint(
        '[Khota location] Location service disabled.',
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      debugPrint(
        '[Khota location] Permission: ${permission.name}',
      );
      return null;
    }

    Position position;

    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      if (kIsWeb ||
          defaultTargetPlatform != TargetPlatform.android) {
        rethrow;
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          forceLocationManager: true,
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        ),
      );
    }

    return ReportLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      source: ReportLocation.sourceGps,
      accuracyMeters: position.accuracy,
    );
  }

  @override
  Future<ReportLocation?> pickManually(
    BuildContext context,
    ReportLocation? initial,
  ) {
    return Navigator.of(context).push<ReportLocation>(
      MaterialPageRoute<ReportLocation>(
        builder: (_) => _ReportLocationPicker(
          center: initial == null
              ? _riyadh
              : LatLng(
                  initial.latitude,
                  initial.longitude,
                ),
          zoom: initial == null ? 12.0 : 17.0,
          hasInitialLocation: initial != null,
        ),
      ),
    );
  }

  @override
  Widget buildMap(
    BuildContext context,
    ReportLocation? location,
  ) {
    final point = location == null
        ? null
        : LatLng(
            location.latitude,
            location.longitude,
          );

    return _ReportMap(
      key: ValueKey(
        (location?.latitude, location?.longitude),
      ),
      center: point ?? _riyadh,
      zoom: point == null ? 12.0 : 17.0,
      point: point,
    );
  }

  @override
  Future<String?> addressFor(
    ReportLocation location,
  ) {
    return lookupAddress(
      location.latitude,
      location.longitude,
    );
  }

  static final Map<String, String?> _addressCache = {};

  static Future<String?> lookupAddress(
    double latitude,
    double longitude,
  ) async {
    if (kIsWeb) return null;

    final key =
        '${latitude.toStringAsFixed(5)},'
        '${longitude.toStringAsFixed(5)}';

    if (_addressCache.containsKey(key)) {
      return _addressCache[key];
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'jsonv2',
          'lat': '$latitude',
          'lon': '$longitude',
          'zoom': '17',
          'addressdetails': '1',
          'accept-language': 'ar',
        },
      );

      final request = await client.getUrl(uri);

      request.headers.set(
        HttpHeaders.userAgentHeader,
        'KhotaApp/1.0 (KSU)',
      );

      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode != 200) return null;

      final body = await response
          .transform(utf8.decoder)
          .join();

      final data = jsonDecode(body);

      final address =
          data is Map ? data['address'] : null;

      final result = address is Map
          ? formatAddress(address)
          : null;

      _addressCache[key] = result;
      return result;
    } catch (error) {
      debugPrint(
        '[Khota location] Address lookup failed: $error',
      );
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static String? formatAddress(
    Map<dynamic, dynamic> address,
  ) {
    String? part(List<String> keys) {
      for (final key in keys) {
        final value = address[key];

        if (value is String &&
            value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return null;
    }

    var district = part([
      'neighbourhood',
      'suburb',
      'quarter',
      'city_district',
    ]);

    if (district != null &&
        !district.startsWith('حي')) {
      district = 'حي $district';
    }

    final street = part([
      'road',
      'pedestrian',
      'footway',
    ]);

    final parts = [
      ?district,
      ?street,
    ];

    if (parts.isEmpty) {
      return part([
        'city',
        'town',
        'village',
      ]);
    }

    return parts.join('، ');
  }
}

// Manual location selection screen.
class _ReportLocationPicker extends StatefulWidget {
  const _ReportLocationPicker({
    required this.center,
    required this.zoom,
    required this.hasInitialLocation,
  });

  final LatLng center;
  final double zoom;
  final bool hasInitialLocation;

  @override
  State<_ReportLocationPicker> createState() =>
      _ReportLocationPickerState();
}

class _ReportLocationPickerState
    extends State<_ReportLocationPicker> {
  late LatLng _selectedPoint;
  bool _hasMoved = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.center;
  }

  void _onPositionChanged(
    MapCamera camera,
    bool hasGesture,
  ) {
    if (!hasGesture) return;

    _selectedPoint = camera.center;

    if (!_hasMoved && mounted) {
      setState(() {
        _hasMoved = true;
      });
    }
  }

  void _confirm() {
    if (!_hasMoved &&
        !widget.hasInitialLocation) {
      return;
    }

    Navigator.of(context).pop(
      ReportLocation(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        source: ReportLocation.sourceManual,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final canConfirm =
        _hasMoved || widget.hasInitialLocation;

    return Scaffold(
      appBar: const GradientAppBar(
        title: 'تحديد الموقع يدوياً',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'حرّك الخريطة حتى تصبح العلامة فوق موقع المشكلة، ثم أكّد الموقع.',
                textAlign: TextAlign.center,
              ),
            ),

            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: widget.center,
                      initialZoom: widget.zoom,
                      maxZoom: 19,
                      interactionOptions:
                          const InteractionOptions(
                        flags: InteractiveFlag.all &
                            ~InteractiveFlag.rotate,
                      ),
                      onPositionChanged:
                          _onPositionChanged,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'sa.edu.ksu.khota_app',
                        maxNativeZoom: 19,
                      ),
                    ],
                  ),

                  IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -25),
                        child: Icon(
                          Icons.location_on,
                          size: 50,
                          color: colors.primary,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  PositionedDirectional(
                    bottom: 4,
                    end: 4,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: colors.surface,
                        foregroundColor: colors.onSurface,
                      ),
                      onPressed: () async {
                        await launchUrl(
                          Uri.https(
                            'www.openstreetmap.org',
                            '/copyright',
                          ),
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
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    canConfirm
                        ? 'الموقع جاهز للتأكيد'
                        : 'حرّك الخريطة لتحديد الموقع',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          canConfirm ? _confirm : null,
                      child: const Text('تأكيد الموقع'),
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

// Read-only report map.
class _ReportMap extends StatelessWidget {
  const _ReportMap({
    super.key,
    required this.center,
    required this.zoom,
    required this.point,
  });

  final LatLng center;
  final double zoom;
  final LatLng? point;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            maxZoom: 19,
            interactionOptions:
                const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'sa.edu.ksu.khota_app',
              maxNativeZoom: 19,
            ),

            if (point != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: point!,
                    width: 34,
                    height: 34,
                    child: Icon(
                      Icons.location_on,
                      color: colors.primary,
                      size: 34,
                    ),
                  ),
                ],
              ),
          ],
        ),

        PositionedDirectional(
          bottom: 2,
          end: 4,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colors.surface,
              foregroundColor: colors.onSurface,
              minimumSize: const Size(0, 26),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6),
            ),
            onPressed: () async {
              await launchUrl(
                Uri.https(
                  'www.openstreetmap.org',
                  '/copyright',
                ),
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
  }
}
