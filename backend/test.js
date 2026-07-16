'use strict';

const assert = require('assert');
const http = require('http');
const { server, classify, validText } = require('./server');

function request(port, method, path, body) {
  return new Promise((resolve, reject) => {
    const payload = body === undefined ? '' : JSON.stringify(body);
    const req = http.request({
      host: '127.0.0.1', port, method, path,
      headers: payload ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) } : {}
    }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body: data ? JSON.parse(data) : {} }));
    });
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function run() {
  assert.match(classify('ohpm package not found').answer, /依赖诊断/);
  assert.match(classify('ArkTS compile error').answer, /ArkTS/);
  assert.match(classify('permission denied').answer, /权限诊断/);
  assert.match(classify('Unexpected token in JSON').answer, /JSON/);
  assert.match(classify('network timeout').answer, /网络诊断/);
  assert.ok(validText('valid prompt'));
  assert.ok(!validText(''));

  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const testPort = server.address().port;
  const health = await request(testPort, 'GET', '/health');
  assert.equal(health.status, 200);
  assert.equal(health.body.status, 'ok');
  const chat = await request(testPort, 'POST', '/api/chat', { prompt: 'ohpm package not found' });
  assert.equal(chat.status, 200);
  assert.match(chat.body.provider, /Chat API/);
  const agent = await request(testPort, 'POST', '/api/agent/run', { prompt: 'ArkTS type error' });
  assert.equal(agent.status, 200);
  assert.ok(agent.body.steps.includes('Verifier'));
  const vision = await request(testPort, 'POST', '/api/vision/analyze', { text: 'permission denied' });
  assert.equal(vision.status, 200);
  assert.equal(vision.body.category, 'PERMISSION');
  const invalid = await request(testPort, 'POST', '/api/chat', { prompt: '' });
  assert.equal(invalid.status, 422);
  const missing = await request(testPort, 'GET', '/missing');
  assert.equal(missing.status, 404);
  await new Promise(resolve => server.close(resolve));
  console.log('backend tests: 13 passed');
}

run().catch(error => {
  console.error(error);
  server.close(() => process.exit(1));
});
