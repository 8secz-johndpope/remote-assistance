const config = require('config');
const express = require('express');

var router = express.Router()

var db = null
if (config.databaseUrl) {
    db = require('./db')
}

if (db !== null) {

    // API

    // Room
    router.post('/room', function(req, res) {
        db.updateRoom(res,true,true,util.generateRandomId(),req.body,function(roomData) {
            db.getRoom(res,roomData.uuid,function(data) {
                res.status(201).json(data)
            })
        })
    });

    router.get('/room/:uuid', function (req, res) {
        db.getRoom(res,req.params.uuid,function(data) {
            if (data.uuid) { res.json(data); }
            else { res.status(404).json({}); }
        })
    });

    router.get('/room', function (req, res) {
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

    router.put('/room/:uuid', function(req, res) {
        db.updateRoom(res,false,true,req.params.uuid,req.body,function(roomData) {
            db.getRoom(res,roomData.uuid,function(data) {
                db.getActiveRooms(res,data,req.params.uuid,function(activeData) {
                    if (activeData.length) { res.status(202).json(activeData[0]); }
                    else { res.status(404).json({}); }
                })
            })
        })
    });

    router.patch('/room/:uuid', function(req, res) {
        db.updateRoom(res,false,false,req.params.uuid,req.body,function(roomData) {
            db.getRoom(res,roomData.uuid,function(data) {
                db.getActiveRooms(res,data,req.params.uuid,function(activeData) {
                    if (activeData.length) { res.status(202).json(activeData[0]); }
                    else { res.status(404).json({}); }
                })
            })
        })
    });

    router.delete('/room/:uuid', function(req, res) {
        db.deleteRoom(res,req.params.uuid,function(data) {
            res.status(410).json(data);
        })
    });


    // User
    router.post('/user', function(req, res) {
        db.updateUser(res,true,true,util.generateRandomId(),req.body,function(userData) {
            db.getUser(res,userData.uuid,function(data) {
                res.status(201).json(data)
            })
        })
    });

    router.post('/customer', function (req, res) {
        db.createUser(res, "customer", function(data) {
            res.status(201).json(data)
        })
    });

    router.post('/expert', function (req, res) {
        db.createUser(res, "expert", function(data) {
            res.status(201).json(data)
        })
    });

    router.get('/user/:uuid', function (req, res) {
        db.getUser(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    router.get('/user', function (req, res) {
        db.getAllUsers(res,function(data) {
            res.json(data)
        })
    });

    router.put('/user/:uuid', function(req, res) {
        db.updateUser(res,false,true,req.params.uuid,req.body,function(userData) {
            db.getUser(res,userData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    router.patch('/user/:uuid', function(req, res) {
        db.updateUser(res,false,false,req.params.uuid,req.body,function(userData) {
            db.getUser(res,userData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    router.delete('/user/:uuid', function(req, res) {
        db.deleteUser(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });

    // Anchor
    router.post('/anchor', function(req, res) {
        db.updateAnchor(res,true,true,util.generateRandomId(),req,function(anchorData) {
            db.getAnchor(res,anchorData.uuid,function(data) {
                res.status(201).json(data)
            })
        })
    });

    router.get('/anchor/:uuid', function (req, res) {
        db.getAnchor(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    router.get('/anchor', function (req, res) {
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

    router.put('/anchor/:uuid', function(req, res) {
        db.updateAnchor(res,false,true,req.params.uuid,req,function(anchorData) {
            db.getAnchor(res,anchorData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    router.patch('/anchor/:uuid', function(req, res) {
        db.updateAnchor(res,false,false,req.params.uuid,req,function(anchorData) {
            db.getAnchor(res,anchorData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    router.delete('/anchor/:uuid', function(req, res) {
        db.deleteAnchor(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });


    // Clip
    router.post('/clip', function (req, res) {
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

    router.get('/clip/:uuid', function (req, res) {
        db.getClip(res,req.params.uuid,function(data) {
            if (data.uuid) {
                res.json(data)
            } else {
                res.status(404).json(data)
            }
        })
    });

    router.put('/clip/:uuid', function(req, res) {
        db.updateClip(res,false,true,req.params.uuid,req.body,function(clipData) {
            db.getClip(res,clipData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    router.patch('/clip/:uuid', function(req, res) {
        db.updateClip(res,false,false,req.params.uuid,req.body,function(clipData) {
            db.getClip(res,clipData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    router.delete('/clip/:uuid', function(req, res) {
        db.deleteClip(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });

    router.get('/clip', function (req, res) {
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
    router.post('/clipAnchor', function (req,res) {
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

    router.get('/clipAnchor/:uuid', function (req, res) {
        db.getClipAnchor(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    router.get('/clipAnchor', function (req, res) {
        db.getAllClipAnchors(res,function(data) {
            res.json(data)
        })
    });

    router.put('/clipAnchor/:uuid', function(req, res) {
        db.updateClipAnchor(res,false,true,req.params.uuid,req.body,function(clipAData) {
            db.getClipAnchor(res,clipAData.uuid,function(data) {
             res.status(202).json(data)
            })
        })
    });

    router.patch('/clipAnchor/:uuid', function(req, res) {
        db.updateClipAnchor(res,false,false,req.params.uuid,req.body,function(clipAData) {
            db.getClipAnchor(res,clipAData.uuid,function(data) {
             res.status(202).json(data)
            })
        })
    });

    router.delete('/clipAnchor/:clip_uuid/:anchor_uuid', function (req, res) {
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

    router.delete('/clipAnchor/:uuid', function(req, res) {
        db.deleteClipAnchor(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });


    //userRoom
    router.post('/userRoom', function (req, res) {
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

    router.get('/userRoom/:uuid', function (req, res) {
        db.getUserRoom(res,req.params.uuid,function(data) {
            res.json(data)
        })
    });

    router.get('/userRoom', function (req, res) {
        db.getAllUserRooms(res,function(data) {
            res.json(data)
        })
    });

    router.put('/userRoom/:uuid', function(req, res) {
        db.updateUserRoom(res,false,true,req.params.uuid,req.body,function(userRoomData) {
            db.getUserRoom(res,userRoomData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    router.patch('/userRoom/:uuid', function(req, res) {
        db.updateUserRoom(res,false,false,req.params.uuid,req.body,function(userRoomData) {
            db.getUserRoom(res,userRoomData.uuid,function(data) {
                res.status(202).json(data)
            })
        })
    });

    router.delete('/userRoom/:user_uuid/:room_uuid', function (req, res) {
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

    router.delete('/userRoom/:uuid', function(req, res) {
        db.deleteUserRoom(res,req.params.uuid,function(data) {
            res.status(410).json(data)
        })
    });

    // End API
}

module.exports = router
