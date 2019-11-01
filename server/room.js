const uuid = require('uuid');

module.exports = function(io) {
    var users = {};
    io.on('connect', function(socket) {
        var room;
        var sid = uuid.v4();
        users[sid] = socket;
        socket.on('join', function(data) {
            room = data.room;
            socket.join(room);
            socket.emit('sid', {sid});
            socket.join(data.room, function() {
                socket.emit('users', Object.keys(users));
            });
        });

        socket.on('leave', function(data) {
            delete users[sid];
        });

        socket.on('disconnect', function() {
            io.to(room).emit('left', {sid})
            delete users[sid];
        });

        socket.on('webrtc', function(id, data) {
            //io.to(room).emit('webrtc', data);
            var to = users[id];
            if (to) {
                data.from = sid;
                to.emit('webrtc', data);
            }
        })

        // forwarded generic events
        [
            'keydown',
            'wheel',
            'camera_update',
            'gyro'
        ]
        .forEach(function(eventName) {
            socket.on(eventName, function(data) {
                Object.values(users).forEach(function(s) {
                    if (s !== socket) {
                        s.emit(eventName, data);
                    }
                });
            });
        })
    });
}