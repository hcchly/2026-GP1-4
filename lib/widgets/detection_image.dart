import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/report_detection.dart';
import '../services/storage_service.dart';
import '../utils/report_labels.dart';

/// Detection colors follow severity: high red, medium orange, low neutral.
Color detectionColor(ReportDetection detection) =>
    severityColor(detection.severity);

/// The private report image with a numbered box around every detected issue.
/// The whole image is shown (not cropped) so the boxes line up with it.
class DetectionImage extends StatefulWidget {
  const DetectionImage({
    super.key,
    required this.imageRef,
    required this.detections,
    this.maxHeight = 360,
  });

  final String imageRef;
  final List<ReportDetection> detections;
  final double maxHeight;

  @override
  State<DetectionImage> createState() => _DetectionImageState();
}

class _LoadedImage {
  const _LoadedImage(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width;
  final int height;
}

class _DetectionImageState extends State<DetectionImage> {
  late Future<_LoadedImage?> _image;

  @override
  void initState() {
    super.initState();
    _image = _load();
  }

  @override
  void didUpdateWidget(covariant DetectionImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageRef != widget.imageRef) _image = _load();
  }

  Future<_LoadedImage?> _load() async {
    final bytes = await StorageService().downloadImage(widget.imageRef);
    if (bytes == null || bytes.isEmpty) return null;
    // Decoded size (after EXIF rotation), needed to place the boxes.
    final decoded = await decodeImageFromList(bytes);
    final image = _LoadedImage(bytes, decoded.width, decoded.height);
    decoded.dispose();
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LoadedImage?>(
      future: _image,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: widget.maxHeight * 0.6,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final image = snapshot.data;
        if (snapshot.hasError || image == null || image.height == 0) {
          return SizedBox(
            height: widget.maxHeight * 0.6,
            child: const Center(child: Text('تعذّر عرض صورة البلاغ')),
          );
        }
        final aspect = image.width / image.height;
        return LayoutBuilder(
          builder: (context, constraints) {
            var width = constraints.maxWidth;
            var height = width / aspect;
            if (height > widget.maxHeight) {
              height = widget.maxHeight;
              width = height * aspect;
            }
            return Center(
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      image.bytes,
                      fit: BoxFit.fill,
                      semanticLabel: 'صورة البلاغ مع المشكلات المكتشفة',
                    ),
                    CustomPaint(
                      painter: _DetectionPainter(
                        widget.detections,
                        Directionality.of(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DetectionPainter extends CustomPainter {
  _DetectionPainter(this.detections, this.direction);

  final List<ReportDetection> detections;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in detections) {
      final color = detectionColor(d);
      final rect = Rect.fromLTWH(
        d.box.left * size.width,
        d.box.top * size.height,
        d.box.width * size.width,
        d.box.height * size.height,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Number tag in the box's top-left corner, matching the list below.
      final label = TextPainter(
        text: TextSpan(
          text: '${d.boxIndex + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: direction,
      )..layout();
      final tag = Rect.fromLTWH(
        rect.left,
        rect.top - label.height - 4 < 0 ? 0.0 : rect.top - label.height - 4,
        label.width + 8,
        label.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tag, const Radius.circular(4)),
        Paint()..color = color,
      );
      label.paint(canvas, Offset(tag.left + 4, tag.top + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter old) =>
      old.detections != detections || old.direction != direction;
}
