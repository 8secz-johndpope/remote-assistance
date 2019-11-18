
function WebRTCClient(options) {
    var self = this;
    this.options = options || {};
    this.room = this.options.room || 'fxpal';
    this.stream = this.options.stream;
    this.pcs = {};
    this.callbacks = {};

    var namespace = '/room'
    var url = location.protocol + '//' + location.host + namespace;
    this.url = this.options.url || url;

    var socket = io.connect(url);
    var dataChannel = this.options.dataChannel;
  
    function createDataChannel(pc)
    {
        if (dataChannel) {
            console.log('creating data channel=',dataChannel);
            self.sendChannel = pc.createDataChannel(dataChannel, null);
            self.sendChannel.onopen = function (event) { console.log('channel onopen',event);};
            self.sendChannel.onclose = function (event) { console.log('channel onclose',event);};
            self.sendChannel.onmessage = function (event) {
                console.log('channel onmessage',event.data);
            };
        }
    }
    function getPC(id) {
        if (self.pcs[id])
            return self.pcs[id];

        var config = {
            "iceServers": [{ "urls": [
                "stun:stun.l.google.com:19302",
            ] }]
        };

        var pc = new RTCPeerConnection(config);
        self.pcs[id] = pc;
        if (self.stream)
            pc.addStream(self.stream);

        pc.onaddstream = function(event) {
            var cb = self.callbacks['stream'];
            if (cb)
                cb(id, event.stream);
        }

        pc.onicecandidate = function(event) {
            if (event.candidate) {
                socket.emit('webrtc', id, {
                    type: 'icecandidate',
                    payload: event.candidate
                })
            }
        }

        createDataChannel(pc);
        return pc;
    }

    var mediaConstraints = {
        offerToReceiveAudio: 1,
        offerToReceiveVideo: 1
    };

    socket.on('connect', function() {
        socket.emit('join', {room: self.room});
    });

    socket.on('left', function(data) {
        console.log('left', data);
        var pc = self.pcs[data.sid];
        if (pc) {
            pc.close();
        }
        delete self.pcs[data.sid];
    });

    socket.on('sid', function(data) {
        console.log('sid', data);
        self.sid = data.sid;
    });

    socket.on('users', function(data) {
        console.log('users', data);

        data.forEach(function(id) {
            if (id != self.sid) {
                var pc = getPC(id);
                var offer = null;
                pc.createOffer(mediaConstraints).then(function(result) {
                    offer = result;
                    return pc.setLocalDescription(new RTCSessionDescription(offer));
                })
                .then(function() {
                    socket.emit('webrtc', id, {
                        type:'offer',
                        payload: {
                            sdp: offer.sdp,
                            type: offer.type
                        }
                    });
                })
                .catch(function(error) {
                    console.error(error);
                })
            }
        });
    });

    socket.on('webrtc', function(data) {
        var from = data.from;
        var pc = getPC(data.from);
        switch (data.type) {
            case 'offer': {
                if (pc) {
                    var answer = null;
                    pc.setRemoteDescription(new RTCSessionDescription(data.payload))
                        .then(function() {
                            return pc.createAnswer(mediaConstraints);
                        })
                        .then(function(result) {
                            answer = result;
                            return pc.setLocalDescription(answer);
                        })
                        .then(function() {
                            socket.emit('webrtc', from, {
                                type: 'answer',
                                payload: {
                                    sdp: answer.sdp,
                                    type: answer.type
                                }
                            });
                        })
                        .catch(function(error) {
                            console.error(error);
                        })
                }
                break;
            }
            case 'answer': {
                pc.setRemoteDescription(new RTCSessionDescription(data.payload))
                    .catch(function(error) {
                        console.error(error);
                    })
                break;
            }
            case 'icecandidate': {
                pc.addIceCandidate(new RTCIceCandidate(data.payload))
                    .catch(function(error) {
                        console.error(error);
                    })
                break;
            }
        }
    });

    // methods.
    WebRTCClient.prototype.disconnect = function() {
        socket.emit('leave', {room: self.room});
        socket.emit('disconnect_request');
    }

    WebRTCClient.prototype.addStream = function(stream) {
        this.stream = stream;
    }

    WebRTCClient.prototype.joinRoom = function(room) {
        this.room = room;
        socket.emit('join', {room: 'fxpal'});

    }

    WebRTCClient.prototype.on = function(name, fn) {
        switch (name) {
            case 'stream':
                this.callbacks[name] = fn;
                break;
            default:
                socket.on(name, fn);
                break;
        }
    }

    WebRTCClient.prototype.emit = function(name, data) {
        socket.emit(name, data);
    }


    WebRTCClient.prototype.off = function(name, fn) {
        switch (name) {
            case 'stream':
                delete this.callbacks[name];
                break;
            default:
                socket.off(name, fn);
                break;
        }
    }
}
