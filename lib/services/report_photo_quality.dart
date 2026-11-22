
import 'dart:typed_data';
import 'dart:ui' as ui;

class ReportPhotoQualityService {
  const ReportPhotoQualityService();

  Future<List<String>> warnings(Uint8List imageBytes) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;

    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(imageBytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);

      final warnings = <String>[];

      if (descriptor.width < 640 || descriptor.height < 480) {
        warnings.add(
          'دقة الصورة منخفضة. اختاري صورة أكبر وأوضح للرصيف.',
        );
      }

      return warnings;
    } catch (_) {
      return [];
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
