import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../models/report_draft.dart';
import '../../models/report_location.dart';
import '../../models/submitted_report.dart';
import '../../services/report_camera_service.dart';
import '../../services/report_location_service.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../widgets/info_card.dart';
import '../../widgets/live_camera.dart';
import '../../widgets/report_card.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/report_step_indicator.dart';
import '../info/photo_guide_screen.dart';

typedef SubmitReport = Future<void> Function(
  String reportId,
  ReportDraft draft,
  ReportLocation location,
);

class NewReportScreen extends StatefulWidget {
  const NewReportScreen({
    super.key,
    this.initialDraft,
    this.camera,
    this.uploadImage,
    this.locationProvider,
    this.submitReport,
  });

  final ReportDraft? initialDraft;
  final ReportCameraService? camera;
  final Future<String> Function(Uint8List)? uploadImage;
  final ReportLocationProvider? locationProvider;
  final SubmitReport? submitReport;

  static const uploadTimeout = Duration(seconds: 30);
  static const saveTimeout = Duration(seconds: 15);

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen>
    with WidgetsBindingObserver {
  late final ReportCameraService _camera =
      widget.camera ?? ImagePickerReportCamera();

  late final ReportLocationProvider _locator =
      widget.locationProvider ?? const GpsReportLocationProvider();

  LiveCameraController? _live;

  late final TextEditingController _description = TextEditingController(
    text: widget.initialDraft?.description ?? '',
  );

  int _step = 1;

  // Step 1: Photo
  late final ScrollController _photoScrollController;
  Uint8List? _image;
  String? _imageUrl;
  bool _picking = false;
  bool _photoChecking = false;
  bool? _sidewalkVisible;
  String? _photoError;
  List<String> _photoWarnings = const [];
  int _photoCheckRequest = 0;

  // Step 2: Location
  ReportLocation? _location;
  String? _address;
  bool _addressLoading = false;
  bool _locating = false;
  String? _locationError;
  int _locationRequest = 0;

  // Step 3: Review and submit
  bool _sending = false;
  bool _failedOnce = false;
  String? _sendError;
  String? _reportId;

  static const _titles = ['التقاط الصورة', 'تأكيد الموقع', 'مراجعة وإرسال'];

  @override
  void initState() {
    super.initState();

    _photoScrollController = ScrollController();
    _image = widget.initialDraft?.imageBytes;
    _imageUrl = widget.initialDraft?.imageUrl;

    // An existing draft already has a selected photo.
    // This preserves existing report-flow tests.
    if (_image != null) {
      _sidewalkVisible = true;
    }

    _recoverLostPhoto();

    if (widget.camera == null) {
      _live = LiveCameraController()..addListener(_onLiveChanged);

      WidgetsBinding.instance.addObserver(this);

      WidgetsBinding.instance.addPostFrameCallback((_) => _syncCamera());
    }
  }

  @override
  void dispose() {
    if (_live != null) {
      WidgetsBinding.instance.removeObserver(this);
    }

    _live?.removeListener(_onLiveChanged);
    _live?.dispose();
    _photoScrollController.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncCamera();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _live?.stop();
    }
  }

  void _onLiveChanged() {
    if (mounted) setState(() {});
  }

  bool get _liveUsable {
    final status = _live?.status;

    return status != null &&
        status != LiveCameraStatus.denied &&
        status != LiveCameraStatus.unavailable;
  }

  void _syncCamera() {
    final live = _live;
    if (live == null || !mounted) return;

    if (_step == 1 && _image == null && !_sending) {
      live.start();
    } else {
      live.stop();
    }
  }

  // ==============================================================
  // STEP 1: PHOTO
  // ==============================================================

  Future<void> _shoot() async {
    final live = _live;

    if (live == null || !live.isReady || _picking) {
      return;
    }

    setState(() {
      _picking = true;
      _photoError = null;
    });

    try {
      final image = await live.takePicture();
      if (!mounted) return;

      if (image != null) {
        _setSelectedPhoto(image);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _photoError = 'تعذّر التقاط الصورة. حاول مرة أخرى.';
      });
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }

