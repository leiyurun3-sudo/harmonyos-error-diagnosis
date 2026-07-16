'use strict';

const http = require('http');
const crypto = require('crypto');

const port = Number(process.env.PORT || 8787);

function classify(prompt) {
  const text = String(prompt || '').trim();
  const lower = text.toLowerCase();
  if (lower.includes('ohpm') || lower.includes('package') || lower.includes('not found')) {
    return {
      category: 'DEPENDENCY',
      answer: '依赖诊断：核对包名和版本，确认 OHPM registry，再清理缓存与锁文件后重新安装。',
      steps: ['检查 oh-package.json5', '验证 registry 可访问', '重新执行 ohpm install']
    };
  }
  if (lower.includes('arkts') || lower.includes('compile') || lower.includes('类型')) {
    return {
      category: 'ARKTS',
      answer: 'ArkTS 诊断：先修复 CompileArkTS 输出中的第一条类型错误，再处理连锁错误。',
      steps: ['定位第一条错误', '补全明确类型与空值处理', '重新构建并回归']
    };
  }
  if (lower.includes('permission') || lower.includes('权限')) {
    return {
      category: 'PERMISSION',
      answer: '权限诊断：检查 module.json5 声明、运行时授权结果以及拒绝授权后的降级路径。',
      steps: ['核对权限声明', '处理授权结果', '验证拒绝后的可用性']
    };
  }
  if (lower.includes('json') || lower.includes('unexpected token')) {
    return {
      category: 'JSON',
      answer: 'JSON 诊断：先校验语法，再检查字段类型、必填字段和嵌套层级。',
      steps: ['格式化 JSON', '定位首个语法错误', '按接口契约检查字段']
    };
  }
  if (lower.includes('timeout') || lower.includes('network') || lower.includes('网络')) {
    return {
      category: 'NETWORK',
      answer: '网络诊断：确认目标地址、端口转发、超时配置和服务端健康状态。',
      steps: ['请求健康检查接口', '确认端口和代理链路', '记录状态码并重试']
    };
  }
  return {
    category: 'GENERAL',
    answer: '建议按“复现现象、保留首个错误、缩小范围、最小修复、回归验证”的顺序排查。',
    steps: ['补充完整日志', '构造最小复现', '修改并重新验证']
  };
}

function json(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(payload),
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
  });
  res.end(payload);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
      if (Buffer.byteLength(body) > 1024 * 1024) {
        reject(new Error('payload_too_large'));
        req.destroy();
      }
    });
    req.on('end', () => {
      try { resolve(body ? JSON.parse(body) : {}); } catch (error) { reject(error); }
    });
    req.on('error', reject);
  });
}

function validText(value) {
  return typeof value === 'string' && value.trim().length > 0 && value.length <= 100000;
}

const server = http.createServer(async (req, res) => {
  const requestId = crypto.randomUUID();
  const path = new URL(req.url, 'http://127.0.0.1').pathname;
  if (req.method === 'OPTIONS') return json(res, 204, {});
  if (req.method === 'GET' && path === '/health') {
    return json(res, 200, {
      status: 'ok', provider: 'DevAssist Local API', model: 'free-rule-model-v1', requestId
    });
  }
  if (req.method === 'GET' && path === '/api/models') {
    return json(res, 200, {
      models: [{ id: 'free-rule-model-v1', price: 0, capabilities: ['chat', 'agent', 'vision-text'] }], requestId
    });
  }
  if (req.method === 'POST' && (path === '/api/chat' || path === '/api/agent/run')) {
    try {
      const body = await readBody(req);
      if (!validText(body.prompt)) return json(res, 422, { error: 'prompt_required', requestId });
      const result = classify(body.prompt);
      const agent = path.endsWith('/agent/run');
      return json(res, 200, {
        answer: agent ? `Agent 已完成规划与 Skill 调用：${result.answer}` : result.answer,
        provider: agent ? 'DevAssist Local Agent API' : 'DevAssist Local Chat API',
        category: result.category,
        steps: agent ? ['Planner', 'Skill Router', ...result.steps, 'Verifier'] : result.steps,
        requestId
      });
    } catch (error) {
      return json(res, error.message === 'payload_too_large' ? 413 : 400, { error: error.message, requestId });
    }
  }
  if (req.method === 'POST' && path === '/api/vision/analyze') {
    try {
      const body = await readBody(req);
      if (!validText(body.text)) return json(res, 422, { error: 'recognized_text_required', requestId });
      const result = classify(body.text);
      return json(res, 200, {
        answer: result.answer,
        provider: 'Privacy-safe Vision Text API',
        category: result.category,
        steps: result.steps,
        requestId
      });
    } catch (error) {
      return json(res, 400, { error: error.message, requestId });
    }
  }
  return json(res, 404, { error: 'not_found', requestId });
});

if (require.main === module) {
  server.listen(port, '0.0.0.0', () => console.log(`DevAssist API listening on http://0.0.0.0:${port}`));
}

module.exports = { server, classify, validText };
