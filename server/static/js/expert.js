// enable popovers
$('[data-trigger=hover]').popover()

// setup sample video
var constraints = {
    video: false,
    audio: true
}

const SERVER_API = "/api/";
const SERVER_CLIP_STOR = "/stor/";
const user_uuid = "tempExpert"

//// Rendering
var renderer;

var first = true;
var wrtc;
var connected = false;
var currentFrame;
var frameUpdateInterval;

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
             drawing_canvas: document.getElementById('drawingCanvas'),
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

$('#lblLsSteps').click(function(e) {
    var checked = $('input', this).is(':checked');
    if (checked) {
        ls = true;
        updateStepCount();
    } else {
        ls = false;
        $('span', this).text('steps off');
    }
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

// ----- START: Live Steps -----
let ls = true;
let mediaRecorder;
let recordingLS = false;
let videoStack = [];
let videoStackIndex = 0;
let dotsInterval;
let step = 0;
let clearCtxInterval;
let vidOutlineInterval;
let recordingClipUUID;
let processing = true;
const LS_TIMEOUT = 3000;

function registerActivityLS() {
    if (!ls) return;
    if (!recordingLS) {
        recordingLS = true;
        toggleDots(true); 
        wrtc.emit({'td':1}); 
        startRecording();
    } 
    clearTimeout(clearCtxInterval);
    clearCtxInterval = setTimeout(stepDone,LS_TIMEOUT);
}

function startRecording() {
  let options = {mimeType: 'video/webm;videoBitsPerSecond:2500000;ignoreMutedMedia:true'};
  try {
    mediaRecorder = new MediaRecorder(renderer.getCanvas(), options);
  } catch (e0) {
    console.log('Unable to create MediaRecorder with options Object: ', e0);
    try {
      options = {mimeType: 'video/webm,codecs=vp9'};
      mediaRecorder = new MediaRecorder(renderer.getCanvas(), options);
    } catch (e1) {
      console.log('Unable to create MediaRecorder with options Object: ', e1);
      try {
        options = 'video/vp8'; // Chrome 47
        mediaRecorder = new MediaRecorder(renderer.getCanvas(), options);
      } catch (e2) {
        alert('MediaRecorder is not supported by this browser.\n\n' +
          'Try Firefox 29 or later, or Chrome 47 or later, ' +
          'with Enable experimental Web Platform features enabled from chrome://flags.');
        console.error('Exception while creating MediaRecorder:', e2);
        return;
      }
    }
  }
  console.log('Created MediaRecorder', mediaRecorder, 'with options', options);

  $.getJSON(SERVER_API + "createClip/lsClip/" + user_uuid + "/" + config.roomid).then( 
        function(data) {
            recordingClipUUID = data.uuid;
            wrtc.emit('start_recording', {name: clipUUID });
            mediaRecorder.onstop = handleStop;
            mediaRecorder.ondataavailable = handleDataAvailable;
            mediaRecorder.start();
            console.log('MediaRecorder started', mediaRecorder);
        }
    )
}

function stopRecording() {
  mediaRecorder.stop();
}

function handleStop(event) {
  console.log('Recorder stopped: ', event);
  let url = SERVER_CLIP_STOR + recordingClipUUID + ".webm";
  wrtc.emit('ls_url', {url: url});
  addStep(url);
  updateStepCount();
}

function handleDataAvailable(event) {
  if (event.data && event.data.size > 0) {
    wrtc.emit('recording_blob', event.data);
  }
}

function stepDone() {
  if (recording) { recording = false; stopRecording(); }
  toggleDots(false); wrtc.emit({'td':0}); ; 
}

function toggleDots(down) {
  if (!down) {
    clearInterval(dotsInterval);
    dotsInterval = null;
  } else {
     clearInterval(dotsInterval);
     document.getElementById("stepsCount").innerHTML = "";
     dotsInterval = window.setInterval( function() {
       let s = document.getElementById("stepsCount");
       if ( s.innerHTML.length > 3 ) {
         s.innerHTML = "";
       } else { s.innerHTML += "."; }
     }, 400);
    }
}

function updateStepCount() {
    let stackTxt = 'step';
    if (videoStack.length>0) { stackTxt += "s " + videoStack.length }
    if (ls) {
        $('#lblLsSteps').find('span').text(stackTxt+" ");        
    }
}

function addStep(url) {
  console.log('Adding step ' + url);
  videoStack.unshift(url);
}

function toggleSteps(open=0) {
  let sv = document.getElementById('stepVideo');
  let svo = document.getElementById('stepVideoOverlay');

  if ( sv.style.display == 'none' && (videoStack.length > 0) ) {
    sv.style.display = 'inline';
    svo.style.display = 'inline';
    videoStackIndex = 0;
    sv.src = videoStack[0];
    sv.autoplay = true;
    processing = false;
  } else if (!open) {
    sv.style.display = 'none';
    svo.style.display = 'none';
    processing = true;
  }
}

// ----- END: Live Steps -----

// ----- START: Comment this out to disable sending browser leapmotion data -----
// connection to leapmotion
function updateLeapmotionStatus(connected) {
    var btn = $('#leapmotion');
    if (connected) {
        btn
            .text('leapmotion connected')
            .removeClass('btn-danger')
            .addClass('btn-success');
    } else {
        btn
            .text('connect to leapmotion')
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
        // save as current frame
        currentFrame = event.data;
    });

    if (frameUpdateInterval) {
        clearInterval(frameUpdateInterval);
    }
    frameUpdateInterval = setInterval(function() {
        // send leap motion hand data to server
        if (SIOConnection.socket && frameUpdateInterval) {
            registerActivityLS();
            SIOConnection.socket.emit('frame', currentFrame);
        }
    }, 1000.0/30.0);

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