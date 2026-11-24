const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineString } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { completedFields, failedFields } = require('./analysis');
const { predict } = require('./api_client');

initializeApp();
const db = getFirestore();

// Base URL of the AI Inference Service, e.g. https://xxxx.ngrok-free.app
// Set in functions-analysis/.env as KHOTA_API_URL.
const apiUrl = defineString('KHOTA_API_URL');

const ATTEMPTS = 3;
const WAIT_MS = [0, 5000, 15000];
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function analyseReport(reportId) {
  const ref = db.collection('reports').doc(reportId);
  const snap = await ref.get();
  const report = snap.data();
  if (!report || report.analysisStatus !== 'processing' || typeof report.imageUrl !== 'string') {
    return;
  }

  const [bytes] = await getStorage().bucket().file(report.imageUrl).download();

  let fields;
  for (let attempt = 0; attempt < ATTEMPTS; attempt += 1) {
    await sleep(WAIT_MS[attempt]);
    try {
      const response = await predict(apiUrl.value(), bytes, `${reportId}.jpg`);
      fields = completedFields(response);
      logger.info('analysis completed', {
        reportId,
        detections: fields.detectionCount,
        modelVersion: response.model_version,
        processingMs: response.processing_ms,
      });
      break;
    } catch (error) {
      logger.warn('analysis attempt failed', { reportId, attempt: attempt + 1, error: error.message });
      fields = failedFields(`AI service error: ${error.message}`);
      if (error.retry === false) break;
    }
  }

  // Write only if the report is still waiting, so a late or repeated run
  // cannot overwrite a newer result.
  await db.runTransaction(async (tx) => {
    const current = await tx.get(ref);
    if (current.get('analysisStatus') !== 'processing') return;
    tx.update(ref, { ...fields, updatedAt: FieldValue.serverTimestamp() });
  });
}

exports.analyseKhotaReport = onDocumentCreated(
  { document: 'reports/{reportId}', timeoutSeconds: 540, memory: '512MiB', retry: false },
  (event) => analyseReport(event.params.reportId),
);
