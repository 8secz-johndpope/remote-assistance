// setup sample video
var constraints = {
    video: false,
    audio: true
}


//// Rendering
var renderer = new Renderer( 
    {add_interaction_box: true,
     add_line_object: false, 
     add_leapmotion_device: false}, 
    SIOConnection );

var first = true;
var wrtc;
navigator.mediaDevices.getUserMedia(constraints).then(
    function(stream) {
        wrtc = new WebRTCClient({ stream: stream });
        wrtc.on('stream', function(id, stream) {
            var video = $('#video')[0]
            video.srcObject = stream;
            video.autoplay = true;
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

function onClick(event)
{   
    //console.log(event);
    //document.getElementById("info").innerHTML = event.clientX.toFixed(2)+" "+event.clientY.toFixed(2)+" "+event.screenX.toFixed(2)+" "+event.screenY.toFixed(2);
    renderer.moveLeapmotionSpaceByClick(event.clientX, event.clientY);
    renderer.updateCamera();

    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
}
window.addEventListener('click', onClick, false);

// toolbar buttons
$('#zoom-small').click(function(e) {
    e.preventDefault();
    console.log('zoom-small');
    renderer.setCameraDistance(500);
    renderer.updateCamera();
    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
    return false;
});

$('#zoom-medium').click(function(e) {
    e.preventDefault();
    console.log('zoom-medium');
    renderer.setCameraDistance(300);
    renderer.updateCamera();
    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
    return false;
});

$('#zoom-large').click(function(e) {
    e.preventDefault();
    console.log('zoom-large');
    renderer.setCameraDistance(100);
    renderer.updateCamera();
    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
    return false;
});

$('#reset').click(function(e) {
    e.preventDefault();
    console.log('reset');
    renderer.resetCameraParam();
    renderer.updateCamera();
    wrtc.emit('camera_update', {msg: 'from_expert', 
                                position: renderer.camera.position, 
                                quaternion: renderer.camera.quaternion});
    return false;
});

// ----- START: Comment this out to disable sending browser leapmotion data -----
// connection to server
var url = [window.location.protocol, '//', window.location.host, '/'].join('')
var sio = io(url)

// connection to leapmotion
var url = 'ws://localhost:6437/v7.json';
var socket = new WebSocket(url);

socket.addEventListener('open', function() {
    console.log('connected to ' + url);
    socket.send(JSON.stringify({enableGestures: false}))
    socket.send(JSON.stringify({background: false}))
    socket.send(JSON.stringify({optimizeHMD: false}))
    socket.send(JSON.stringify({focused: true}))

});

socket.addEventListener('message', function (data) {
    // send leap motion hand data to server
    sio.emit('update_frame', event.data);
});

socket.addEventListener('close', function(code, reason) { console.log(code, reason) });
socket.addEventListener('error', function() { console.log('ws error') });
// ----- END: Comment this out to disable sending browser leapmotion data -----