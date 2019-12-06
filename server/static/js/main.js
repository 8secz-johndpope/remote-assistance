$(function() {
    var ifaces = $('#interfaces');
    function onChangeInterfaces(e) {
        var host = ifaces.val();
        var url;
        if (host == 'default') {
            url = 'https://' + window.location.host + '/customer';
        } else {
            url = 'https://' + host + ':5443/customer';
        }
        $('#qrcode').empty().qrcode(url);
        $('#url').text(url);
    }
    $('#interfaces').on('change', onChangeInterfaces);
    onChangeInterfaces();
});