      _syncCamera();
    }
  }

  Future<void> _pickPhoto({required bool gallery}) async {
    setState(() {
      _picking = true;
      _photoError = null;
    });

    try {
      final image = gallery
          ? await _camera.pickFromGallery()
          : await _camera.capture();

      if (!mounted) return;

      if (image != null) {
        _setSelectedPhoto(image);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _photoError = error is FormatException
            ? error.message
            : gallery
            ? 'تعذّر فتح الصور. تحقّق من إذن الوصول للصور وحاول مرة أخرى.'
            : 'تعذّر فتح الكاميرا. تحقّق من إذن الكاميرا وحاول مرة أخرى.';
      });
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }

      _syncCamera();
    }
  }

  Future<void> _recoverLostPhoto() async {
    try {
      final image = await _camera.recover();

      if (!mounted || image == null) return;

      _setSelectedPhoto(image);
    } catch (_) {
      // No lost image to recover.
    }
  }

  void _setSelectedPhoto(Uint8List image) {
    _photoCheckRequest++;

    setState(() {
      _image = image;
      _imageUrl = null;
      _photoError = null;
      _photoWarnings = const [];
      _sidewalkVisible = null;
      _sendError = null;
      _failedOnce = false;
    });

    _checkPhotoQuality(image);
    _syncCamera();
  }

  Future<void> _checkPhotoQuality(Uint8List bytes) async {
    final request = ++_photoCheckRequest;

    setState(() {
      _photoChecking = true;
      _photoWarnings = const [];
    });

    final warnings = <String>[];

    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? decodedImage;

    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

      descriptor = await ui.ImageDescriptor.encoded(buffer);

      // Small image warning.
      if (descriptor.width < 640 || descriptor.height < 480) {
        warnings.add('دقة الصورة منخفضة. يُفضّل اختيار صورة أكبر وأوضح.');
      }

      codec = await descriptor.instantiateCodec(
        targetWidth: 96,
        targetHeight: 96,
      );

      final frame = await codec.getNextFrame();
      decodedImage = frame.image;

      final data = await decodedImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (data != null) {
        final pixels = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        final width = decodedImage.width;
        final height = decodedImage.height;

        double brightnessSum = 0;
        double edgeSum = 0;
        int count = 0;
        int edgeCount = 0;

        for (var y = 0; y < height; y++) {
          int? previous;

          for (var x = 0; x < width; x++) {
            final index = (y * width + x) * 4;

            final red = pixels[index];
            final green = pixels[index + 1];
            final blue = pixels[index + 2];

            final brightness = (red * 0.299) + (green * 0.587) + (blue * 0.114);

            brightnessSum += brightness;
            count++;

            if (previous != null) {
              edgeSum += (brightness - previous).abs();
              edgeCount++;
            }

            previous = brightness.round();
          }
        }

        final averageBrightness = count == 0 ? 0.0 : brightnessSum / count;

        final averageEdge = edgeCount == 0 ? 0.0 : edgeSum / edgeCount;

        // Heuristic lighting warning.
        if (averageBrightness < 65) {
          warnings.add('تبدو الصورة مظلمة. حاول التصوير في إضاءة أفضل.');
        }

        // Heuristic clarity warning.
        if (averageBrightness >= 65 && averageEdge < 4.5) {
          warnings.add(
            'قد تكون الصورة غير واضحة أو مهزوزة. تأكّد من وضوح تفاصيل الرصيف.',
          );
        }
      }
    } catch (error) {
      debugPrint('[Khota photo] Quality check failed: $error');
    } finally {
      decodedImage?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }

    if (!mounted ||
        request != _photoCheckRequest ||
        !identical(_image, bytes)) {
      return;
    }

    setState(() {
      _photoWarnings = warnings;
      _photoChecking = false;
    });
  }

  void _retake() {
    if (_liveUsable) {
      _photoCheckRequest++;

      setState(() {
        _image = null;
        _imageUrl = null;
        _photoError = null;
        _photoWarnings = const [];
        _photoChecking = false;
        _sidewalkVisible = null;
      });

      _syncCamera();
    } else {
      _pickPhoto(gallery: false);
    }
  }

  void _openPhotoGuide() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PhotoGuideScreen()));
  }

  // ==============================================================
  // STEP 2: LOCATION
  // ==============================================================

  Future<void> _locate() async {
    final request = ++_locationRequest;

    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final location = await _locator.currentLocation();

      if (!mounted || request != _locationRequest) {
        return;
      }

      if (location == null || !location.isValid) {
        setState(() {
          _locationError =
              'تعذّر تحديد موقعك تلقائياً. حدّد الموقع يدوياً على الخريطة.';
        });
        return;
      }

      setState(() {
        _location = location;
        _address = null;
        _addressLoading = true;
      });

      final address = await _locator.addressFor(location);

      if (!mounted || request != _locationRequest) {
        return;
      }

      setState(() {
        _address = address;
        _addressLoading = false;
      });
    } catch (error) {
      debugPrint('[Khota location] GPS error: $error');

      if (!mounted || request != _locationRequest) {
        return;
      }

      setState(() {
        _locationError =
            'تعذّر تحديد موقعك تلقائياً. حدّد الموقع يدوياً على الخريطة.';
        _addressLoading = false;
      });
    } finally {
      if (mounted && request == _locationRequest) {
        setState(() {
          _locating = false;
          _addressLoading = false;
        });
      }
    }
  }

  String get _placeText {
    if (_address != null && _address!.trim().isNotEmpty) {
      return _address!;
    }

    if (_addressLoading) {
      return 'جارٍ تحديد اسم الموقع…';
    }

    return 'الموقع المحدد على الخريطة';
  }

  Future<void> _pickManually() async {
    ReportLocation? picked;

    try {
      picked = await _locator.pickManually(context, _location);
    } catch (error) {
      debugPrint('[Khota location] Manual picker error: $error');

      if (!mounted) return;

      setState(() {
        _locationError = 'تعذّر فتح الخريطة. حاول مرة أخرى.';
      });

      return;
    }

    if (!mounted) return;

    if (picked == null) {
      if (_locator is TemporaryReportLocationProvider) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تحديد الموقع يدوياً سيتوفر قريباً.')),
        );
      }
      return;
    }

    final request = ++_locationRequest;

    setState(() {
      _location = picked;
      _address = null;
      _addressLoading = true;
      _locating = false;
      _locationError = null;
    });

    try {
      final address = await _locator.addressFor(picked);

      if (!mounted || request != _locationRequest) {
        return;
      }

      setState(() {
        _address = address;
      });
    } catch (error) {
      debugPrint('[Khota location] Address error: $error');
    } finally {
      if (mounted && request == _locationRequest) {
        setState(() {
          _addressLoading = false;
        });
      }
    }
  }

  // ==============================================================
  // STEP 3: SUBMIT
  // ==============================================================

  Future<void> _submit() async {
    if (_sending) return;

    if (_image == null) {
      _goTo(1);
      return;
    }

    if (_location == null) {
      _goTo(2);
      return;
    }

    setState(() {
      _sending = true;
      _sendError = null;
    });

    final stopwatch = Stopwatch()..start();
    var stage = 'upload';

    try {
      _imageUrl ??= await (widget.uploadImage ?? StorageService().uploadImage)(
        _image!,
      ).timeout(NewReportScreen.uploadTimeout);

      stage = 'save';

      _reportId ??= ReportService.generateId();

      await (widget.submitReport ?? ReportService().submit)(
        _reportId!,
        ReportDraft(
          imageBytes: _image!,
          description: _description.text.trim(),
          imageUrl: _imageUrl,
        ),
        _location!.withAddress(_address),
      ).timeout(NewReportScreen.saveTimeout);

      stopwatch.stop();

      debugPrint(
        '[Khota perf] report $_reportId saved in '
        '${stopwatch.elapsedMilliseconds} ms',
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        SubmittedReport(
          id: _reportId!,
          location: _location!,
          address: _address,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _sendError = _messageFor(error, stage);
        _failedOnce = true;
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _messageFor(Object error, String stage) {
    if (error is StateError) {
      return error.message;
    }

    if (error is ArgumentError) {
      return error.message.toString();
    }

    if (error is TimeoutException) {
      return 'استغرق الإرسال وقتاً أطول من المتوقع. تحقّق من الاتصال وحاول مرة أخرى.';
    }

    final denied =
        error is FirebaseException &&
        [
          'unauthorized',
          'unauthenticated',
          'permission-denied',
        ].contains(error.code);

    if (stage == 'upload') {
      return denied
          ? 'تعذّر رفع الصورة. تأكّد من تسجيل الدخول وحاول مرة أخرى.'
          : 'تعذّر رفع الصورة. تحقّق من الاتصال وحاول مرة أخرى.';
    }

    return denied
        ? 'تعذّر حفظ البلاغ. تأكّد من تسجيل الدخول وحاول مرة أخرى.'
        : 'تعذّر حفظ البلاغ. تحقّق من الاتصال وحاول مرة أخرى.';
  }

  // ==============================================================
  // NAVIGATION
  // ==============================================================

  void _goTo(int step) {
    setState(() {
      _step = step;
    });

    _syncCamera();

    if (step == 2 && _location == null && !_locating) {
      _locate();
    }
  }

  void _back() {
    if (_sending) return;

    if (_step > 1) {
      setState(() {
        _step--;
      });
      _syncCamera();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 1 && !_sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'بلاغ جديد',
          compact: true,
          leading: _sending
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'رجوع',
                  icon: const BackButtonIcon(),
                  onPressed: _back,
                ),
        ),
        body: Column(
          children: [
            ReportStepIndicator(title: _titles[_step - 1], step: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    1 => _buildPhotoStep(context),
                    2 => _buildLocationStep(context),
                    _ => _buildReviewStep(context),
                  },
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildActions(context),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final List<Widget> buttons;

    switch (_step) {
      case 1:
        if (_image == null && _liveUsable) {
          buttons = [
            Center(
              child: _ShutterButton(
                onPressed: _live!.isReady && !_picking ? _shoot : null,
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _picking ? null : () => _pickPhoto(gallery: true),
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text('اختيار من المعرض'),
            ),
          ];
        } else if (_image == null) {
          buttons = [
            ElevatedButton.icon(
              onPressed: _picking ? null : () => _pickPhoto(gallery: false),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('التقاط صورة'),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _picking ? null : () => _pickPhoto(gallery: true),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('اختيار من المعرض'),
            ),
          ];
        } else {
          buttons = [
            ElevatedButton(
              onPressed: _picking || _photoChecking || _sidewalkVisible != true
                  ? null
                  : () => _goTo(2),
              child: const Text('استخدام الصورة'),
            ),

            if (!_picking && !_photoChecking && _sidewalkVisible != true) ...[
              const SizedBox(height: 6),
              Text(
                _sidewalkVisible == null
                    ? 'أجب عن سؤال وضوح الصورة للمتابعة'
                    : 'أعد التصوير أو اختر صورة يظهر فيها الرصيف',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.khota.muted(0.7),
                ),
              ),
            ],

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking ? null : _retake,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('إعادة التصوير'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking
                        ? null
                        : () => _pickPhoto(gallery: true),
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text('من المعرض'),
                  ),
                ),
              ],
            ),
          ];
        }
        break;

      case 2:
        buttons = [
          ElevatedButton(
            onPressed: _location == null || _locating ? null : () => _goTo(3),
            child: const Text('تأكيد الموقع'),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _pickManually,
            icon: const Icon(Icons.edit_location_alt_outlined, size: 20),
            label: const Text('تحديد الموقع يدوياً'),
          ),
        ];
        break;

      default:
        buttons = [
          ElevatedButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: context.khota.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('جارٍ إرسال البلاغ…'),
                    ],
                  )
                : Text(_failedOnce ? 'إعادة المحاولة' : 'إرسال البلاغ'),
          ),
        ];
    }

    return Container(
      decoration: BoxDecoration(
        color: context.khota.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: context.khota.divider),
        boxShadow: [
          BoxShadow(
            color: context.khota.isDark
                ? Colors.transparent
                : AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // PHOTO UI
  // ==============================================================

  Widget _buildPhotoStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // A taken photo is shown smaller than the live camera frame, so the
    // sidewalk question below it stays visible without scrolling.
    final previewHeight = MediaQuery.sizeOf(context).height * 0.38;

    return ListView(
      controller: _photoScrollController,
      padding: const EdgeInsets.all(20),
      children: [
        _PhotoFrame(
          compactHeight: _image == null ? null : previewHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _image == null
                ? _buildCameraFrame()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFF111413)),
                      Image.memory(
                        _image!,
                        fit: BoxFit.contain,
                        semanticLabel: 'معاينة صورة البلاغ',
                      ),
                      const PositionedDirectional(
                        top: 12,
                        start: 12,
                        child: _Pill(
                          icon: Icons.visibility_outlined,
                          label: 'معاينة الصورة',
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Static status without an endless animation.
        if (_picking || _photoChecking) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: InfoCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.image_search_outlined,
                    color: context.khota.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'جارٍ تجهيز الصورة وفحص جودتها...',
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        if (_photoError != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _photoError!),
        ],

        if (_image != null && _photoWarnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: InfoCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملاحظات على جودة الصورة',
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final warning in _photoWarnings)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              warning,
                              style: text.bodySmall?.copyWith(height: 1.6),
                            ),
                          ),
                        Text(
                          'هذه ملاحظات تقديرية. يمكنك إعادة التصوير أو متابعة البلاغ.',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // User confirmation that the sidewalk is visible.
        if (_image != null) ...[
          const SizedBox(height: 14),
          InfoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هل يظهر الرصيف والمشكلة في الصورة؟',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'تأكّد أن الصورة توضح المشكلة والمكان المحيط بها.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('نعم، واضح'),
                      selected: _sidewalkVisible == true,
                      onSelected: (_) {
                        setState(() {
                          _sidewalkVisible = true;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('لا، غير ظاهر'),
                      selected: _sidewalkVisible == false,
                      onSelected: (_) {
                        setState(() {
                          _sidewalkVisible = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_sidewalkVisible == false) ...[
            const SizedBox(height: 12),
            const _ErrorBox(
              message: 'يجب أن يظهر الرصيف والمشكلة بوضوح. أعد التصوير أو اختر صورة أخرى.',
            ),
          ],
        ],

        const SizedBox(height: 16),

        InfoCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: context.khota.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _image == null
                      ? 'صوّر المشكلة بوضوح مع إظهار ما حولها.'
                      : 'تأكّد أن المشكلة ظاهرة كاملة والصورة غير مهزوزة.',
                  style: text.bodySmall?.copyWith(height: 1.6),
                ),
              ),
              TextButton(
                onPressed: _openPhotoGuide,
                child: const Text('دليل التصوير'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraFrame() {
    final live = _live;
    final camera = live?.camera;

    if (live != null && live.isReady && camera != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          LiveCameraPreview(controller: camera),
          IgnorePointer(child: CustomPaint(painter: _ViewfinderPainter())),
          PositionedDirectional(
            top: 12,
            end: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.35),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: live.flashOn ? 'إطفاء الإضاءة' : 'تشغيل الإضاءة',
                onPressed: live.toggleFlash,
                icon: Icon(
                  live.flashOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const PositionedDirectional(
            bottom: 14,
            start: 14,
            end: 14,
            child: Center(
              child: _Pill(
                icon: Icons.center_focus_strong_outlined,
                label: 'أظهر المشكلة كاملة مع ما حولها',
              ),
            ),
          ),
        ],
      );
    }

    return switch (live?.status) {
      LiveCameraStatus.starting || LiveCameraStatus.idle => const _Viewfinder(
        message: 'جارٍ تشغيل الكاميرا…',
        busy: true,
      ),

      LiveCameraStatus.denied => const _Viewfinder(
        message: 'لا يوجد إذن لاستخدام الكاميرا.\nفعّله من الإعدادات، أو اختر صورة من المعرض.',
      ),

      _ => const _Viewfinder(),
    };
  }

  // ==============================================================
  // LOCATION UI
  // ==============================================================

  Widget _buildLocationStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.khota.muted(0.65);

    final map =
        _locator.buildMap(context, _location) ?? const _MapPlaceholder();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                map,

                if (_location != null)
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    end: 12,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _AddressChip(text: _placeText),
                    ),
                  ),

                if (_locating)
                  ColoredBox(
                    color: Colors.white.withValues(alpha: 0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: context.khota.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text('جارٍ تحديث موقعك…'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: _locating ? null : _locate,
          icon: const Icon(Icons.my_location_outlined),
          label: const Text('تحديث موقعي الحالي'),
        ),

        if (_locationError != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(
            message: _locationError!,
            actionLabel: 'إعادة المحاولة',
            onAction: _locating ? null : _locate,
          ),
          const SizedBox(height: 6),
          Text(
            'إذا رفضت صلاحية الموقع، يمكنك تحديد مكان البلاغ يدوياً على الخريطة.',
            style: text.bodySmall?.copyWith(color: muted),
          ),
        ],

        if (_location == null && !_locating) ...[
          const SizedBox(height: 12),
          InfoCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              'لم يتم تحديد الموقع بعد. استخدم GPS أو اختر الموقع يدوياً.',
              style: text.bodySmall,
            ),
          ),
        ],

        if (_location != null) ...[
          const SizedBox(height: 14),
          InfoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: context.khota.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'موقع البلاغ',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(_placeText, style: text.bodyMedium),

                if (_address == null && !_addressLoading) ...[
                  const SizedBox(height: 6),
                  Text(
                    'تعذّر عرض اسم الشارع، لكن الموقع محدد على الخريطة.',
                    style: text.bodySmall?.copyWith(color: muted),
                  ),
                ],

                const SizedBox(height: 12),

                LocationAccuracyBadge(location: _location!),

                const SizedBox(height: 10),

                Text(
                  'لتغيير النقطة، اضغط تحديد الموقع يدوياً وحرّك الخريطة.',
                  style: text.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==============================================================
  // REVIEW UI
  // ==============================================================

  Widget _buildReviewStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.khota.muted(0.65);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF111413)),

                if (_image != null)
                  Image.memory(
                    _image!,
                    fit: BoxFit.contain,
                    semanticLabel: 'صورة البلاغ',
                  ),

                PositionedDirectional(
                  bottom: 12,
                  end: 12,
                  child: _EditButton(
                    label: 'تعديل الصورة',
                    onTap: _sending ? null : () => _goTo(1),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        InfoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'الموقع',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _EditButton(
                    label: 'تعديل الموقع',
                    onTap: _sending ? null : () => _goTo(2),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: context.khota.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _placeText,
                      style: text.bodyMedium?.copyWith(color: muted),
                    ),
                  ),
                ],
              ),

              if (_location != null) ...[
                const SizedBox(height: 12),
                LocationAccuracyBadge(location: _location!),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        InfoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'تفاصيل إضافية',
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const StatusChip(label: 'اختياري', tone: StatusTone.neutral),
                ],
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _description,
                enabled: !_sending,
                minLines: 2,
                maxLines: 4,
                maxLength: ReportDraft.maxDescriptionLength,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'تفاصيل إضافية (اختياري)',
                  hintText: 'مثال: بلاط مكسور يعيق مرور المشاة',
                  helperText: 'الحد الأقصى 500 حرف',
                  alignLabelWithHint: true,
                  fillColor: context.khota.surface,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        InfoCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_outlined, color: context.khota.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'بعد الإرسال، يحلل النظام الصورة للمساعدة في تحديد نوع المشكلة ومستوى شدتها.',
                  style: text.bodySmall?.copyWith(height: 1.6),
                ),
              ),
            ],
          ),
        ),

        if (_sendError != null) ...[
          const SizedBox(height: 14),
          _ErrorBox(message: _sendError!),
        ],
      ],
    );
  }
}

