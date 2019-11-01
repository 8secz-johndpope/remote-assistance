// note: before implementing based off of this, you can instead grab the boneHand plugin, which does this all for you,
// better than the way it is done here.
// https://developer.leapmotion.com/gallery/bone-hands
// If you prefer to see exactly how it all works, read on..

var colors = [0xff0000, 0x00ff00, 0x0000ff];
var baseBoneRotation = (new THREE.Quaternion).setFromEuler(
    new THREE.Euler(Math.PI / 2, 0, 0)
);

// setup sample video
var constraints = {
    video: {
        width: 1920,
        height: 1080
    }
}
var wrtc;
navigator.mediaDevices.getUserMedia(constraints).then(
    function(stream) {
        var video = $('#video')[0]
        video.srcObject = stream;
        video.autoplay = true;

        wrtc = new WebRTCClient({
            stream: stream
        });
    }
)

var SIOConnection = function (opts) {
    Leap.BrowserConnection.call(this, opts);
}
_.extend(SIOConnection.prototype, Leap.BrowserConnection.prototype);
SIOConnection.__proto__ = Leap.BrowserConnection;

SIOConnection.prototype.setupSocket = function() {
    var connection = this;
    var url = [window.location.protocol, '//', window.location.host, '/'].join('')
    var socket = io(url)
    socket.on('connection', function(socket) {
        connection.handleOpen();
    });
    socket.on('disconnect', function () {
        connection.handleClose(200, 'disconnect');
    });
    socket.on('frame', function(data) {
        connection.handleData(data);
    });
    return socket;
}


SIOConnection.prototype.handleData = function (data) {
    if (this.protocol === undefined) {
        Leap.BrowserConnection.prototype.handleData.call(this, JSON.stringify({ version: 6 }))
        var data = {
            "event": {
                "state": {
                    "attached": true,
                    "id": "LP89728733428",
                    "streaming": true,
                    "type": "Peripheral"
                },
                "type": "deviceEvent"
            }
        };
        Leap.BrowserConnection.prototype.handleData.call(this, JSON.stringify(data))
    } else {
        Leap.BrowserConnection.prototype.handleData.call(this, data)
    }
}
 
/*
Leap.loop({ background: true, connectionType: undefined }, {
    hand: function (hand) {

        hand.fingers.forEach(function (finger) {

            // This is the meat of the example - Positioning `the cylinders on every frame:
            finger.data('boneMeshes').forEach(function (mesh, i) {
                var bone = finger.bones[i];

                mesh.position.fromArray(bone.center());

                mesh.setRotationFromMatrix(
                    (new THREE.Matrix4).fromArray(bone.matrix())
                );

                mesh.quaternion.multiply(baseBoneRotation);
            });

            finger.data('jointMeshes').forEach(function (mesh, i) {
                var bone = finger.bones[i];

                if (bone) {
                    mesh.position.fromArray(bone.prevJoint);
                } else {
                    // special case for the finger tip joint sphere:
                    bone = finger.bones[i - 1];
                    mesh.position.fromArray(bone.nextJoint);
                }

            });

        });

        var armMesh = hand.data('armMesh');

        armMesh.position.fromArray(hand.arm.center());

        armMesh.setRotationFromMatrix(
            (new THREE.Matrix4).fromArray(hand.arm.matrix())
        );

        armMesh.quaternion.multiply(baseBoneRotation);

        armMesh.scale.x = hand.arm.width / 2;
        armMesh.scale.z = hand.arm.width / 4;

        renderer.render(scene, camera);

    }
})
    // these two LeapJS plugins, handHold and handEntry are available from leapjs-plugins, included above.
    // handHold provides hand.data
    // handEntry provides handFound/handLost events.
    .use('handHold')
    .use('handEntry')
    .on('handFound', function (hand) {

        hand.fingers.forEach(function (finger) {

            var boneMeshes = [];
            var jointMeshes = [];

            finger.bones.forEach(function (bone) {

                // create joints

                // CylinderGeometry(radiusTop, radiusBottom, height, radiusSegments, heightSegments, openEnded)
                var boneMesh = new THREE.Mesh(
                    new THREE.CylinderGeometry(5, 5, bone.length),
                    new THREE.MeshPhongMaterial()
                );

                boneMesh.material.color.setHex(0xffffff);
                scene.add(boneMesh);
                boneMeshes.push(boneMesh);
            });

            for (var i = 0; i < finger.bones.length + 1; i++) {

                var jointMesh = new THREE.Mesh(
                    new THREE.SphereGeometry(8),
                    new THREE.MeshPhongMaterial()
                );

                jointMesh.material.color.setHex(0x0088ce);
                scene.add(jointMesh);
                jointMeshes.push(jointMesh);

            }


            finger.data('boneMeshes', boneMeshes);
            finger.data('jointMeshes', jointMeshes);

        });

        if (hand.arm) { // 2.0.3+ have arm api,
            // CylinderGeometry(radiusTop, radiusBottom, height, radiusSegments, heightSegments, openEnded)
            var armMesh = new THREE.Mesh(
                new THREE.CylinderGeometry(1, 1, hand.arm.length, 64),
                new THREE.MeshPhongMaterial()
            );

            armMesh.material.color.setHex(0xffffff);

            scene.add(armMesh);

            hand.data('armMesh', armMesh);

        }

    })
    .on('handLost', function (hand) {

        hand.fingers.forEach(function (finger) {

            var boneMeshes = finger.data('boneMeshes');
            var jointMeshes = finger.data('jointMeshes');

            boneMeshes.forEach(function (mesh) {
                scene.remove(mesh);
            });

            jointMeshes.forEach(function (mesh) {
                scene.remove(mesh);
            });

            finger.data({
                boneMeshes: null,
                boneMeshes: null
            });

        });

        var armMesh = hand.data('armMesh');
        scene.remove(armMesh);
        hand.data('armMesh', null);

        renderer.render(scene, camera);

    })
    .connect();
*/

