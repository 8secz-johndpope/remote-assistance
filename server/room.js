const uuid = require('uuid');
const config = require('config');
const fs = require('fs');

module.exports = function(io) {
    var rooms = {};
    io.on('connect', function(socket) {
        var room;
        var users = {};
        var sid = uuid.v4();
        var fileStream;
        var filePath;

        socket.on('join', function(data) {
            room = data.room;
            console.log('user', sid, 'joined room', room);
            if (rooms[room] == undefined) {
                users = {}
                rooms[room] = {
                    id: room,
                    created: Date.now(),
                    users
                };
            } else {
                users = rooms[room].users;
            }

            socket.join(data.room, function() {
                socket.emit('sid', {sid});
                users[sid] = socket;
                socket.emit('users', Object.keys(users));
                io.emit('update_dashboard', { room });
            });
        });

        socket.on('recording_started', function(data) {
            console.log('creating file');
            filePath = config.clipLoc + data.name + ".webm";
            fileStream = fs.createWriteStream(filePath, { flags: 'w' });
        });

        socket.on('recording_blob', function(data) {
            console.log('writing packet',data.length)
            fileStream.write(Buffer.from(new Uint8Array(data)));
        });

        socket.on('leave', function(data) {
            socket.disconnect();
        });

        socket.on('disconnect', function() {
            console.log('user', sid, 'left room', room);
            io.to(room).emit('left', {sid});
            socket.leave(room);
            delete users[sid];
            io.emit('update_dashboard', { room });
        });

        socket.on('webrtc', function(id, data) {
            var to = users[id];
            if (to) {
                data.from = sid;
                to.emit('webrtc', data);
            }
        })

        socket.on('frame', function(data) {
            // console.log(eventName);
            socket.to(room).emit('frame', data);
            socket.emit('frame', data);
        });


        // forwarded generic events
        let events = [
            'keydown',
            'wheel',
            'camera_update',
            'gyro',
            'ls_url',
            'recording_started',
            'recording_stopped',
            'sketch_draw',
            'sketch_clear',
            'clip_marker'
        ]
        events.forEach(function(eventName) {
            socket.on(eventName, function(data) {
                // console.log(eventName);
                socket.to(room).emit(eventName, data);
            });
        })
    });
    return rooms;
}