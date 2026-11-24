const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { predict } = require('./api_client');

function server(handler) {
  return new Promise((resolve) => {
    const s = http.createServer(handler).listen(0, () => resolve(s));
  });
}

test('sends the image as multipart field "image" and returns the JSON', async () => {
  let seen = '';
  const s = await server((req, res) => {
    let body = '';
    req.on('data', (c) => { body += c; });
    req.on('end', () => {
      seen = `${req.method} ${req.url} ${req.headers['content-type']} ${req.headers['ngrok-skip-browser-warning']}\n${body}`;
      res.setHeader('content-type', 'application/json');
      res.end(JSON.stringify({ result: 'No Target Defect', defects: [] }));
    });
  });
  const url = `http://127.0.0.1:${s.address().port}/`;
  const out = await predict(url, Buffer.from('fake-image-bytes'), 'r1.jpg');
  s.close();
  assert.deepEqual(out, { result: 'No Target Defect', defects: [] });
  assert.match(seen, /^POST \/predict multipart\/form-data; boundary=.+ true/);
  assert.match(seen, /name="image"; filename="r1.jpg"/);
  assert.match(seen, /fake-image-bytes/);
});

test('400 is not retried, 503 is', async () => {
  for (const [code, retry] of [[400, false], [503, true]]) {
    const s = await server((req, res) => { req.resume(); req.on('end', () => { res.statusCode = code; res.end('nope'); }); });
    await assert.rejects(predict(`http://127.0.0.1:${s.address().port}`, Buffer.from('x'), 'a.jpg'),
      (e) => e.retry === retry && e.message.includes(String(code)));
    s.close();
  }
});
