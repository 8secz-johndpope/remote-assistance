const express = require('express');
const app = express();
const http = require('http');
const https = require('https');
const fs = require('fs');
const io = require('socket.io');
const nunjucks = require('nunjucks');
const argparse = require('argparse');
const config = require('config');

const room = require('./room');
const util = require('./util');

nunjucks.configure('templates', {
    autoescape: true,
    express: app,
    noCache: true
});

// Args
var parser = new argparse.ArgumentParser({
    addHelp:true,
    description: 'Remote Assistance Server'
});

parser.addArgument(
    [ '-n', '--no_db' ],
    {
        action: 'storeConst',
        constant: true,
        defaultValue: false,
        help: 'Do not connect to the database'
    }
);
var args = parser.parseArgs();

// Routing
app.use('/static', express.static(__dirname + '/static'))

app.get('/', function (req, res) {
    var roomid = util.generateRandomRoomId();
    res.redirect('/' + roomid)
});


if (!args.no_db) {
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

// Setup http server
var privateKey  = fs.readFileSync('ssl/wild.fxpal.net.key', 'utf8');
var certificate = fs.readFileSync('ssl/wild.fxpal.net.bundle.crt', 'utf8');
var credentials = {key: privateKey, cert: certificate};

// var httpServer = http.createServer(app);
var httpsServer = https.createServer(credentials, app);

// httpServer.listen(5000, '0.0.0.0');
httpsServer.listen(config.port, config.host);

// var httpio = io(httpServer);
var httpsio = io(httpsServer);

roomio = httpsio.of('/room');
room(roomio);

console.log(`Listening to https on ${config.host}:${config.port}`);
