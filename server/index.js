const express = require('express');
const app = express();
const http = require('http');
const https = require('https');
const fs = require('fs');
// const server = require('http').Server(app);
const io = require('socket.io');
const WebSocket = require('ws');
const nunjucks = require('nunjucks');
const room = require('./room');

nunjucks.configure('templates', {
    autoescape: true,
    express: app,
    noCache: true
});

app.use('/static', express.static(__dirname + '/static'))

app.get('/', function (req, res) {
    res.render('index.html')
});

app.get('/expert', function (req, res) {
    res.render('expert.html')
});

app.get('/customer', function (req, res) {
    res.render('customer.html')
});

var clients = new Set()


var url = 'ws://localhost:6437/v7.json';
var socket = new WebSocket(url);
socket.on('message', function (data) {
    clients.forEach(function(s) {
        s.emit('frame', data);
    });
});

socket.on('open', function() {
    console.log('connected to ' + url);
    socket.send(JSON.stringify({enableGestures: false}))
    socket.send(JSON.stringify({background: false}))
    socket.send(JSON.stringify({optimizeHMD: false}))
    socket.send(JSON.stringify({focused: true}))

});
socket.on('close', function(code, reason) { console.log(code, reason) });
socket.on('error', function() { console.log('ws error') });

// setup http server
var privateKey  = fs.readFileSync('ssl/wild.fxpal.net.key', 'utf8');
var certificate = fs.readFileSync('ssl/wild.fxpal.net.bundle.crt', 'utf8');
var credentials = {key: privateKey, cert: certificate};

var httpServer = http.createServer(app);
var httpsServer = https.createServer(credentials, app);

httpServer.listen(5000, '0.0.0.0');
httpsServer.listen(5443, '0.0.0.0');

// socket.io connection
function onConnection(connection) {
    clients.add(connection);
    connection.on('disconnect', function() {
        clients.delete(connection);
    });
}

var httpio = io(httpServer);
var httpsio = io(httpsServer);
httpio.on('connection', onConnection);
httpsio.on('connection', onConnection);

roomio = httpsio.of('/room');
require('./room')(roomio);

console.log('listening to port http 5000, https 5443')
