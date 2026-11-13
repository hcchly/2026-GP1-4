import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

typedef MapReport = ({
  String id,
  LatLng point,
  Object? issueClass,
  Object? severity,
  Object? reportStatus,
});

/// Reads the limited report information published for the public map.
class ReportMapService {
  ReportMapService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<MapReport>> watchInBounds({
    required double south,
    required double north,
    required double west,
    required double east,
  }) {
    return _firestore
        .collection('mapReports')
        .where('latitude', isGreaterThanOrEqualTo: south)
        .where('latitude', isLessThanOrEqualTo: north)
        .where('longitude', isGreaterThanOrEqualTo: west)
        .where('longitude', isLessThanOrEqualTo: east)
        .orderBy('latitude')
        .orderBy('longitude')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_readMarker).whereType<MapReport>().toList(),
        );
  }

  static MapReport? _readMarker(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    if (latitude is! num ||
        longitude is! num ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return (
      id: doc.id,
      point: LatLng(latitude.toDouble(), longitude.toDouble()),
      issueClass: data['issueClass'],
      severity: data['severity'],
      reportStatus: data['reportStatus'],
    );
  }
}
