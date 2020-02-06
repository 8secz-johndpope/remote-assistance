// enable popovers
$('[data-trigger=hover]').popover()

// setup sample video
var constraints = {
    video: false,
    audio: true
}

const SERVER_API = "/api/";
const SERVER_CLIP_STOR = "/stor/";

// can be the following: hands, screenar, sketch, pointer
var mode = "hands"

//// Rendering
var renderer;

var first = true;
var wrtc;
var connected = false;
var lmConnected = false;
var currentFrame;
var frameUpdateInterval;

let user_uuid;

// hide the video until we have a stream
$('#video').hide();

navigator.mediaDevices.getUserMedia(constraints).then(
    function(stream) {
        wrtc = new WebRTCClient({
            stream: stream,
            room: config.roomid,
            dataChannel: 'ScreenAR',
            dataChannelCallback: dataChannelCallback
        });

        user_uuid = localStorage.getItem('expert_uuid');
        if (user_uuid === null) {
            $.post(SERVER_API + "user", {"type": "expert"}).then( 
             function(data) {
                    console.log('Created expert', data);
                    localStorage.setItem('expert_uuid',data.uuid);
                    addUserToRoom(data.uuid);
             }
            )
        } else {
            console.log('Got expert', user_uuid);
            addUserToRoom(user_uuid);
        } 

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
            });
            
            wrtc.on('connect', function() {
                wrtc.emit('set_mode', {mode});
            });
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
        wrtc.on('add_clip_to_anchor', function(clipData) {
            $.post(SERVER_API + "clipAnchor", {"clip_uuid":recordingClipUUID,"anchor_uuid":clipData.anchor_uuid,"position":clipData.position}).then( 
             function(data) {
                console.log('Added clip marker',data);
             }
            )
        });        
        wrtc.on('conversation_archive', function(data) {
            document.getElementById("chat").style.display = 'inline';
            if (typeof(data) == "string") {
                // convert string to JSON struct
                data = JSON.parse(data);
            }
            console.log(data);
            let ca = document.getElementById("conversationArchive");
            
            for (let i=0; i<data.responses.length;i++) {
                let row = ca.insertRow(ca.rows.length);
                let c1 = row.insertCell(0);
                let c2 = row.insertCell(1);
                c1.innerHTML = data.responses[i].question;
                c2.innerHTML = "<b>"+data.responses[i].responseLabel+"<b>";
                c2.style.verticalAlign = "top";
            }
            //console.log(ca.innerHTML);
        });

        // Create renderer after wrtc because it shares the same socket
        renderer = new Renderer( 
            {add_interaction_box: true,
             add_line_object: false, 
             add_leapmotion_device: false, 
             sio_connection: SIOConnection,
             dom_element: document.getElementById('container'),
             sketch_canvas: document.getElementById('sketchCanvas'),
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

// ----- START: Toolbar -----
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
    const url = ['https://', window.location.host, '/', config.roomid  ,'/customer'].join('');
    $('#qrcode').empty().qrcode(url);
    $('#url').text(url);
    $('#qrcode-modal').modal();
});

$('#lblLsStepsCount').click(function(e) {
    toggleStepsView(1);
});

$('#lblLsStepsOnOff').click(function(e) {
    const checked = $('input', this).is(':checked');
    if (!checked) {
        ls = true;
    } else {
        ls = false;
    }
    setLSOnOff();
});

// $('#lblSketchOnOff').click(function(e) {
//     const checked = $('input', this).is(':checked');
//     const c = document.getElementById("sketchCanvas");
//     if (!checked) {
//         sketch = true;
//         c.style.zIndex = 3;        
//         c.addEventListener('mousemove', drawSketch);
//         c.addEventListener('mouseup', handleMouseUp);
//         c.addEventListener('mousedown', handleMouseDown);
//         c.addEventListener('mouseout', handleMouseUp);
//         c.addEventListener('mouseenter', setPosition);

//         renderer.domElement.removeEventListener('click', onMouseClick, false);
//     } else {
//         sketch = false;
//         c.style.zIndex = 1;        
//         c.removeEventListener('mousemove', drawSketch);
//         c.removeEventListener('mouseup', handleMouseUp);
//         c.removeEventListener('mousedown', handleMouseDown);
//         c.removeEventListener('mouseout', handleMouseUp);
//         c.removeEventListener('mouseenter', setPosition);

//         renderer.domElement.addEventListener('click', onMouseClick, false);
//     }
//     setSketchOnOff();
// });

var lmSocket;
$('#leapmotion').click(function(e) {
    reconnectLeapmotion();
});

function setSketchOnOff() {
    if (sketch) { $('#sketchOnOffIcon').css('color', '#DC3545'); }
    else { $('#sketchOnOffIcon').css('color', 'gray'); }
}

