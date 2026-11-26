function key(value) {
  return typeof value === 'string'
    ? value.trim().toLowerCase().replace(/[\s-]+/g, '_')
    : '';
}

function projectMapReport(report) {
  if (!report || !['gps', 'manual'].includes(report.locationSource)) {
    return null;
  }

  const { latitude, longitude } = report.location ?? {};
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
      !Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
    return null;
  }

  const issueClass = key(report.issueClass);
  const severity = key(report.severity);
  const rawStatus = key(report.reportStatus ?? report.status);
  const reportStatus = {
    pending: 'pending',
    in_progress: 'in_progress',
    inprogress: 'in_progress',
    resolved: 'resolved',
    completed: 'resolved',
    done: 'resolved',
    'قيد_الانتظار': 'pending',
    'قيد_التنفيذ_من_الجهة_المختصة': 'in_progress',
    'تم_الحل': 'resolved',
  };
  const status = Object.hasOwn(reportStatus, rawStatus)
    ? reportStatus[rawStatus]
    : null;

  return {
    latitude,
    longitude,
    issueClass: ['surface_damage', 'curb_ramp_issue'].includes(issueClass)
      ? issueClass
      : null,
    severity: severity === 'high' || severity === 'severe'
      ? 'high'
      : ['low_medium', 'non_severe', 'not_severe', 'low', 'medium'].includes(severity)
        ? 'low_medium'
        : null,
    reportStatus: status,
    detectionCount: Number.isInteger(report.detectionCount) && report.detectionCount >= 0
      ? report.detectionCount
      : null,
  };
}

async function syncMapReport(db, reportId) {
  const reportRef = db.collection('reports').doc(reportId);
  const mapRef = db.collection('mapReports').doc(reportId);

  return db.runTransaction(async (transaction) => {
    // Read the current document so delayed events cannot restore old data.
    const report = await transaction.get(reportRef);
    const marker = projectMapReport(report.data());

    if (marker === null) {
      transaction.delete(mapRef);
    } else {
      transaction.set(mapRef, marker);
    }
  });
}

module.exports = { projectMapReport, syncMapReport };
