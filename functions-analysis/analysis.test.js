const test = require('node:test');
const assert = require('node:assert/strict');
const { toDetections, summaryOf, completedFields, failedFields } = require('./analysis');

const response = {
  model_version: 'v1-2026-11-21',
  result: 'Defects found',
  defects: [
    { box_xywhn: [0.5, 0.5, 0.2, 0.4], class: 'Surface Damage', confidence: 0.81, severity_label: 'LM' },
    { box_xywhn: [0.2, 0.7, 0.1, 0.2], class: 'Curb Ramp Issue', confidence: 0.42, severity_label: 'HIGH' },
    { box_xywhn: [0.8, 0.3, 0.1, 0.1], class: 'Surface Damage', confidence: 0.30, severity_label: 'HIGH' },
  ],
};

test('one detection per defect, highest confidence first, box as top-left + size', () => {
  const d = toDetections(response);
  assert.equal(d.length, 3);
  assert.deepEqual(d[0], {
    boxIndex: 0, issueClass: 'surface_damage', severity: 'low_medium', confidence: 0.81,
    box: { x: 0.4, y: 0.3, w: 0.2, h: 0.4 },
  });
  assert.equal(d[1].issueClass, 'curb_ramp_issue');
  assert.equal(d[1].severity, 'high');
  assert.deepEqual(d.map((x) => x.boxIndex), [0, 1, 2]);
});

test('summary is the most severe detection, ties by confidence', () => {
  assert.deepEqual(summaryOf(toDetections(response)), { issueClass: 'curb_ramp_issue', severity: 'high' });
});

test('no defects: completed with empty list and null summary', () => {
  assert.deepEqual(completedFields({ result: 'No Target Defect', defects: [] }), {
    analysisStatus: 'completed', analysisReason: null, detections: [], detectionCount: 0,
    issueClass: null, severity: null,
  });
});

test('unknown classes or bad boxes are skipped', () => {
  const d = toDetections({ defects: [{ class: 'Pothole', box_xywhn: [0.5, 0.5, 0.1, 0.1], confidence: 0.9, severity_label: 'LM' },
    { class: 'Surface Damage', box_xywhn: [0.5], confidence: 0.9, severity_label: 'LM' }] });
  assert.equal(d.length, 0);
});

test('failed fields', () => {
  assert.deepEqual(failedFields('timeout'), { analysisStatus: 'failed', analysisReason: 'timeout' });
});