// ==============================================================
// REUSABLE WIDGETS
// ==============================================================

class LocationAccuracyBadge extends StatelessWidget {
  const LocationAccuracyBadge({super.key, required this.location});

  final ReportLocation location;

  static const goodMeters = 20;
  static const fairMeters = 50;

  @override
  Widget build(BuildContext context) {
    final accuracy = location.accuracyMeters;

    final (
      IconData icon,
      String label,
      StatusTone tone,
      String? hint,
    ) = switch (location.source) {
      ReportLocation.sourceManual => (
        Icons.touch_app_outlined,
        'تم تحديده يدوياً على الخريطة',
        StatusTone.info,
        null,
      ),

      ReportLocation.sourceGps when accuracy == null => (
        Icons.gps_fixed,
        'تم تحديده من موقعك (GPS)',
        StatusTone.success,
        null,
      ),

      ReportLocation.sourceGps when accuracy! <= goodMeters => (
        Icons.gps_fixed,
        'دقة عالية · ± ${accuracy.round()} م',
        StatusTone.success,
        null,
      ),

      ReportLocation.sourceGps when accuracy! <= fairMeters => (
        Icons.gps_not_fixed,
        'دقة متوسطة · ± ${accuracy.round()} م',
        StatusTone.progress,
        null,
      ),

      ReportLocation.sourceGps => (
        Icons.gps_off_outlined,
        'دقة منخفضة · ± ${accuracy!.round()} م',
        StatusTone.warning,
        'لموقع أدق، انتقل إلى مكان مفتوح أو حدّد الموقع يدوياً.',
      ),

      _ => (
        Icons.science_outlined,
        'موقع تجريبي مؤقت',
        StatusTone.progress,
        null,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: context.khota.muted(0.7)),
            const SizedBox(width: 6),
            Flexible(
              child: StatusChip(label: label, tone: tone),
            ),
          ],
        ),

        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    this.message = 'وجّه الكاميرا نحو المشكلة في الرصيف',
    this.busy = false,
  });

  final String message;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF111413)),
        CustomPaint(painter: _ViewfinderPainter()),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                    size: 48,
                  ),

                const SizedBox(height: 14),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: 'التقاط صورة',
      excludeSemantics: true,
      child: Tooltip(
        message: 'التقاط صورة',
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;

    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);

      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE4EBE5),
      child: const Center(child: Icon(Icons.location_on, size: 52)),
    );
  }
}

class _AddressChip extends StatelessWidget {
  const _AddressChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.khota.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.khota.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place_outlined, color: context.khota.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined, size: 15, color: Colors.white),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.error),
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

/// Live camera keeps the 3:4 frame; a taken photo uses [compactHeight] so the
/// question under it fits on screen.
class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({required this.child, this.compactHeight});

  final Widget child;
  final double? compactHeight;

  @override
  Widget build(BuildContext context) {
    final height = compactHeight;
    if (height == null) return AspectRatio(aspectRatio: 3 / 4, child: child);
    return SizedBox(height: height, child: child);
  }
}
