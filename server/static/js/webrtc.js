
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
    if (window.SIOConnection) {
        // update the socket.io connection for leapmotion if exists
        SIOConnection.socket = socket;
    }
    var dataChannelName = this.options.dataChannel;
    var onDataChannelCallback = this.options.dataChannelCallback;

    this.createDataChannel = function(name,pc)
    {
      console.log('creating data channel=',name);
      const dataChannelOptions = {
        ordered: false, // do not guarantee order
        //maxPacketLifeTime: 1000/25, // in milliseconds
        maxRetransmits: 0
      };
      this.sendChannel = pc.createDataChannel(name, dataChannelOptions);
      this.sendChannel.onopen = function (event) { console.log('channel onopen',event);};
      this.sendChannel.onclose = function (event) { console.log('channel onclose',event);};
      this.sendChannel.onmessage = function (event) {
          if (onDataChannelCallback)
            onDataChannelCallback(event.data);
      };
    }
    function getPC(id) {
        if (self.pcs[id])
        {
            return self.pcs[id];
        }

        var config = {
            "iceServers": [
                { "urls": "stun:stun.l.google.com:19302" },
                { "urls": "stun:ace.paldeploy.com" },
                {
                    "urls": "stun:ace.paldeploy.com",
                    "username": "fxpal",
                    "credential": "j6NLrDvq4zCUkc2Y5SweHofU"
                }
            ]
        };

        var pc = new RTCPeerConnection(config);

        /*pc.ondatachannel = function(event) {
          var channel = event.channel;
            channel.onopen = function(event) {
            channel.send('Hi back!');
          }
          channel.onmessage = function(event) {
            console.log(event.data);
          }
        }*/

        self.pcs[id] = pc;
        if (self.stream) {
            self.stream.getAudioTracks().forEach(function(track) {
                pc.addTrack(track, self.stream);
            });
            self.stream.getVideoTracks().forEach(function(track) {
                pc.addTrack(track, self.stream);
            });
        }

        /*pc.onnegotiationneeded = function (event) {
          console.error('negociation needed');
        }*/

        if (dataChannelName)
        {
          self.createDataChannel(dataChannelName,pc);
        }

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

        return pc;
    }

    var mediaConstraints = {
        offerToReceiveAudio: true,
        offerToReceiveVideo: true,
        voiceActivityDetection: true
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
                            if (!answer) {
                                answer = result;
                                // force vp8 because safari doesn't handle h264 negotiation well
                                answer.sdp = CodecsHandler.preferCodec(answer.sdp, 'vp8');
                                return pc.setLocalDescription(answer);
                            }
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

    WebRTCClient.prototype.setStream = function(stream) {
        for (var key in this.pcs) {
            var pc = wrtc.pcs[key];
            stream.getVideoTracks().forEach(function(track) {
                var sender = pc.getSenders().find(function(s) {
                    return s.track.kind == track.kind;
                });
                sender.replaceTrack(track);
           });
        }
        this.stream = stream;
    }
}


