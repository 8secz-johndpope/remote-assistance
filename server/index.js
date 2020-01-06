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

parser.addArgument(
    [ '-d', '--db_off' ],
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

    app.get('/api/getActiveRooms', function (req, res) {
        db.getActiveRooms(res,function(data) {
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
        db.createUser(res, "customer", function(data) {
            res.json(data)
        })
    });

    app.get('/api/createExpert', function (req, res) {
        db.createUser(res, "expert", function(data) {
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

    app.get('/api/addUserToRoom/:room_uuid/:user_uuid', function (req, res) {
        db.getUser(res,req.params.user_uuid,function(userData) {
            if (userData.length) {
                db.addUserToRoom(res,req.params.room_uuid,req.params.user_uuid, function(data) {
                    res.json(data)
                });
            } else {
                let out = {"error":"No user with that UUID"}
                res.json(out)
            }
        })
    });

    app.get('/api/removeUserFromRoom/:room_uuid/:user_uuid', function (req, res) {
        db.getUser(res,req.params.user_uuid,function(userData) {
            if (userData.length) {
                db.removeUserFromRoom(res,req.params.room_uuid,req.params.user_uuid, function(data) {
                    res.json(data)
                });
            } else {
                let out = {"error":"No user with that UUID"}
                res.json(out)
            }
        })
    });

}

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
            created: new Date(rooms[id].created),
            users: Object.keys(rooms[id].users).length
        });
    });
    // look for rooms with only 1 users
    roomArray = roomArray.filter(function(room) {
        return room.users == 1;
    });
    res.render('dashboard.html', { rooms: roomArray });
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
rooms = room(roomio);

console.log(`Listening to https on ${config.host}:${config.port}`);