function setLSOnOff() {
    if (ls) { $('#lsStepsOnOffIcon').css('color', '#DC3545'); }
    else { $('#lsStepsOnOffIcon').css('color', 'gray'); }
}

function updateVideoStack(dir,play=true) {
    let sv = document.getElementById('stepVideo');
    videoStackIndex += dir;
    if ( (videoStackIndex < 0) || (videoStackIndex == 0) ) { 
        videoStackIndex = 0;
        document.getElementById("lsUpIcon").style.color = "gray";
    } else {        
        document.getElementById("lsUpIcon").style.color = "#DC3545";
    }
    if (videoStackIndex >= videoStack.length-1) {
        videoStackIndex = videoStack.length-1;
        document.getElementById("lsDownIcon").style.color = "gray";
    } else {        
        document.getElementById("lsDownIcon").style.color = "#DC3545";
    }

    if (play && (sv.src !== videoStack[videoStackIndex])) {
        sv.src = videoStack[videoStackIndex];
        sv.play();        
    }
}

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

function addUserToRoom(user_uuid) {
    $.post(SERVER_API + "userRoom", {"user_uuid":user_uuid,"room_uuid":config.roomid}).then( 
        function(data) {
            console.log('Added user to room', data);
        }
    )
}

function removeUserFromRoom() {
    $.ajax({
      dataType: "json",
      type: "DELETE",
      url: SERVER_API + "userRoom/" + user_uuid + "/" + config.roomid,
      async: false, 
      success: function(data) {
           console.log('Removed user from room', data);
      }
    });
    //$.getJSON(SERVER_API + "removeUserFromRoom/" + config.roomid + "/" + user_uuid).then( 
    //   function(data) {
    //       console.log('Removed user from room', data);
    //   }
    //)
}

window.onbeforeunload = function() {
      removeUserFromRoom();
}


function setMode(newMode) {
    // console.log('setMode', mode);

    // reset hands
    if (mode == "hands" && newMode != "hands") {
        if (renderer) {
            $(renderer.canvas).hide();
            renderer.domElement.removeEventListener('click', onMouseClick, false);
        }
    }

    // reset sketch
    if (mode == "sketch" && newMode != "sketch") {
        sketch = false;
        const c = document.getElementById("sketchCanvas");
        c.style.zIndex = 1;
        c.removeEventListener('mousemove', drawSketch);
        c.removeEventListener('mouseup', handleMouseUp);
        c.removeEventListener('mousedown', handleMouseDown);
        c.removeEventListener('mouseout', handleMouseUp);
        c.removeEventListener('mouseenter', setPosition);
    }

    // reset pointer
    if (mode == "pointer" && newMode != "pointer") {
        enablePointer = false;
        const c = document.getElementById("sketchCanvas");
        c.style.zIndex = 1;
        c.removeEventListener('click', handlePointerClick);
        wrtc.emit('pointer_clear', {});
    }

    // reset screenar
    if (mode == "screenar" && newMode != "screenar") {
        enablePointer = false;
        $('#correctedcanvas').hide();
    }

    switch(newMode) {
        case "hands": {
            if (renderer && renderer.interaction_box) {
                $(renderer.canvas).show();
                renderer.domElement.addEventListener('click', onMouseClick, false);
            }
            break;
        }

        case "sketch": {
            const c = document.getElementById("sketchCanvas");
            sketch = true;
            c.style.zIndex = 3;
            c.addEventListener('mousemove', drawSketch);
            c.addEventListener('mouseup', handleMouseUp);
            c.addEventListener('mousedown', handleMouseDown);
            c.addEventListener('mouseout', handleMouseUp);
            c.addEventListener('mouseenter', setPosition);
            renderer.domElement.removeEventListener('click', onMouseClick, false);
            break;
        }

        case "pointer": {
            enablePointer = true;
            const c = document.getElementById("sketchCanvas");
            c.style.zIndex = 3;
            c.addEventListener('click', handlePointerClick);
            renderer.domElement.removeEventListener('click', onMouseClick, false);
            break;
        }

        case "screenar": {
            enableScreenAR = true;
            $('#correctedcanvas').show();
            break;
        }

        default: {
            mode = newMode;
            return;
        }
    }

    mode = newMode;
    if (wrtc) {
        wrtc.emit('set_mode', {mode});
    }
}

$('#toolbar-tab a').on('click', function (e) {
    e.preventDefault()

    var newMode = $(this).data('tab') || 'none';
    setMode(newMode);

    $(this).tab('show');
});
// default is hands for now
setMode('hands')
// ----- END: Toolbar -----

