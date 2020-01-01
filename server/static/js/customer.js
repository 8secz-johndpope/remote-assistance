// import { request } from "http";

function isEpson() {
  if (navigator.userAgent.match(/EMBT3C/i)) {
    return true;
  } else {
    return false;
  }
}

function isIOS() {
    if  (navigator.userAgent.match(/iPhone/i)
        || navigator.userAgent.match(/iPad/i)
        || navigator.userAgent.match(/iPod/i)
        || navigator.userAgent.match(/AppleWebKit/i)
    ) {
        return true;
    }  else {
        return false;
    }
}

function isMobile() {
    if (navigator.userAgent.match(/Android/i)
      || navigator.userAgent.match(/webOS/i)
      || navigator.userAgent.match(/iPhone/i)
      || navigator.userAgent.match(/iPad/i)
      || navigator.userAgent.match(/iPod/i)
      || navigator.userAgent.match(/BlackBerry/i)
      || navigator.userAgent.match(/Windows Phone/i)
    ) {
      return true;
    }
    else {
      return false;
    }
}

// setup sample video
var constraints = {
    video: {
        width: 1920,
        height: 1080
    },
    audio: true
}
if (isEpson()) {
    constraints.video.width = 320;
    constraints.video.height = 240;
}

if (isMobile()) {
    constraints.video.facingMode = { exact: 'environment' }
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

var muted = true;
$('#mute').click(function() {
    muted = !muted;
    if (muted) {
        $(this).removeClass('btn-success').addClass('btn-danger');
        $(this.children[0]).removeClass('fa-microphone').addClass('fa-microphone-slash')
    } else {
        $(this).removeClass('btn-danger').addClass('btn-success');
        $(this.children[0]).removeClass('fa-microphone-slash').addClass('fa-microphone')
    }
    $('audio, video').each(function(i, video) {
        var tracks = video.srcObject.getAudioTracks();
        tracks.forEach(function(t) {
            t.enabled = !muted;
        });
    })
});


//// Rendering
var renderer;
var wrtc;
navigator.mediaDevices.getUserMedia(constraints).then(
    function(stream) {
        var video = $('#video')[0]
        video.srcObject = stream;
        video.autoplay = true;
        video.muted = true;

        // set default mute
        var tracks = stream.getAudioTracks();
        tracks.forEach(function(t) {
            t.enabled = !muted;
        });

        wrtc = new WebRTCClient({
            stream: stream,
            room: config.roomid
        });

        wrtc.on('stream', function(id, stream) {
            var audio = $('<audio autoplay/>');
            audio[0].id = id;
            audio[0].srcObject = stream;
            var tracks = stream.getAudioTracks();
            tracks.forEach(function(t) {
                t.enabled = !muted;
            });
            $(document.body).append(audio);
            stream.addEventListener('ended', function() {
                audio.remove();
            });
        });


        wrtc.on('camera_update', function(data) {
            if (renderer) {
                renderer.updateCameraByParameter(data.position, data.quaternion);
            }
        });

        wrtc.on('sketch_draw', function(data) {
            drawSketch(data);
        });

        wrtc.on('sketch_clear', function(data) {
            clearSketch();
        });

        renderer = new Renderer(
            {add_interaction_box: false,
             add_line_object: false,
             add_leapmotion_device: false,
             sio_connection: SIOConnection
            });
    }
)


var first = true;
// camera transformation based on the gyro sensor data
var handleOrientation = function(event)
{
    var absolute = event.absolute;
    var alpha    = event.alpha;
    var beta     = event.beta;
    var gamma    = event.gamma;

    if(wrtc && alpha && beta && gamma)  // check the gyro sensor data is not null
    {        
        wrtc.emit('gyro', 
                  {msg: 'from customer',
                   alpha: alpha,
                   beta: beta,
                   gamma: gamma,
                   absolute: absolute
                  });

    }    
}

function configSketch() {
    const c = document.getElementById("sketchCanvas");
    c.style.zIndex = 3;
    c.style.position = 'fixed';
    c.style.top = 0;
    c.style.left = 0;
    c.style.width = '100%';
    c.style.height = '100%';
    c.width = window.innerWidth;
    c.height = window.innerHeight;
}

function drawSketch(data) {
  let sCanvasCtx =  document.getElementById("sketchCanvas").getContext('2d');
  sCanvasCtx.beginPath();
  sCanvasCtx.lineWidth = 5;
  sCanvasCtx.lineCap = 'round';
  sCanvasCtx.strokeStyle = 'rgba(255, 255, 0, 1)';
  sCanvasCtx.moveTo(data.sX, data.sY); 
  sCanvasCtx.lineTo(data.eX, data.eY); 
  sCanvasCtx.stroke(); 
}

function clearSketch() {
  let sCanvas = document.getElementById("sketchCanvas");
  let sCanvasCtx = sCanvas.getContext('2d');
  sCanvasCtx.clearRect(0, 0, sCanvas.width, sCanvas.height);
}

if (isIOS() && typeof DeviceMotionEvent.requestPermission === 'function') {
    var dialog = $('#device-orientation-modal');
    dialog.find('.btn-primary').click(function() {
        DeviceOrientationEvent.requestPermission()
            .then(response => {
                if (response == 'granted') {
                    console.log('DeviceMotionEvent granted');
                    window.addEventListener('deviceorientation', handleOrientation)
                } else {
                    console.log('DeviceMotionEvent denied');
                    alert('Please turn on Motion & Orientation.\nSettings > Safari > Motion & Orientation Access');
                }
            })
            .catch(console.error)
            .finally(function() {
                dialog.modal('hide');
            });
    });


    DeviceOrientationEvent.requestPermission()
        .then(response => {
            if (response == 'granted') {
                window.addEventListener('deviceorientation', handleOrientation)
            }
        })
        .catch(function() {
            dialog.modal('show');
        });

} else {
    window.addEventListener("deviceorientation", handleOrientation, true);
}

configSketch();
window.addEventListener("resize", configSketch);

// How get video to opencv
// var canvas = $('<canvas id="canvasVideo" width="640" height="480" />')[0];
// var ctx    = canvas.getContext('2d');
// function updateFrame() {
//     var video = $('#video')[0];
//     ctx.drawImage(video, 0, 0, 640, 480);

//     let imgData = ctx.getImageData(0, 0, canvas.width, canvas.height);
//     let src = cv.matFromImageData(imgData);

//     requestAnimationFrame(updateFrame);
// }
// requestAnimationFrame(updateFrame);