var CodecsHandler = (function() {
    function preferCodec(sdp, codecName) {
        var info = splitLines(sdp);

        if (codecName === 'vp8' && info.vp8LineNumber === info.videoCodecNumbers[0]) {
            return sdp;
        }

        if (codecName === 'vp9' && info.vp9LineNumber === info.videoCodecNumbers[0]) {
            return sdp;
        }

        if (codecName === 'h264' && info.h264LineNumber === info.videoCodecNumbers[0]) {
            return sdp;
        }

        sdp = preferCodecHelper(sdp, codecName, info);

        return sdp;
    }

    function preferCodecHelper(sdp, codec, info, ignore) {
        var preferCodecNumber = '';

        if (codec === 'vp8') {
            if (!info.vp8LineNumber) {
                return sdp;
            }
            preferCodecNumber = info.vp8LineNumber;
        }

        if (codec === 'vp9') {
            if (!info.vp9LineNumber) {
                return sdp;
            }
            preferCodecNumber = info.vp9LineNumber;
        }

        if (codec === 'h264') {
            if (!info.h264LineNumber) {
                return sdp;
            }

            preferCodecNumber = info.h264LineNumber;
        }

        var newLine = info.videoCodecNumbersOriginal.split('SAVPF')[0] + 'SAVPF ';

        var newOrder = [preferCodecNumber];

        if (ignore) {
            newOrder = [];
        }

        info.videoCodecNumbers.forEach(function(codecNumber) {
            if (codecNumber === preferCodecNumber) return;
            newOrder.push(codecNumber);
        });

        newLine += newOrder.join(' ');

        sdp = sdp.replace(info.videoCodecNumbersOriginal, newLine);
        return sdp;
    }

    function splitLines(sdp) {
        var info = {};
        sdp.split('\n').forEach(function(line) {
            if (line.indexOf('m=video') === 0) {
                info.videoCodecNumbers = [];
                line.split('SAVPF')[1].split(' ').forEach(function(codecNumber) {
                    codecNumber = codecNumber.trim();
                    if (!codecNumber || !codecNumber.length) return;
                    info.videoCodecNumbers.push(codecNumber);
                    info.videoCodecNumbersOriginal = line;
                });
            }

            if (line.indexOf('VP8/90000') !== -1 && !info.vp8LineNumber) {
                info.vp8LineNumber = line.replace('a=rtpmap:', '').split(' ')[0];
            }

            if (line.indexOf('VP9/90000') !== -1 && !info.vp9LineNumber) {
                info.vp9LineNumber = line.replace('a=rtpmap:', '').split(' ')[0];
            }

            if (line.indexOf('H264/90000') !== -1 && !info.h264LineNumber) {
                info.h264LineNumber = line.replace('a=rtpmap:', '').split(' ')[0];
            }
        });

        return info;
    }

    function removeVPX(sdp) {
        var info = splitLines(sdp);

        // last parameter below means: ignore these codecs
        sdp = preferCodecHelper(sdp, 'vp9', info, true);
        sdp = preferCodecHelper(sdp, 'vp8', info, true);

        return sdp;
    }

    function disableNACK(sdp) {
        if (!sdp || typeof sdp !== 'string') {
            throw 'Invalid arguments.';
        }

        sdp = sdp.replace('a=rtcp-fb:126 nack\r\n', '');
        sdp = sdp.replace('a=rtcp-fb:126 nack pli\r\n', 'a=rtcp-fb:126 pli\r\n');
        sdp = sdp.replace('a=rtcp-fb:97 nack\r\n', '');
        sdp = sdp.replace('a=rtcp-fb:97 nack pli\r\n', 'a=rtcp-fb:97 pli\r\n');

        return sdp;
    }

    function prioritize(codecMimeType, peer) {
        if (!peer || !peer.getSenders || !peer.getSenders().length) {
            return;
        }

        if (!codecMimeType || typeof codecMimeType !== 'string') {
            throw 'Invalid arguments.';
        }

        peer.getSenders().forEach(function(sender) {
            var params = sender.getParameters();
            for (var i = 0; i < params.codecs.length; i++) {
                if (params.codecs[i].mimeType == codecMimeType) {
                    params.codecs.unshift(params.codecs.splice(i, 1));
                    break;
                }
            }
            sender.setParameters(params);
        });
    }

    function removeNonG722(sdp) {
        return sdp.replace(/m=audio ([0-9]+) RTP\/SAVPF ([0-9 ]*)/g, 'm=audio $1 RTP\/SAVPF 9');
    }

    function setBAS(sdp, bandwidth, isScreen) {
        if (!bandwidth) {
            return sdp;
        }

        if (typeof isFirefox !== 'undefined' && isFirefox) {
            return sdp;
        }

        if (isScreen) {
            if (!bandwidth.screen) {
                console.warn('It seems that you are not using bandwidth for screen. Screen sharing is expected to fail.');
            } else if (bandwidth.screen < 300) {
                console.warn('It seems that you are using wrong bandwidth value for screen. Screen sharing is expected to fail.');
            }
        }

        // if screen; must use at least 300kbs
        if (bandwidth.screen && isScreen) {
            sdp = sdp.replace(/b=AS([^\r\n]+\r\n)/g, '');
            sdp = sdp.replace(/a=mid:video\r\n/g, 'a=mid:video\r\nb=AS:' + bandwidth.screen + '\r\n');
        }

        // remove existing bandwidth lines
        if (bandwidth.audio || bandwidth.video) {
            sdp = sdp.replace(/b=AS([^\r\n]+\r\n)/g, '');
        }

        if (bandwidth.audio) {
            sdp = sdp.replace(/a=mid:audio\r\n/g, 'a=mid:audio\r\nb=AS:' + bandwidth.audio + '\r\n');
        }

        if (bandwidth.screen) {
            sdp = sdp.replace(/a=mid:video\r\n/g, 'a=mid:video\r\nb=AS:' + bandwidth.screen + '\r\n');
        } else if (bandwidth.video) {
            sdp = sdp.replace(/a=mid:video\r\n/g, 'a=mid:video\r\nb=AS:' + bandwidth.video + '\r\n');
        }

        return sdp;
    }

    // Find the line in sdpLines that starts with |prefix|, and, if specified,
    // contains |substr| (case-insensitive search).
    function findLine(sdpLines, prefix, substr) {
        return findLineInRange(sdpLines, 0, -1, prefix, substr);
    }

    // Find the line in sdpLines[startLine...endLine - 1] that starts with |prefix|
    // and, if specified, contains |substr| (case-insensitive search).
    function findLineInRange(sdpLines, startLine, endLine, prefix, substr) {
        var realEndLine = endLine !== -1 ? endLine : sdpLines.length;
        for (var i = startLine; i < realEndLine; ++i) {
            if (sdpLines[i].indexOf(prefix) === 0) {
                if (!substr ||
                    sdpLines[i].toLowerCase().indexOf(substr.toLowerCase()) !== -1) {
                    return i;
                }
            }
        }
        return null;
    }

    // Gets the codec payload type from an a=rtpmap:X line.
    function getCodecPayloadType(sdpLine) {
        var pattern = new RegExp('a=rtpmap:(\\d+) \\w+\\/\\d+');
        var result = sdpLine.match(pattern);
        return (result && result.length === 2) ? result[1] : null;
    }

    function setVideoBitrates(sdp, params) {
        params = params || {};
        var xgoogle_min_bitrate = params.min;
        var xgoogle_max_bitrate = params.max;

        var sdpLines = sdp.split('\r\n');

        // VP8
        var vp8Index = findLine(sdpLines, 'a=rtpmap', 'VP8/90000');
        var vp8Payload;
        if (vp8Index) {
            vp8Payload = getCodecPayloadType(sdpLines[vp8Index]);
        }

        if (!vp8Payload) {
            return sdp;
        }

        var rtxIndex = findLine(sdpLines, 'a=rtpmap', 'rtx/90000');
        var rtxPayload;
        if (rtxIndex) {
            rtxPayload = getCodecPayloadType(sdpLines[rtxIndex]);
        }

        if (!rtxIndex) {
            return sdp;
        }

        var rtxFmtpLineIndex = findLine(sdpLines, 'a=fmtp:' + rtxPayload.toString());
        if (rtxFmtpLineIndex !== null) {
            var appendrtxNext = '\r\n';
            appendrtxNext += 'a=fmtp:' + vp8Payload + ' x-google-min-bitrate=' + (xgoogle_min_bitrate || '228') + '; x-google-max-bitrate=' + (xgoogle_max_bitrate || '228');
            sdpLines[rtxFmtpLineIndex] = sdpLines[rtxFmtpLineIndex].concat(appendrtxNext);
            sdp = sdpLines.join('\r\n');
        }

        return sdp;
    }

    function setOpusAttributes(sdp, params) {
        params = params || {};

        var sdpLines = sdp.split('\r\n');

        // Opus
        var opusIndex = findLine(sdpLines, 'a=rtpmap', 'opus/48000');
        var opusPayload;
        if (opusIndex) {
            opusPayload = getCodecPayloadType(sdpLines[opusIndex]);
        }

        if (!opusPayload) {
            return sdp;
        }

        var opusFmtpLineIndex = findLine(sdpLines, 'a=fmtp:' + opusPayload.toString());
        if (opusFmtpLineIndex === null) {
            return sdp;
        }

        var appendOpusNext = '';
        appendOpusNext += '; stereo=' + (typeof params.stereo != 'undefined' ? params.stereo : '1');
        appendOpusNext += '; sprop-stereo=' + (typeof params['sprop-stereo'] != 'undefined' ? params['sprop-stereo'] : '1');

        if (typeof params.maxaveragebitrate != 'undefined') {
            appendOpusNext += '; maxaveragebitrate=' + (params.maxaveragebitrate || 128 * 1024 * 8);
        }

        if (typeof params.maxplaybackrate != 'undefined') {
            appendOpusNext += '; maxplaybackrate=' + (params.maxplaybackrate || 128 * 1024 * 8);
        }

        if (typeof params.cbr != 'undefined') {
            appendOpusNext += '; cbr=' + (typeof params.cbr != 'undefined' ? params.cbr : '1');
        }

        if (typeof params.useinbandfec != 'undefined') {
            appendOpusNext += '; useinbandfec=' + params.useinbandfec;
        }

        if (typeof params.usedtx != 'undefined') {
            appendOpusNext += '; usedtx=' + params.usedtx;
        }

        if (typeof params.maxptime != 'undefined') {
            appendOpusNext += '\r\na=maxptime:' + params.maxptime;
        }

        sdpLines[opusFmtpLineIndex] = sdpLines[opusFmtpLineIndex].concat(appendOpusNext);

        sdp = sdpLines.join('\r\n');
        return sdp;
    }

    // forceStereoAudio => via webrtcexample.com
    // requires getUserMedia => echoCancellation:false
    function forceStereoAudio(sdp) {
        var sdpLines = sdp.split('\r\n');
        var fmtpLineIndex = null;
        for (var i = 0; i < sdpLines.length; i++) {
            if (sdpLines[i].search('opus/48000') !== -1) {
                var opusPayload = extractSdp(sdpLines[i], /:(\d+) opus\/48000/i);
                break;
            }
        }
        for (var i = 0; i < sdpLines.length; i++) {
            if (sdpLines[i].search('a=fmtp') !== -1) {
                var payload = extractSdp(sdpLines[i], /a=fmtp:(\d+)/);
                if (payload === opusPayload) {
                    fmtpLineIndex = i;
                    break;
                }
            }
        }
        if (fmtpLineIndex === null) return sdp;
        sdpLines[fmtpLineIndex] = sdpLines[fmtpLineIndex].concat('; stereo=1; sprop-stereo=1');
        sdp = sdpLines.join('\r\n');
        return sdp;
    }

    return {
        removeVPX: removeVPX,
        disableNACK: disableNACK,
        prioritize: prioritize,
        removeNonG722: removeNonG722,
        setApplicationSpecificBandwidth: function(sdp, bandwidth, isScreen) {
            return setBAS(sdp, bandwidth, isScreen);
        },
        setVideoBitrates: function(sdp, params) {
            return setVideoBitrates(sdp, params);
        },
        setOpusAttributes: function(sdp, params) {
            return setOpusAttributes(sdp, params);
        },
        preferVP9: function(sdp) {
            return preferCodec(sdp, 'vp9');
        },
        preferCodec: preferCodec,
        forceStereoAudio: forceStereoAudio
    };
})();
