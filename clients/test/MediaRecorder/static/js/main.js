let mediaRecorder;
let mediaStream;
let ws;

document.addEventListener('DOMContentLoaded', () => {
    navigator.mediaDevices.getUserMedia({
        video: true,
        audio: true
    }).then(function(stream) {
        const video = document.querySelector('video');
        video.srcObject = stream;
        mediaStream = stream;
    });

    document.querySelector('[data-action="record"]').addEventListener('click', (e) => {
        ws = new WebSocket(
          window.location.protocol.replace('http', 'ws') + '//' + // http: => ws:, https: -> wss:
          window.location.host +
          '/rtmp/'
        //    +
        //   encodeURIComponent(createRes.stream_url)
        );

        ws.addEventListener('open', (e) => {
          console.log('WebSocket Open', e);
          mediaRecorder = new MediaRecorder(mediaStream, {
            mimeType: 'video/webm',
            videoBitsPerSecond : 3000000
          });

          mediaRecorder.addEventListener('dataavailable', (e) => {
            ws.send(e.data);
          });

          mediaRecorder.addEventListener('stop', ws.close.bind(ws));

          mediaRecorder.start(1000); // Start recording, and dump data every second
        });

        ws.addEventListener('close', (e) => {
          console.log('WebSocket Close', e);
          mediaRecorder.stop();
        });
     });

     document.querySelector('[data-action="stop"]').addEventListener('click', (e) => {
        ws.close();
        var video = document.getElementById('play')
        video.src = '/static/recording.webm?t=' + Date.now();
        video.play();
     });
  });