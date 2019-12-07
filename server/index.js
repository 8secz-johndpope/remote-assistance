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
let useDB = true
let leapMotion = false

nunjucks.configure('templates', {
    autoescape: true,
    express: app,
    noCache: true
});


// Args
const args = process.argv.slice(2)
if (args.includes("--no_db")) {
    useDB = false
} 
if (args.includes("--use_leap_motion")) {
    leapMotion = true
}
if (args.includes("--help")) {
    console.log("node index.js [--help]  [--no_db --use_leap_motion]")
    console.log("--no_db              Do not attempt to connect to a database. This turns off API features.")
    console.log("--use_leap_motion    Connect to Leap Motion device.")
    console.log("--help               Print this help message and exit.")
    process.exit()
}

// Routing
app.use('/static', express.static(__dirname + '/static'))

app.get('/', function (req, res) {
    var roomid = util.generateRandomRoomId();
    res.redirect('/' + roomid)
});


if (useDB) {
    const db = require('./db')

    app.get('/chat', function (req, res) {
        res.render('chat.html')
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

    // TODO
    app.get('/api/createCustomer/', function (req, res) {
        //db.createUser(res,req.params.uuid)
    });

    app.get('/api/createRoom/', function (req, res) {
        //db.createRoom(res,req.params.uuid)
    });
}


app.get('/screenarexpert', function (req, res) {
    res.render('screenar-expert.html')
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


var clients = new Set()


if (leapMotion) {
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
}

// Setup http server
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
