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
    [ '-d', '--db_off' ],
    {
        action: 'storeConst',
        constant: true,
        defaultValue: false,
        help: 'Do not connect to the database'
    }
);
parser.addArgument(
    [ '-w', '--ws_off' ],
    {
        action: 'storeConst',
        constant: true,
        defaultValue: false,
        help: 'Do not start web socket server'
    }
);
var args = parser.parseArgs();

// Routing
app.use('/static', express.static(__dirname + '/static'))

app.get('/', function (req, res) {
    var roomid = util.generateRandomId();
    res.redirect('/' + roomid)
});

if (!args.db_off) {
    const db = require('./db')

    app.get('/chat', function (req, res) {
        res.render('chat.html')
    });

    app.get('/api/getRoom/:uuid', function (req, res) {
        db.getRoom(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    app.get('/api/getUser/:uuid', function (req, res) {
        db.getUser(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    app.get('/api/getClip/:uuid', function (req, res) {
        db.getClip(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    app.get('/api/getClips/:marker_uuid', function (req, res) {
        db.getClips(res,req.params.marker_uuid,function(data) {
            res.json(data)
        })
    });

    app.get('/api/createCustomer', function (req, res) {
        db.createUser(res, function(data) {
            res.json(data)
        })
    });

    app.get('/api/createClip/:name/:user_uuid/:room_uuid', function (req, res) {
        db.getUser(res,req.params.user_uuid,function(userData) {
            if (userData.length) {
                db.getRoom(res,req.params.room_uuid,function(roomData) {
                    if (roomData.length) {
                        db.createClip(res, req.params.name, req.params.user_uuid, req.params.room_uuid, function(data) {
                         res.json(data)
                        })
                    } else {
                        let out = {"error":"No room with that UUID"}
                        res.json(out)                        
                    }
                })
            } else {
                let out = {"error":"No user with that UUID"}
                res.json(out)
            }
        })
    });

    app.get('/api/createRoom/:user_uuid', function (req, res) {
        db.getUser(res,req.params.user_uuid,function(userData) {
            if (userData.length) {
                db.createRoom(res,req.params.user_uuid, function(data) {
                    res.json(data)
                })
            } else {
                let out = {"error":"No user with that UUID"}
                res.json(out)
            }
        })
    });
}

if (!args.no_ws) {
    const wsServer = http.createServer(app).listen(config.wsport, () => {
        console.log(`WS server listening on ${config.wsport}`);
    });
    const wss = new WebSocketServer({
        server: wsServer
    });
    wss.on('connection', (ws, req) => {
        console.log('creating file');
        var filePath = config.clipLoc + req.params.name.webm;
        const fileStream = fs.createWriteStream(filePath, { flags: 'w' });
        ws.on('message', message => {
            console.log('writing packet')
            // Only raw blob data can be sent
            fileStream.write(Buffer.from(new Uint8Array(message)));
        });
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
