// enable popovers
$('[data-trigger=hover]').popover()

// setup sample video
var constraints = {
    video: false,
    audio: true
}


//// Rendering
var renderer;

var first = true;
var wrtc;
var connected = false;
// hide the video until we have a stream
$('#video').hide();

navigator.mediaDevices.getUserMedia(constraints).then(
    function(stream) {
        wrtc = new WebRTCClient({
            stream: stream,
            room: config.roomid
        });
        wrtc.on('stream', function(id, stream) {
            var video = $('#video').show().get(0)
            video.srcObject = stream;
            video.autoplay = true;
            $('#qrcode-modal').modal('hide');
            connected = true;
            stream.getVideoTracks().forEach(function(t) {
                t.addEventListener('ended', function() {
                    $('#video').hide();
                    connected = false;
                    onReset();
                });
            })
        });
        wrtc.on('gyro', function(data) {
            // console.log('gyro', data);
            //document.getElementById("info").innerHTML = data.alpha.toFixed(2)+" "+data.beta.toFixed(2)+" "+data.gamma.toFixed(2)+" "+data.absolute;
            
            renderer.rotateCameraBody(data.alpha, data.beta, data.gamma);
            
            renderer.alignLeapmotionSpace();

            renderer.updateCamera();
            wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
                                
        });

        // Create renderer after wrtc because it shares the same socket
        renderer = new Renderer( 
            {add_interaction_box: true,
             add_line_object: false, 
             add_leapmotion_device: false, 
             sio_connection: SIOConnection,
             dom_element: document.getElementById('container'),
             video_element: document.getElementById('video'),
            });

        // reset camera
        onReset();

        // limit click to threejs canvas
        renderer.domElement.addEventListener('click', onMouseClick, false);

    }
);

function onKeyDown( event ) {    
    var charcode = String.fromCharCode(event.keyCode);    
    var d_trans = 10;
    var d_rot = 1;
    switch(charcode)
    {
        case 'O':
            renderer.updateCameraType('O');            
            break;
        case 'P':
            renderer.updateCameraType('P'); 
            break;
        case 'R':
            renderer.resetCameraParam();            
            break;
        case 'Q':
            renderer.rotateLeapmotionSpace(d_rot);            
            break;
        case 'E':
            renderer.rotateLeapmotionSpace(-d_rot);  
            break;
        case 'W':
            renderer.moveLeapmotionSpace(0,0,d_trans);
            break;
        case 'S':
            renderer.moveLeapmotionSpace(0,0,-d_trans);            
            break;
        case 'A':
            renderer.moveLeapmotionSpace(d_trans,0,0);
            break;
        case 'D':
            renderer.moveLeapmotionSpace(-d_trans,0,0);            
            break;
        case 'Z':
            renderer.moveLeapmotionSpace(0,-d_trans,0);
            break;
        case 'X':
            renderer.moveLeapmotionSpace(0,d_trans,0);            
            break;
        case 'T':
            renderer.toggleTrackingMode();
            break;
        case 'N':
            renderer.toggleAlignNormalMode();
            break;
        case 'G':
            renderer.toggleGestureMode();
            break;        
    }
    renderer.updateCamera();
    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
}

window.addEventListener('keydown', onKeyDown, false);


function onWheel( event ) 
{    
    var delta = 20;
    if (event.deltaY > 0)
    {
        renderer.zoominoutCamera(delta);        
    }
    else
    {
        renderer.zoominoutCamera(-delta);      
    }
    renderer.updateCamera();

    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
}

window.addEventListener('wheel', onWheel, false);

function onMouseClick(event)
{   
    if (!connected) {
        return;
    }
    //console.log(event);
    //document.getElementById("info").innerHTML = event.clientX.toFixed(2)+" "+event.clientY.toFixed(2)+" "+event.screenX.toFixed(2)+" "+event.screenY.toFixed(2);
    renderer.moveLeapmotionSpaceByClick(event.clientX, event.clientY);
    renderer.updateCamera();

    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
}

// toolbar buttons
$('#zoom-small').click(function(e) {
    console.log('zoom-small');
    renderer.setCameraDistance(500);
    renderer.updateCamera();
    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
});

$('#zoom-medium').click(function(e) {
    console.log('zoom-medium');
    renderer.setCameraDistance(300);
    renderer.updateCamera();
    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
});

$('#zoom-large').click(function(e) {
    console.log('zoom-large');
    renderer.setCameraDistance(100);
    renderer.updateCamera();
    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
});

function onReset() {
    console.log('reset');
    renderer.rotateCameraBody(0, 90, 0);
    renderer.resetCameraParam();
    renderer.updateCamera();
}

$('#reset').click(function(e) {
    onReset();
    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
});


$('#qr').click(function(e) {
    var url = ['https://', window.location.host, '/', config.roomid  ,'/customer'].join('');
    $('#qrcode').empty().qrcode(url);
    $('#url').text(url);
    $('#qrcode-modal').modal();
});

var lmSocket;
$('#leapmotion').click(function(e) {
    reconnectLeapmotion();
});

function toggleFullScreen() {
    if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen();
    } else {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        }
    }
}
$('#fullscreen').click(function() {
    toggleFullScreen()
});

// ----- START: Comment this out to disable sending browser leapmotion data -----
// connection to leapmotion
function updateLeapmotionStatus(connected) {
    var btn = $('#leapmotion');
    if (connected) {
        btn
            .text('Leapmotion Connected')
            .removeClass('btn-danger')
            .addClass('btn-success');
    } else {
        btn
            .text('Connect to Leapmotion')
            .removeClass('btn-success')
            .addClass('btn-danger');
    }
}

function reconnectLeapmotion() {
    if (lmSocket) {
        lmSocket.close();
        lmSocket = null;
    }

    var url = 'ws://localhost:6437/v7.json';
    var socket = new WebSocket(url);

    socket.addEventListener('open', function() {
        console.log('connected to ' + url);
        socket.send(JSON.stringify({enableGestures: false}));
        socket.send(JSON.stringify({background: false}));
        socket.send(JSON.stringify({optimizeHMD: false}));
        socket.send(JSON.stringify({focused: true}));
        updateLeapmotionStatus(true);
    });

    socket.addEventListener('message', function (data) {
        // send leap motion hand data to server
        if (SIOConnection.socket) {
            SIOConnection.socket.emit('frame', event.data);
        }
    });

    socket.addEventListener('close', function(code, reason) {
        console.log(code, reason);
        updateLeapmotionStatus(false);
    });
    socket.addEventListener('error', function(e) {
        console.log('ws error', e);
        updateLeapmotionStatus(false);
    });

    lmSocket = socket;
}
reconnectLeapmotion();
// ----- END: Comment this out to disable sending browser leapmotion data -----