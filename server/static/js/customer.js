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
      || navigator.userAgent.match(/AppleWebKit/i)
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
var renderer = new Renderer( 
    {add_interaction_box: false,
     add_line_object: false,
     add_leapmotion_device: false}, 
    SIOConnection );

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
            stream: stream
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
            renderer.updateCameraByParameter(data.position, data.quaternion);
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

    if(alpha && beta && gamma)  // check the gyro sensor data is not null
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
