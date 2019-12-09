const nunjucks = require('nunjucks');
const express = require('express');
const WebSocketServer = require('ws').Server;
const http = require('http');
const fs = require('fs');

const app = express();
const server = http.createServer(app).listen(3000, () => {
    console.log('Listening...');
});

app.use('/static', express.static('static'))

nunjucks.configure('views', {
    autoescape: true,
    watch: true,
    express: app
});

app.get('/', function (req, res) {
    res.render('index.html');
});

const wss = new WebSocketServer({
    server: server
});

wss.on('connection', (ws, req) => {
    console.log('creating file');
    var filePath="./static/recording.webm";
    const fileStream = fs.createWriteStream(filePath, { flags: 'w' });
    ws.on('message', message => {
        console.log('writing packet')
        // Only raw blob data can be sent
        fileStream.write(Buffer.from(new Uint8Array(message)));
    });
});

app.use((req, res, next) => {
    console.log('HTTP Request: ' + req.method + ' ' + req.originalUrl);
    return next();
});