const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');

let clients = [];
let activeGroups = new Set(['General']);

function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

const localIp = getLocalIp();
const port = 3000;

const server = http.createServer((req, res) => {
  // CORS setup to allow any local connections
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST');

  if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html')) {
    fs.readFile(path.join(__dirname, 'index.html'), (err, data) => {
      if (err) { res.writeHead(500); return res.end('Error loading index.html'); }
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.end(data);
    });
    return;
  }

  if (req.method === 'GET' && req.url === '/api/config') {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({ ip: localIp, port: port, url: `http://${localIp}:${port}` }));
    return;
  }

  if (req.method === 'GET' && req.url === '/events') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    });
    res.write(`data: ${JSON.stringify({ type: 'groups-updated', groups: Array.from(activeGroups) })}\n\n`);

    const clientId = Date.now() + Math.random();
    clients.push({ id: clientId, res });

    req.on('close', () => {
      clients = clients.filter(c => c.id !== clientId);
    });
    return;
  }

  if (req.method === 'POST' && req.url === '/message') {
    let body = '';
    req.on('data', chunk => {
        body += chunk.toString();
        if (body.length > 50 * 1024 * 1024) req.connection.destroy(); // 50MB file transfer limit
    });
    req.on('end', () => {
        try {
            const data = JSON.parse(body);
            clients.forEach(client => {
                client.res.write(`data: ${JSON.stringify({ type: 'message', message: data })}\n\n`);
            });
            res.writeHead(200); res.end('ok');
        } catch(e) {
            res.writeHead(400); res.end('error');
        }
    });
    return;
  }

  if (req.method === 'POST' && req.url === '/join') {
     let body = '';
     req.on('data', chunk => body += chunk.toString());
     req.on('end', () => {
       try {
           const { group } = JSON.parse(body);
           if (!activeGroups.has(group)) {
               activeGroups.add(group);
               clients.forEach(client => {
                   client.res.write(`data: ${JSON.stringify({ type: 'groups-updated', groups: Array.from(activeGroups) })}\n\n`);
               });
           }
           res.writeHead(200); res.end('ok');
       } catch (e) {}
     });
     return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(port, '0.0.0.0', () => {
   console.log(`\n==========================================`);
   console.log(`🚀 Lumina LAN Messenger Server RUNNING!`);
   console.log(`📱 TO CONNECT PHONES: Open Browser and go to:`);
   console.log(`👉 http://${localIp}:${port}`);
   console.log(`==========================================\n`);
});
