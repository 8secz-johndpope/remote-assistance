(function() {
    var namespace = '/room'
    var url = location.protocol + '//' + location.host + namespace;
    var socket = io.connect(url);

    socket.on('update_dashboard', function() {
        window.location.reload();
    });
})();