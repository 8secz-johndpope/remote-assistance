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
//const bodyParser = require('body-parser')
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

var db = null
if (!args.db_off) {
    db = require('./db')
}

// Routing
//app.use(bodyParser.urlencoded())
//app.use(bodyParser.json())
bb.extend(app, {
    upload: true
})

app.use('/static', express.static(__dirname + '/static'))

app.get('/', function (req, res) {
    var roomid = util.generateRandomId();
    if (db !== null) {
        db.updateRoom(res,true,true,roomid,req.body,function(roomData) {
            res.redirect('/' + roomid)
        });        
    }
});

if (db !== null) {

    // Chat
    app.get('/chat', function (req, res) {
        res.render('chat.html')
    });


    // API

    // Room
    app.post('/api/room', function(req, res) { 
        db.updateRoom(res,true,true,util.generateRandomId(),req.body,function(roomData) {
            db.getRoom(res,roomData.uuid,function(data) {
                res.status(201).json(data)
            })
        })
    });

    app.get('/api/room/:uuid', function (req, res) {
        db.getRoom(res,req.params.uuid,function(data) {
            if (data.uuid) { res.json(data); }
            else { res.status(404).json({}); }
        })
    });

    app.get('/api/room', function (req, res) {
        if(req.query.active) {
            db.getActiveRooms(res,[],null,function(data) {
                res.json(data);
            })
        } else {
            db.getAllRooms(res,function(data) {
                db.getActiveRooms(res,data,null,function(activeData) {
                    res.json(activeData);
                })
            })            
        }
    });

    app.put('/api/room/:uuid', function(req, res) { 
        db.updateRoom(res,false,true,req.params.uuid,req.body,function(roomData) {
            db.getRoom(res,roomData.uuid,function(data) {
                db.getActiveRooms(res,data,req.params.uuid,function(activeData) {
                    if (activeData.length) { res.status(202).json(activeData[0]); }
                    else { res.status(404).json({}); }
                })
            })
        })
    });

    app.patch('/api/room/:uuid', function(req, res) { 
        db.updateRoom(res,false,false,req.params.uuid,req.body,function(roomData) {
            db.getRoom(res,roomData.uuid,function(data) {
                db.getActiveRooms(res,data,req.params.uuid,function(activeData) {
                    if (activeData.length) { res.status(202).json(activeData[0]); }
                    else { res.status(404).json({}); }
                })
            })
        })
    });

    app.delete('/api/room/:uuid', function(req, res) { 
        db.deleteRoom(res,req.params.uuid,function(data) {
            res.status(410).json(data);
        })
    });


    // User
    app.post('/api/user', function(req, res) { 
        db.updateUser(res,true,true,util.generateRandomId(),req.body,function(userData) {
            db.getUser(res,userData.uuid,function(data) {
                res.status(201).json(data)
            })
        })
    });

    app.post('/api/customer', function (req, res) {
        db.createUser(res, "customer", function(data) {
            res.status(201).json(data)
        })
    });

    app.post('/api/expert', function (req, res) {
        db.createUser(res, "expert", function(data) {
            res.status(201).json(data)
        })
    });

    app.get('/api/user/:uuid', function (req, res) {
        db.getUser(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    app.get('/api/user', function (req, res) {
        db.getAllUsers(res,function(data) {
            res.json(data)
        })
    });

    app.put('/api/user/:uuid', function(req, res) { 
        db.updateUser(res,false,true,req.params.uuid,req.body,function(userData) {
            db.getUser(res,userData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    app.patch('/api/user/:uuid', function(req, res) { 
        db.updateUser(res,false,false,req.params.uuid,req.body,function(userData) {
            db.getUser(res,userData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    app.delete('/api/user/:uuid', function(req, res) { 
        db.deleteUser(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });


    // Anchor
    app.post('/api/anchor', function(req, res) { 
        db.updateAnchor(res,true,true,util.generateRandomId(),req,function(anchorData) {
            db.getAnchor(res,anchorData.uuid,function(data) {
                res.status(201).json(data)
            })
        })
    });

    app.get('/api/anchor/:uuid', function (req, res) {
        db.getAnchor(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    app.get('/api/anchor', function (req, res) {
        if (req.query.text) {
            db.getAllAnchorsSearch(res,req.query.text,function(data) {
                res.json(data)
            })
        } else {
            db.getAllAnchors(res,function(data) {
                res.json(data)
            })
        }
    });

    app.put('/api/anchor/:uuid', function(req, res) { 
        db.updateAnchor(res,false,true,req.params.uuid,req,function(anchorData) {
            db.getAnchor(res,anchorData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    app.patch('/api/anchor/:uuid', function(req, res) { 
        db.updateAnchor(res,false,false,req.params.uuid,req,function(anchorData) {
            db.getAnchor(res,anchorData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    app.delete('/api/anchor/:uuid', function(req, res) { 
        db.deleteAnchor(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });


    // Clip 
    app.post('/api/clip', function (req, res) {
        db.getUser(res,req.body.user_uuid,function(userData) {
            if (userData.uuid) {
                db.getRoom(res,req.body.room_uuid,function(roomData) {
                    if (roomData.uuid) {
                        db.updateClip(res,true,true,util.generateRandomId(),req.body,function(clipData) {
                            db.getClip(res,clipData.uuid,function(data) {
                                res.status(201).json(data)
                            })
                        })
                    } else {
                        let body = {};
                        body.time_created = new Date() / 1000;
                        db.updateRoom(res,true,true,req.body.room_uuid,req.body,function(roomData) {
                            db.updateClip(res,true,true,util.generateRandomId(),req.body,function(clipData) {
                                db.getClip(res,clipData.uuid,function(data) {
                                    res.status(201).json(data)
                                })
                            })
                        })
                    }
                })
            } else {
                let out = {"error":"No user with that UUID"}
                res.status(404).json(out)
            }
        })
    });

    app.get('/api/clip/:uuid', function (req, res) {
        db.getClip(res,req.params.uuid,function(data) {
            if (data.uuid) {
                res.json(data)
            } else {
                res.status(404).json(data)
            }
        })
    });

    app.put('/api/clip/:uuid', function(req, res) { 
        db.updateClip(res,false,true,req.params.uuid,req.body,function(clipData) {
            db.getClip(res,clipData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    app.patch('/api/clip/:uuid', function(req, res) { 
        db.updateClip(res,false,false,req.params.uuid,req.body,function(clipData) {
            db.getClip(res,clipData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    app.delete('/api/clip/:uuid', function(req, res) { 
        db.deleteClip(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });

    app.get('/api/clip', function (req, res) {
        if (req.query.anchor_uuid) {
            db.getClipsForAnchor(res,req.query.anchor_uuid,function(data) {
                res.json(data)
            })
        } else {
            db.getAllClips(res,function(data) {
                res.json(data)
            })            
        }
    });



    // clipAnchor
    app.post('/api/clipAnchor', function (req,res) {
        db.getClip(res,req.body.clip_uuid,function(clipData) {
            if (clipData.uuid) {
                db.getAnchor(res,req.body.anchor_uuid,function(anchorData) {
                    if (anchorData.uuid) {
                        db.removeClipFromAnchor(res,req.body.anchor_uuid,req.body.clip_uuid,function(data) {
                            db.updateClipAnchor(res,true,true,util.generateRandomId(),req.body,function(clipAData) {
                                db.getClipAnchor(res,clipAData.uuid,function(data) {
                                    res.status(201).json(data)
                                })
                            })
                        })
                    } else {
                        let out = {"error":"No anchor with that UUID"}
                        res.status(404).json(out)
                    }
                })
            } else {
                let out = {"error":"No clip with that UUID"}
                res.status(404).json(out)
            }
        })
    });

    app.get('/api/clipAnchor/:uuid', function (req, res) {
        db.getClipAnchor(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    app.get('/api/clipAnchor', function (req, res) {
        db.getAllClipAnchors(res,function(data) {
            res.json(data)
        })
    });

    app.put('/api/clipAnchor/:uuid', function(req, res) { 
        db.updateClipAnchor(res,false,true,req.params.uuid,req.body,function(clipAData) {
            db.getClipAnchor(res,clipAData.uuid,function(data) {
             res.status(202).json(data)
            })
        })
    });

    app.patch('/api/clipAnchor/:uuid', function(req, res) { 
        db.updateClipAnchor(res,false,false,req.params.uuid,req.body,function(clipAData) {
            db.getClipAnchor(res,clipAData.uuid,function(data) {
             res.status(202).json(data)
            })
        })
    });

    app.delete('/api/clipAnchor/:clip_uuid/:anchor_uuid', function (req, res) {
       db.getClip(res,req.params.clip_uuid,function(clipData) {
            if (clipData.uuid) {
                db.getAnchor(res,req.params.anchor_uuid,function(anchorData) {
                    if (anchorData.uuid) {
                        db.removeClipFromAnchor(res,req.params.anchor_uuid,req.params.clip_uuid,function(data) {
                            res.status(410).json(data)
                        })
                    } else {
                        let out = {"error":"No anchor with that UUID"}
                        res.status(404).json(out)
                    }
                })
            } else {
                let out = {"error":"No clip with that UUID"}
                res.status(404).json(out)
            }
        })
     });

    app.delete('/api/clipAnchor/:uuid', function(req, res) { 
        db.deleteClipAnchor(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });


    //userRoom
    app.post('/api/userRoom', function (req, res) {
        db.getUser(res,req.body.user_uuid,function(userData) {
            if (userData.uuid) { 
                db.getRoom(res,req.body.room_uuid,function(roomData) {
                    if (roomData.uuid) {
                            db.updateUserRoom(res,true,true,util.generateRandomId(),req.body,function(userRoomData) {
                                db.getUserRoom(res,userRoomData.uuid,function(data) {
                                    res.status(201).json(data)
                                })
                            })
                    } else {
                        let out = {"error":"No room with that UUID"}
                        res.status(404).json(out)
                    }
                })
            } else {
                let out = {"error":"No user with that UUID"}
                res.status(200).json(req.body)
            }
        })
    });

    app.get('/api/userRoom/:uuid', function (req, res) {
        db.getUserRoom(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    app.get('/api/userRoom', function (req, res) {
        db.getAllUserRooms(res,function(data) {
            res.json(data)
        })
    });

    app.put('/api/userRoom/:uuid', function(req, res) { 
        db.updateUserRoom(res,false,true,req.params.uuid,req.body,function(userRoomData) {
            db.getUserRoom(res,userRoomData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    app.patch('/api/userRoom/:uuid', function(req, res) { 
        db.updateUserRoom(res,false,false,req.params.uuid,req.body,function(userRoomData) {
            db.getUserRoom(res,userRoomData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    app.delete('/api/userRoom/:user_uuid/:room_uuid', function (req, res) {
        db.getUser(res,req.params.user_uuid,function(userData) {
            if (userData.uuid) {
                db.getRoom(res,req.params.room_uuid,function(roomData) {
                    if (roomData.uuid) {
                        db.removeUserFromRoom(res,req.params.room_uuid,req.params.user_uuid, function(data) {
                            res.status(410).json(data)
                        });
                    } else {
                        let out = {"error":"No room with that UUID"}
                        res.status(404).json(out)
                    }
                })
            } else {
                let out = {"error":"No user with that UUID"}
                res.status(404).json(out)
            }
        })
    });

    app.delete('/api/userRoom/:uuid', function(req, res) { 
        db.deleteUserRoom(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });

    // End API
}


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
