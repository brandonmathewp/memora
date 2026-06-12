const http = require('http');
const Database = require('better-sqlite3');
const path = require('path');

const PORT = process.env.PORT || 3000;
const dbPath = process.env.DB_PATH || path.join(__dirname, 'memora.db');

// Init database
const db = new Database(dbPath);
db.pragma('journal_mode = WAL');
db.exec(`
  CREATE TABLE IF NOT EXISTS stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ip TEXT,
    version TEXT,
    created_at INTEGER DEFAULT (strftime('%s','now'))
  );

  CREATE TABLE IF NOT EXISTS announcements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    min_version TEXT,
    created_at INTEGER DEFAULT (strftime('%s','now'))
  );

  CREATE TABLE IF NOT EXISTS feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    email TEXT,
    created_at INTEGER DEFAULT (strftime('%s','now'))
  );
`);

// Parse JSON body
function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        resolve({});
      }
    });
    req.on('error', reject);
  });
}

function sendJSON(res, status, data) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
  });
  res.end(JSON.stringify(data));
}

function getClientIP(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded) return forwarded.split(',')[0].trim();
  return req.socket.remoteAddress || '';
}

const server = http.createServer(async (req, res) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    return res.end();
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  try {
    // POST /v1/stats - report startup event
    if (req.method === 'POST' && url.pathname === '/v1/stats') {
      const body = await parseBody(req);
      const ip = getClientIP(req);
      db.prepare('INSERT INTO stats (ip, version) VALUES (?, ?)').run(ip, body.version || 'unknown');
      return sendJSON(res, 200, { ok: true });
    }

    // GET /v1/announcement - get latest announcement
    if (req.method === 'GET' && url.pathname === '/v1/announcement') {
      const row = db.prepare(
        'SELECT title, content, min_version FROM announcements ORDER BY created_at DESC LIMIT 1'
      ).get();
      if (row) {
        return sendJSON(res, 200, row);
      }
      return sendJSON(res, 200, null);
    }

    // POST /v1/feedback - submit feedback
    if (req.method === 'POST' && url.pathname === '/v1/feedback') {
      const body = await parseBody(req);
      db.prepare('INSERT INTO feedback (content, email) VALUES (?, ?)').run(
        body.content || '',
        body.email || null
      );
      return sendJSON(res, 200, { ok: true });
    }

    // Health check
    if (req.method === 'GET' && url.pathname === '/health') {
      return sendJSON(res, 200, { status: 'ok', uptime: process.uptime() });
    }

    // 404
    sendJSON(res, 404, { error: 'not found' });
  } catch (err) {
    console.error('Error:', err.message);
    sendJSON(res, 500, { error: 'internal server error' });
  }
});

server.listen(PORT, () => {
  console.log(`Memora server running on port ${PORT}`);
});