// ----- START: Live Steps -----
let ls = false;
let mediaRecorder;
let recordingLS = false;
let videoStack = []; 
//videoStack.push("http://showhow.fxpal.com/misc/test.mp4"); 
//videoStack.push("http://showhow.fxpal.com/misc/wcDocHandles.mp4");

let videoStackIndex = 0;
let dotsInterval;
let dotsCount = 0;
let step = 0;
let clearCtxInterval;
let clearSketchInterval;
let vidOutlineInterval;
let recordingClipUUID;
let processing = true;
const LS_TIMEOUT = 3000;
const SKETCH_TIMEOUT = 3000;
const pos = { x: 0, y: 0 };
let sketch = false;


function registerActivityLS() {
    if (!ls) return;
    if (!recordingLS) {
        recordingLS = true;
        toggleDots(true); 
        wrtc.emit('recording_started',{"clip_uuid":recordingClipUUID}); 
        startRecording();
    } 
    clearTimeout(clearCtxInterval);
    clearCtxInterval = setTimeout(stepDone,LS_TIMEOUT);
}

function startRecording() {
    let options = {mimeType: 'video/webm;videoBitsPerSecond:2500000;ignoreMutedMedia:true'};
    try {
        mediaRecorder = new MediaRecorder(renderer.getCanvas().captureStream(), options);
    } catch (e0) {
        console.log('Unable to create MediaRecorder with options Object: ', e0);
        try {
            options = {mimeType: 'video/webm,codecs=vp9'};
            mediaRecorder = new MediaRecorder(renderer.getCanvas().captureStream(), options);
        } catch (e1) {
                console.log('Unable to create MediaRecorder with options Object: ', e1);
            try {
                options = 'video/vp8'; // Chrome 47
                mediaRecorder = new MediaRecorder(renderer.getCanvas().captureStream(), options);
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

    $.post(SERVER_API + "clip", {"name": "lsClip","user_uuid":user_uuid,"room_uuid":config.roomid}).then( 
        function(data) {
            recordingClipUUID = data.uuid;
            wrtc.emit('recording_started', {"clip_uuid":recordingClipUUID});
            mediaRecorder.onstop = handleStop;
            mediaRecorder.ondataavailable = handleDataAvailable;
            mediaRecorder.start(500);
            console.log('MediaRecorder started', mediaRecorder);
        }
    )
}

function stopRecording() {
  mediaRecorder.stop();
  mediaRecorder = [];
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
    console.log("writing recording data");
    wrtc.emit('recording_blob', event.data);
  }
}

function stepDone() {
  if (recordingLS) { 
    recordingLS = false; 
    stopRecording(); 
    wrtc.emit('recording_stopped',{"clip_uuid":recordingClipUUID}); 
  }
  clearTimeout(clearCtxInterval);
  toggleDots(false); 
}

function toggleDots(down) {
  if (!down) {
    clearInterval(dotsInterval);
    dotsInterval = null; dotsCount = 0;
    updateStepCount();
  } else {
     clearInterval(dotsInterval);
     dotsInterval = window.setInterval( function() {
        let s = "steps ";
        for (let i=0;i<dotsCount%4;i++) {
            s += ".";
        }
        $('#lsStepsCountSpan').text(s);
        dotsCount++;
     }, 400);
    }
}

function updateStepCount() {
    let stackTxt = 'step';
    if (videoStack.length>0) { stackTxt += "s " + videoStack.length }
    $('#lsStepsCountSpan').text(stackTxt); 
    console.log(stackTxt);     
}

function addStep(url) {
  console.log('Adding step ' + url);
  videoStack.unshift(url);
}

function toggleStepsView(open=0) {
  let sv = document.getElementById('stepVideo');
  let svo = document.getElementById('stepVideoOverlay');
  let tb = document.getElementById('toolbar');

  if ( sv.style.display == 'none' && (videoStack.length > 0) ) {
    sv.style.display = 'inline';
    svo.style.display = 'inline';
    tb.style.display = 'none';
    videoStackIndex = 0;
    sv.src = videoStack[0];
    sv.autoplay = true;
    processing = false;
  } else if (!open) {
    sv.style.display = 'none';
    svo.style.display = 'none';
    tb.style.display = 'inline';
    processing = true;
  }
}

// ----- END: Live Steps -----

// ----- START: Sketch -----

// Possibly move to shared lib with customer code
function configSketch() {
    const c = document.getElementById("sketchCanvas");
    //c.style.zIndex = 3;
    c.style.position = 'fixed';
    c.style.top = 0;
    c.style.left = 0;
    c.style.width = '100%';
    c.style.height = '100%';
    c.width = window.innerWidth;
    c.height = window.innerHeight;
}

function clearSketchCanvas() {
  let sCanvas = document.getElementById("sketchCanvas");
  let sCanvasCtx = sCanvas.getContext('2d');
  sCanvasCtx.clearRect(0, 0, sCanvas.width, sCanvas.height);
  wrtc.emit('sketch_clear', {}); 
}

function setPosition(e) {
  pos.x = e.clientX;
  pos.y = e.clientY;
}

function handleMouseUp(e) {
  if (ls) {
    clearCtxInterval = setTimeout(stepDone,LS_TIMEOUT);     
  }
  clearSketchInterval = setTimeout(clearSketchCanvas,SKETCH_TIMEOUT);  
}

function handleMouseDown(e) {
  e.preventDefault();
  setPosition(e);
  if (ls && !recordingLS) {
    recordingLS = true;
    toggleDots(true);
    clearTimeout(clearCtxInterval);
    startRecording();
    //dCanvas.setPointerCapture(e.pointerId);
  }
}

function drawSketch(e) {
  // mouse left button must be pressed
  if (e.buttons !== 1) return;

  clearTimeout(clearSketchInterval);
  if (ls) {  clearTimeout(clearCtxInterval); }

  let sCanvas = document.getElementById("sketchCanvas");
  let sCanvasCtx =  sCanvas.getContext('2d');

  sCanvasCtx.beginPath();

  sCanvasCtx.lineWidth = 5;
  sCanvasCtx.lineCap = 'round';
  sCanvasCtx.strokeStyle = 'rgba(255, 255, 0, 1)';

  let sX = pos.x, sY = pos.y;
  setPosition(e);
  sCanvasCtx.moveTo(sX, sY); // from
  sCanvasCtx.lineTo(pos.x, pos.y); // to

  sCanvasCtx.stroke(); // draw it

  wrtc.emit('sketch_draw', {sX: sX, sY: sY, eX: pos.x, eY: pos.y,
    cW: sCanvas.width, cH: sCanvas.height}); // ship it
}

setSketchOnOff();
setLSOnOff();
updateStepCount();
updateVideoStack(0,false);
configSketch();
window.addEventListener("resize", configSketch);

// ----- END: Sketch -----

// ----- START: Comment this out to disable sending browser leapmotion data -----
// connection to leapmotion
function updateLeapmotionStatus(lmc) {
    var btn = $('#leapmotion');
    lmConnected = lmc
    if (lmConnected) {
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
            if (currentFrame) {
                // Inspect frame hands/velocity
                //registerActivityLS();
                SIOConnection.socket.emit('frame', currentFrame);
            }
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

// ----- START: AR Pointer
var enablePointer = false;

function handlePointerClick(e) {
    console.log('pointer_set', e.clientX, e.clientY);
    let canvas = document.getElementById("sketchCanvas");
    wrtc.emit('pointer_set', {
        x: e.clientX,
        y: e.clientY,
        w: canvas.width,
        h: canvas.height
    });
    return false;
}

// $('#pointerSet').click(function(e) {
//     e.preventDefault();
//     const input = $(this).children('input');
//     const checked = !input.is(':checked');
//     const c = document.getElementById("sketchCanvas");
//     input.prop('checked', !checked);
//     if (checked) {
//         enablePointer = true;
//         $(this).addClass('btn-success');
//         c.style.zIndex = 3;
//         c.addEventListener('click', handlePointerClick);
//         renderer.domElement.removeEventListener('click', onMouseClick, false);
//     } else {
//         enablePointer = false;
//         $(this).removeClass('btn-success');
//         c.style.zIndex = 1;
//         c.removeEventListener('click', handlePointerClick);
//         renderer.domElement.addEventListener('click', onMouseClick, false);
//         wrtc.emit('pointer_clear', {});
//     }
// });

// ----- END: AR Pointer

// ----- START: ScreenAR
var enableScreenAR = false;
// $('#toggleScreenAR').click(function(e) {
//     e.preventDefault();
//     const input = $(this).children('input');
//     const checked = !input.is(':checked');
//     const c = $('#correctedcanvas');
//     input.prop('checked', !checked);
//     if (checked) {
//         enableScreenAR = true;
//         $(this).addClass('btn-success');
//         c.show();
//     } else {
//         enablePointer = false;
//         $(this).removeClass('btn-success');
//         c.hide();
//     }
// });
$('#correctedcanvas').hide();
// ----- END: ScreenAR

$('#dbg-send-recording_started').click(function() {
    wrtc.emit('recording_started', {"clip_uuid": "demo1", "debug": true})
});

$('#dbg-send-clip_ready').click(function() {
    wrtc.emit('clip_ready', {"clip_uuid": "demo1", "debug": true})
});

$('#dbg-send-clip_thumbnail_ready').click(function() {
    wrtc.emit('clip_thumbnail_ready', {"clip_uuid": "demo1", "debug": true})
});