// all units in mm
var initScene = function () {
    window.scene = new THREE.Scene();
    window.renderer = new THREE.WebGLRenderer({
        alpha: true
    });

    window.renderer.setClearColor(0x000000, 0);
    window.renderer.setSize(window.innerWidth, window.innerHeight);

    window.renderer.domElement.style.position = 'fixed';
    window.renderer.domElement.style.top = 0;
    window.renderer.domElement.style.left = 0;
    window.renderer.domElement.style.width = '100%';
    window.renderer.domElement.style.height = '100%';

    document.body.appendChild(window.renderer.domElement);

    var directionalLight = new THREE.DirectionalLight(0xffffff, 1);
    directionalLight.position.set(0, 0.5, 1);
    window.scene.add(directionalLight);

    window.camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 1000);    
    window.camera.position.fromArray([0, 200, 700]);
    window.camera.lookAt(new THREE.Vector3(0, 200, 700));

    window.addEventListener('resize', function () {

        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
        return renderer.render(scene, camera);

    }, false);

    scene.add(camera);
    return renderer.render(scene, camera);
  
};

initScene();

var controller = new Leap.Controller({ enableGestures:true, background: true, connectionType: SIOConnection });
controller
    .use('riggedHand', 
         {
            parent: scene,
            renderer: renderer,
            renderFn: function() 
            {
                renderer.render(scene, camera);                
            },
            camera: camera,
            //boneLabels: function(boneMesh, leapHand) 
            //{
            //    if (boneMesh.name.indexOf('Finger_03') === 0) {
            //        return leapHand.pinchStrength;
            //    }
            //},
            boneColors: function(boneMesh, leapHand) 
            {
                if ((boneMesh.name.indexOf('Finger_0') === 0) || (boneMesh.name.indexOf('Finger_1') === 0)) {
                    return {
                        hue: 0.6,
                        saturation: 1.0 //leapHand.pinchStrength
                    };
                }
            }             
         }
         
        )
    .connect()
    .on('riggedHand.meshAdded', 
        function(handMesh, leapHand)
        {
            handMesh.material.opacity = 0.5;
        }
       );
/*
riggedHand = controller.plugins.riggedHand;
controller.use('boneHand', 
               {
                   renderer: riggedHand.renderer,
                   scene: riggedHand.parent,
                   camera: riggedHand.camera,
                   render: function() {}
               });
*/


var animate = function () {
    requestAnimationFrame( animate );
    renderer.render( scene, camera );
};

animate();