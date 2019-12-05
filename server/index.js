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
const util = require('./util');

const db = require('./db')

nunjucks.configure('templates', {
    autoescape: true,
    express: app,
    noCache: true
});

app.use('/static', express.static(__dirname + '/static'))

app.get('/', function (req, res) {
    var roomid = util.generateRandomRoomId();
    res.redirect('/' + roomid)
});

app.get('/:roomid', function (req, res) {
    var roomid = req.params.roomid;
    res.render('index.html', { roomid });
});

app.get('/:roomid/expert', function (req, res) {
    var roomid = req.params.roomid;
    res.render('expert.html', { roomid });
});

app.get('/:roomid/customer', function (req, res) {
    var roomid = req.params.roomid;
    res.render('customer.html', { roomid });
});

app.get('/screenarexpert', function (req, res) {
    res.render('screenar-expert.html')
});

app.get('/api/getRoom/:uuid', function (req, res) {
    db.getRoom(res,req.params.uuid)
});

app.get('/api/getUser/:uuid', function (req, res) {
    db.getUser(res,req.params.uuid)
});

app.get('/api/getClip/:uuid', function (req, res) {
    db.getClip(res,req.params.uuid)
});

var clients = new Set()

// ----- START: Uncomment to have Node.js fetch leapmotion ------
// var url = 'ws://localhost:6437/v7.json';
// var socket = new WebSocket(url);
// socket.on('message', function (data) {
//     clients.forEach(function(s) {
//         s.emit('frame', data);
//     });
// });

// socket.on('open', function() {
//     console.log('connected to ' + url);
//     socket.send(JSON.stringify({enableGestures: false}))
//     socket.send(JSON.stringify({background: false}))
//     socket.send(JSON.stringify({optimizeHMD: false}))
//     socket.send(JSON.stringify({focused: true}))

// });
// socket.on('close', function(code, reason) { console.log(code, reason) });
// socket.on('error', function() { console.log('ws error') });
// ----- END: Uncomment to have Node.js fetch leapmotion ------

// setup http server
var privateKey  = fs.readFileSync('ssl/wild.fxpal.net.key', 'utf8');
var certificate = fs.readFileSync('ssl/wild.fxpal.net.bundle.crt', 'utf8');
var credentials = {key: privateKey, cert: certificate};

// var httpServer = http.createServer(app);
var httpsServer = https.createServer(credentials, app);

// httpServer.listen(5000, '0.0.0.0');
httpsServer.listen(5443, '0.0.0.0');

// var httpio = io(httpServer);
var httpsio = io(httpsServer);

roomio = httpsio.of('/room');
room(roomio);

console.log('listening to port https 5443');
