const uuid = require('uuid');
const config = require('config');
const fs = require('fs');
const { exec } = require("child_process");

module.exports = function(io) {
    var rooms = {};

    function sleep(ms) {
      return new Promise((resolve) => {
        setTimeout(resolve, ms);
      });
    }

    async function execCmd(cmd, event, room, uuid, waitTime) {
        await sleep(waitTime); // wait to gather data from client
        console.log(cmd);
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                console.log(`error: ${error.message}`);
                // don't return on error because we have no way to tell client for now.  always emit message
                // return;
            }
            if (stderr) {
                console.log(`stderr: ${stderr}`);
                // We don't return because ffmpeg returns stderr for the status
                // return;
            }
            console.log(`stdout: ${stdout}`);
            io.to(room).emit(event, {clip_uuid:uuid});
        });
    }

    io.on('connect', function(socket) {
        var room;
        var users = {};
        var sid = uuid.v4();
        var fileStream;

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
            if (data.debug) {
                console.log('fake recording_started event');
                return;
            }
            let filePath = config.clipLoc + data.clip_uuid + ".webm";
            console.log('creating webm file ' + filePath);
            fileStream = fs.createWriteStream(filePath, { flags: 'w' });
            console.log(fileStream);
        });

        socket.on('recording_stopped', function(data) {
            console.log('creating mp4 file');
            let filePathThumb = config.clipLoc + data.clip_uuid + ".jpg";
            let filePathMp4 = config.clipLoc + data.clip_uuid + ".mp4";
            let filePathWebm = config.clipLoc + data.clip_uuid + ".webm";
            let cmdTranscode = "ffmpeg -i " + filePathWebm + 
                      " -y -vcodec libx264 -pix_fmt yuv420p -acodec libfdk_aac -vf \"pad=ceil(iw/2)*2:ceil(ih/2)*2\" " +
                      filePathMp4;
            execCmd(cmdTranscode,"clip_ready", room, data.clip_uuid,2000);
            let cmdCreateThumb = "ffmpeg -i " + filePathWebm + 
                      " -ss 00:00:01.000 -vframes 1 " + filePathThumb;
            execCmd(cmdCreateThumb,"clip_thumbnail_ready", room, data.clip_uuid,2500);
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
            "clip_ready",
            "clip_thumbnail_ready",
            'sketch_draw',
            'sketch_clear',
            'add_clip_to_anchor',
            'pointer_set',
            'pointer_clear',
            'conversation_archive',
            'set_mode',
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