
var SIOConnection = function (opts) {
    Leap.BrowserConnection.call(this, opts);
}
_.extend(SIOConnection.prototype, Leap.BrowserConnection.prototype);
SIOConnection.__proto__ = Leap.BrowserConnection;

SIOConnection.prototype.setupSocket = function() {
    var connection = this;
    var url = [window.location.protocol, '//', window.location.host, '/'].join('')
    var socket = io(url)
    socket.on('connection', function(socket) {
        connection.handleOpen();
    });
    socket.on('disconnect', function () {
        connection.handleClose(200, 'disconnect');
    });
    socket.on('frame', function(data) {
        connection.handleData(data);
    });
    return socket;
}


SIOConnection.prototype.handleData = function (data) {
    if (this.protocol === undefined) {
        Leap.BrowserConnection.prototype.handleData.call(this, JSON.stringify({ version: 6 }))
        var data = {
            "event": {
                "state": {
                    "attached": true,
                    "id": "LP89728733428",
                    "streaming": true,
                    "type": "Peripheral"
                },
                "type": "deviceEvent"
            }
        };
        Leap.BrowserConnection.prototype.handleData.call(this, JSON.stringify(data))
    } else {
        Leap.BrowserConnection.prototype.handleData.call(this, data)
    }
}
