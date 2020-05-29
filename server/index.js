/*!
 * Remote Asistance/ACE
 * Copyright(c) 2020 FX Palo Lato Labs, Inc.
 * License: contact ace@fxpal.com
 */

const express = require('express');
const app = express();
const http = require('http');
const https = require('https');
const fs = require('fs');
const io = require('socket.io');
const nunjucks = require('nunjucks');
const argparse = require('argparse');
const config = require('config');
const WebSocketServer = require('ws').Server;
const bb = require('express-busboy')
var dateFilter = require('nunjucks-date-filter');

const room = require('./room');
const util = require('./util');

// socket.io for the help room
var roomio;
var rooms = {};

nunjucks.configure('templates', {
    autoescape: true,
    express: app,
    noCache: true
})
// register filters
.addFilter('date', dateFilter);

// Args
var parser = new argparse.ArgumentParser({
    addHelp:true,
    description: 'Remote Assistance Server'
});

var args = parser.parseArgs();

var db = null
if (config.databaseUrl) {
    db = require('./db');

    // Chat (require DB)
    app.get('/chat', function (req, res) {
        res.render('chat.html')
    });
}

// Routing
bb.extend(app, {
    upload: true
})

app.use('/static', express.static(__dirname + '/static'))

app.get('/', function (req, res) {
    var roomid = util.generateRandomId();
    if (db !== null) {
        db.updateRoom(res,true,true,roomid,req.body,function(roomData) {
            res.redirect('/' + roomid);
        });        
    } else {
        res.redirect('/' + roomid);
    }
});


app.get('/help', function (req, res) {
    res.render('help.html')
});

app.get('/screenarexpert', function (req, res) {
    res.render('screenar-expert.html')
});

app.get('/customer', function (req, res) {
    // redirect to new room and notify expert waiting room
    var roomid = util.generateRandomId();
    res.redirect(`/${roomid}/customer`);
});

app.get('/expert', function (req, res) {
    // redirect to new room and notify expert waiting room
    var roomArray = [];
    Object.keys(rooms).forEach(function(id) {
        roomArray.push({
            id,
            modifiedMS: rooms[id].modified,
            modified: new Date(rooms[id].modified),
            users: Object.keys(rooms[id].users).length
        });
    });
    // look for rooms with only 0 or 1 users
    roomArray = roomArray.filter(function(room) {
        return room.users <= 1;
    });
    roomArray.sort((a, b) => b.modifiedMS-a.modifiedMS);
    res.render('dashboard.html', { rooms: roomArray });
});

// handle remote assistance basic urls
app.use('/basic', require('./basic'));

// API
app.use('/api', require('./api'));

// remote assistance url
app.get('/:roomid', function (req, res) {
    var roomid = req.params.roomid;
    res.render('index.html', { roomid });
});

app.get('/:roomid/expert', function (req, res) {
    var roomid = req.params.roomid;
    var mode = req.query.mode;
    if (mode == 'basic') {
        res.render('expert_basic.html', { roomid });
    } else if (mode == 'fxa') {
        res.render('expert_fxa.html', { roomid });
    } else {
        res.render('expert.html', { roomid });
    }
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
rooms = room(roomio);

console.log(`Listening to https on ${config.host}:${config.port}`);
