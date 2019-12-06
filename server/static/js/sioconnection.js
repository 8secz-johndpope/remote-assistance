
var SIOConnection = function (opts) {
    Leap.BrowserConnection.call(this, opts);
}
_.extend(SIOConnection.prototype, Leap.BrowserConnection.prototype);
SIOConnection.__proto__ = Leap.BrowserConnection;

SIOConnection.prototype.setupSocket = function() {
    var connection = this;

    if (SIOConnection.socket) {
        var socket = SIOConnection.socket;
        socket.on('frame', function(data) {
            connection.handleData(data);
        });
        return socket;
    } else {
        return null;
    }
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
