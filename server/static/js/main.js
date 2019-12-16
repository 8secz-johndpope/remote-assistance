$(function() {
    var ifaces = $('#interfaces');
    function onChangeInterfaces(e) {
        var host = ifaces.val();
        var url;
        if (host == 'default') {
            var roomid = e.target.getAttribute('data-roomid');
            url = 'https://' + window.location.host + '/' + roomid + '/customer';
        } else {
            url = 'https://' + host + ':5443/customer';
        }
        $('#qrcode').empty().qrcode(url);
        $('#url').text(url);
    }
    $('#interfaces').on('change', onChangeInterfaces);
    onChangeInterfaces({target: document.getElementById('default-value')});
});