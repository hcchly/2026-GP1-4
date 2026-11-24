// Converts the AI Inference Service response (/predict) into the fields
// stored on a report: detections, detectionCount, issueClass, severity.

const ISSUE_CLASSES = {
  'surface damage': 'surface_damage',
  'curb ramp issue': 'curb_ramp_issue',
};

function issueClassOf(defect) {
  return ISSUE_CLASSES[String(defect.class ?? '').trim().toLowerCase()] ?? null;
}

function severityOf(defect) {
  const label = String(defect.severity_label ?? '').trim().toUpperCase();
  if (label === 'HIGH') return 'high';
  if (label === 'LM') return 'low_medium';
  return null;
}

function round(value, digits) {
  const f = 10 ** digits;
  return Math.round(value * f) / f;
}

function clamp01(value) {
  return Math.min(1, Math.max(0, value));
}

// box_xywhn is [x_center, y_center, width, height], normalised to 0..1.
// The report stores the top-left corner and the size, also normalised.
function boxOf(defect) {
  const b = defect.box_xywhn;
  if (!Array.isArray(b) || b.length !== 4 || !b.every(Number.isFinite)) {
    return null;
  }
  const [xc, yc, w, h] = b;
  return {
    x: round(clamp01(xc - w / 2), 4),
    y: round(clamp01(yc - h / 2), 4),
    w: round(clamp01(w), 4),
    h: round(clamp01(h), 4),
  };
}

function toDetections(response) {
  const defects = Array.isArray(response?.defects) ? response.defects : [];
  const detections = [];
  for (const defect of defects) {
    const issueClass = issueClassOf(defect);
    const severity = severityOf(defect);
    const box = boxOf(defect);
    const confidence = Number(defect.confidence);
    if (!issueClass || !severity || !box || !Number.isFinite(confidence)) {
      continue;
    }
    detections.push({ issueClass, severity, confidence: round(confidence, 4), box });
  }
  detections.sort((a, b) => b.confidence - a.confidence);
  return detections.map((d, i) => ({ boxIndex: i, ...d }));
}

// Summary for the report and the map: the most severe detection,
// ties broken by the highest confidence. Null when there are none.
function summaryOf(detections) {
  let best = null;
  for (const d of detections) {
    if (
      best === null ||
      (d.severity === 'high' && best.severity !== 'high') ||
      (d.severity === best.severity && d.confidence > best.confidence)
    ) {
      best = d;
    }
  }
  return best
    ? { issueClass: best.issueClass, severity: best.severity }
    : { issueClass: null, severity: null };
}

function completedFields(response) {
  const detections = toDetections(response);
  return {
    analysisStatus: 'completed',
    analysisReason: null,
    detections,
    detectionCount: detections.length,
    ...summaryOf(detections),
  };
}

function failedFields(reason) {
  return {
    analysisStatus: 'failed',
    analysisReason: String(reason).slice(0, 300),
  };
}

module.exports = { toDetections, summaryOf, completedFields, failedFields };
