// Calls POST /predict on the AI Inference Service (khota/api.py).
const REQUEST_TIMEOUT_MS = 120000;

async function predict(baseUrl, bytes, fileName) {
  const form = new FormData();
  form.append('image', new Blob([bytes]), fileName);
  const res = await fetch(`${baseUrl.replace(/\/+$/, '')}/predict`, {
    method: 'POST',
    body: form,
    // Skips the ngrok free-plan browser warning page.
    headers: { 'ngrok-skip-browser-warning': 'true' },
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    const error = new Error(`AI service returned ${res.status}: ${text.slice(0, 200)}`);
    // 4xx means the image itself was rejected, so retrying will not help.
    error.retry = res.status >= 500;
    throw error;
  }
  return res.json();
}

module.exports = { predict };
