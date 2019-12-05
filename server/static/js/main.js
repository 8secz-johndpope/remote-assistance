$(function() {
    var url = ['https://', window.location.host, '/', config.roomid  ,'/customer'].join('');
    $('#qrcode').empty().qrcode(url);
    $('#url').text(url);
});