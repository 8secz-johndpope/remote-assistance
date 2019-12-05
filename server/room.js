const uuid = require('uuid');

module.exports = function(io) {
    var rooms = {};
    io.on('connect', function(socket) {
        var room;
        var users;
        var sid = uuid.v4();
        socket.on('join', function(data) {
            room = data.room;
            console.log('user', sid, 'joined room', room);
            if (rooms[room] == undefined) {
                users = rooms[room] = {};
            } else {
                users = rooms[room];
            }

            socket.join(data.room, function() {
                socket.emit('sid', {sid});
                users[sid] = socket;
                socket.emit('users', Object.keys(users));
            });
        });

        socket.on('leave', function(data) {
            socket.disconnect();
        });

        socket.on('disconnect', function() {
            console.log('user', sid, 'left room', room);
            io.to(room).emit('left', {sid})
            socket.leave(room);
            delete users[sid];
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
        ]
        events.forEach(function(eventName) {
            socket.on(eventName, function(data) {
                // console.log(eventName);
                socket.to(room).emit(eventName, data);
            });
        })
    });
}