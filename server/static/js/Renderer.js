// This requires three.js: <script src="three.js"></script>

Renderer = function ( parameters ) {
    var scope = this;

    this.parameters = parameters;

    var SIOConnection = parameters.sio_connection;
    var domElement = parameters.dom_element;
    var videoElement = parameters.video_element;
    var sketchCanvas = parameters.sketch_canvas;

    this.default_distance = 500;
    this.default_height = 200;

    this.domElement = ( domElement !== undefined ) ? domElement : document.body;
    this.connected = false;

    //// scene
    this.scene = new THREE.Scene();

    //// renderer
    this.renderer = new THREE.WebGLRenderer({alpha: true});
    this.renderer.setClearColor(0x000000, 0);
    this.renderer.setSize(window.innerWidth, window.innerHeight);

    // create composite canvas
    this.canvas = document.createElement('canvas');
    this.canvas2d = this.canvas.getContext('2d');
    this.canvas.style.position = 'fixed';
    this.canvas.style.top = 0;
    this.canvas.style.left = 0;
    this.canvas.style.width = '100%';
    this.canvas.style.height = '100%';
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
    this.canvas.style.zIndex = 2;
    this.domElement.appendChild(this.canvas);

    //// light
    this.light = new THREE.DirectionalLight(0xffffff, 1);
    this.light.position.set(0, 700, 100);
    this.scene.add(this.light);

    this.light2 = new THREE.DirectionalLight(0xffffff, 1);
    this.light2.position.set(0, -500, 100);
    this.scene.add(this.light2);

    //// camera
    var aspect = window.innerWidth / window.innerHeight;
    this.cameraPerspective = new THREE.PerspectiveCamera(45, aspect, 1, 5000);
    this.cameraPerspective.position.fromArray([0, 200, 700]);
    this.cameraPerspective.lookAt(new THREE.Vector3(0, 200, 0));
    this.cameraPerspective.updateProjectionMatrix();
    this.scene.add(this.cameraPerspective);

    //// orthographic camera
    var frustumSize = 600;
    this.cameraOrtho = new THREE.OrthographicCamera( frustumSize * aspect / - 2, frustumSize * aspect / 2, frustumSize / 2, frustumSize / - 2, 1, 1000 );
    this.cameraOrtho.position.fromArray([0, 200, 700]);
    this.cameraOrtho.lookAt(new THREE.Vector3(0, 200, 0));
    this.scene.add(this.cameraOrtho);
    
    this.camera = this.cameraPerspective;


    //// leapmotion transformation class
    this.leapmotion_trans = new LeapmotionTrans({
        d_init: this.default_distance
    });    
    
    //// options
    this.tracking = true;
    this.align_normal = false;
    this.gesture = false;

    //// threejs objects
    this.ib_y_offset = 200;
    if(this.parameters.add_interaction_box)
    {
        /*var geometry = new THREE.CircleGeometry( 120, 32 );
        var meshMaterial = new THREE.MeshPhongMaterial( { color: 0x156289, 
                                                          emissive: 0x072534, 
                                                          side: THREE.DoubleSide, 
                                                          flatShading: true,
                                                          opacity: 0.1 } );
        var circle = new THREE.Mesh( geometry, meshMaterial );
        circle.rotation.x += Math.PI/2;
        circle.position.y = 80;
        this.scene.add( circle );
        */

        //// interaction box        
        var backGeometry = new THREE.Geometry();
        backGeometry.vertices.push(new THREE.Vector3( 120, 120, 120 ) );
        backGeometry.vertices.push(new THREE.Vector3( 120, 120, -120 ) );
        backGeometry.vertices.push(new THREE.Vector3( 120, -120, -120 ) );
        backGeometry.vertices.push(new THREE.Vector3( 120, -120, 120 ) );
        backGeometry.vertices.push(new THREE.Vector3( 120, -120, -120 ) );
        backGeometry.vertices.push(new THREE.Vector3( -120, -120, -120 ) );
        backGeometry.vertices.push(new THREE.Vector3( -120, -120, 120 ) );
        backGeometry.vertices.push(new THREE.Vector3( -120, -120, -120 ) );
        backGeometry.vertices.push(new THREE.Vector3( -120, 120, -120 ) );
        backGeometry.vertices.push(new THREE.Vector3( -120, 120, 120 ) );
        backGeometry.vertices.push(new THREE.Vector3( -120, 120, -120 ) );
        backGeometry.vertices.push(new THREE.Vector3( 120, 120, -120 ) );

        var blueMaterial = new THREE.LineBasicMaterial( { color: 0x86c9e8, linewidth: 3 } );
        var backBox = new THREE.Line( backGeometry, blueMaterial );

        var frontGeometry = new THREE.Geometry();
        frontGeometry.vertices.push(new THREE.Vector3( 120, 120, 120 ) );
        frontGeometry.vertices.push(new THREE.Vector3( 120, -120, 120 ) );
        frontGeometry.vertices.push(new THREE.Vector3( -120, -120, 120 ) );
        frontGeometry.vertices.push(new THREE.Vector3( -120, 120, 120 ) );
        frontGeometry.vertices.push(new THREE.Vector3( 120, 120, 120 ) );
        var redMaterial = new THREE.LineBasicMaterial( { color: 0xff0000, linewidth: 3 } );
        var frontBox = new THREE.Line( frontGeometry, redMaterial );


        this.interaction_box = new THREE.Group();
        this.interaction_box.add(backBox);
        this.interaction_box.add(frontBox);
        this.interaction_box.position.copy(new THREE.Vector3(0,this.ib_y_offset,0));
        this.scene.add( this.interaction_box );
        
    }

    if(this.parameters.add_leapmotion_device)
    {
        // load leap motion box       
        var loader = new THREE.OBJMTLLoader();
        loader.load( '/static/models/leap_motion/leap_motion.obj', '/static/models/leap_motion/leap_motion.mtl', function ( object ) {
            object.rotation.x = -Math.PI/2;
            scope.scene.add( object );
        }, console.log, console.error );
    }

    if(this.parameters.add_line_object)
    {
        //create a blue LineBasicMaterial
        var material = new THREE.LineBasicMaterial( { color: 0x0000ff, linewidth: 3 } );
        var geometry = new THREE.Geometry();
        geometry.vertices.push(new THREE.Vector3( 0, 200, 100) );
        geometry.vertices.push(new THREE.Vector3( 0, 200, -100) );
        geometry.vertices.push(new THREE.Vector3( 10, 200, -100) );
        geometry.vertices.push(new THREE.Vector3( 0, 200, -110) );
        geometry.vertices.push(new THREE.Vector3( -10, 200, -100) );
        geometry.vertices.push(new THREE.Vector3( 10, 200, -100) );

        var line = new THREE.Line( geometry, material );
        this.scene.add(line);
    }

    // pencil
    this.pencil = new THREE.Group();    
    var loader = new THREE.OBJMTLLoader();
    loader.load( '/static/models/pencil/pencil.obj', '/static/models/pencil/pencil.mtl', function ( object ) {                        
        scope.pencil.add(object);        
    }, console.log, console.error );
    this.scene.add( this.pencil );
    this.pencil.visible = false; 
    
    //// circular_arrow
    this.circular_arrow = new THREE.Group();    
    //var loader = new THREE.OBJMTLLoader();
    loader.load( '/static/models/circularArrow/arrow.obj', '/static/models/circularArrow/arrow.mtl', function ( object ) {                              
        object.children[0].children[2].material.opacity = 0.5;
        scope.circular_arrow.add(object);        
    }, console.log, console.error );
    this.scene.add( this.circular_arrow );
    this.circular_arrow.visible = false;
    

    //// resize event
    window.addEventListener( 'resize', onWindowResize, false );

    //
	// internals
    //
    function onWindowResize()
    {
        scope.camera.aspect = window.innerWidth / window.innerHeight;
        scope.camera.updateProjectionMatrix();

        scope.renderer.setSize( window.innerWidth, window.innerHeight );

        scope.canvas.width = window.innerWidth;
        scope.canvas.height = window.innerHeight;
    }

    function animate()
    {
        requestAnimationFrame( animate );

        var canvas = scope.canvas;
        var ctx = scope.canvas2d;

        // clear canvas
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // render video if exists
        if (scope.parameters.video_element && scope.parameters.video_element.videoWidth && scope.parameters.video_element.videoHeight) {
            var x,y,width,height;
            var videoWidth = scope.parameters.video_element.videoWidth;
            var videoHeight = scope.parameters.video_element.videoHeight;
            var aspectRatio = scope.parameters.video_element.videoWidth/scope.parameters.video_element.videoHeight;

            // try max height
            height = canvas.height;
            width = Math.round(aspectRatio*height);
            if (width < canvas.width) {
                x = (canvas.width - width)/2;
                y = 0;
            } else {
                width = canvas.width;
                height = Math.round(width/aspectRatio);
                x = 0;
                y = (canvas.height - height)/2;
            }

            //console.log(x,y,width,height)
            var offset = 16;
            ctx.drawImage(scope.parameters.video_element, offset, offset, videoWidth - 2*offset, videoHeight - 2*offset, x, y, width, height);
        }

        // render sketch canvas
        if (typeof sketchCanvas !== 'undefined') {
           ctx.drawImage(sketchCanvas,0,0);            
        }

        // render threejs
        if (lmConnected) {
            scope.renderer.render( scope.scene, scope.camera );
        } 

        // compose video and threejs
        ctx.drawImage(scope.renderer.domElement, 0, 0, canvas.width, canvas.height);
        if (typeof sar !== 'undefined') {
            sar.animate(ctx.canvas);
        }
    }


    //// Leap motion rigged hand rendering
    var controller = new Leap.Controller({ enableGestures:true, background: true, connectionType: SIOConnection });
    controller
    .use('riggedHand',
         {
            parent: scope.scene,
            renderer: scope.renderer,
            renderFn: function()
            {
                scope.renderer.render(scope.scene, scope.camera);
            },
            camera: scope.camera,
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
                        hue: 1.0,
			
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
       )
    .on('frame', onFrame)
    .on("gesture", onGesture);

    // leap js's 'frame' callback function
    function onFrame(frame){
        //// tool
        if(frame.tools.length>0)
            scope.pencil.visible = true;
        else
            scope.pencil.visible = false;
        for(i=0; i<frame.tools.length; i++)
        {            
            var tool = frame.tools[i];
            scope.pencil.position.x = tool.stabilizedTipPosition[0];
            scope.pencil.position.y = tool.stabilizedTipPosition[1];
            scope.pencil.position.z = tool.stabilizedTipPosition[2];

            var n = new THREE.Vector3(tool.direction[0], tool.direction[1], tool.direction[2]).normalize();
            var a = new THREE.Vector3(0,0,1).cross(n).normalize();
            var quaternion = new THREE.Quaternion();
            quaternion.setFromAxisAngle( a, Math.acos(n.z) );
            scope.pencil.quaternion.copy(quaternion);
        }

        //// gestures
        if(scope.gesture)
        {
            for(i=0; i<frame.gestures.length; i++)
            {
                var gesture = frame.gestures[i];

                // render gestures if they are from the index finger or tool            
                for(j=0; j<gesture.pointableIds.length; j++)
                {
                    var pointable = frame.pointable(gesture.pointableIds[j]);
                    if(pointable.tool || pointable.type == 1)
                    {                    
                        switch (gesture.type) 
                        {
                            case "circle":                    
                                scope.circular_arrow.position.x = gesture.center[0];
                                scope.circular_arrow.position.y = gesture.center[1];
                                scope.circular_arrow.position.z = gesture.center[2];

                                // snap the normal to the closet axis.
                                var n_array = [0,0,0];
                                if(scope.align_normal)
                                {
                                    var result = Array.from(Array(3).keys())
                                                .sort((a, b) => Math.abs(gesture.normal[a]) < Math.abs(gesture.normal[b]) ? -1 : (Math.abs(gesture.normal[b]) < Math.abs(gesture.normal[a])) | 0);
                                    n_array[result[2]] = Math.sign(gesture.normal[result[2]]);                                
                                }
                                else
                                {
                                    n_array = gesture.normal;
                                }
                                console.log(n_array);

                                var n = new THREE.Vector3(n_array[0],n_array[1],n_array[2]).normalize();
                                var a = new THREE.Vector3(0,0,1).cross(n).normalize();
                                var quaternion = new THREE.Quaternion();
                                quaternion.setFromAxisAngle( a, Math.acos(n.z) );
                                scope.circular_arrow.quaternion.copy(quaternion);

                                scope.circular_arrow.scale.copy(new THREE.Vector3(gesture.radius,gesture.radius,gesture.radius));
                                                                                        
                                if(gesture.state != 'stop')
                                {
                                    scope.circular_arrow.visible = true;
                                }
                                else
                                {
                                    scope.circular_arrow.visible = false;
                                }                                

                                break;                        
                        }
                    }
                }
            }
        }

        if(scope.parameters.add_interaction_box)
        {            
            /*
            var box = frame.interactionBox;
            if (box) {
                var scale = box.width/scope.interaction_box.geometry.parameters.width;
                scope.interaction_box.scale.copy(new THREE.Vector3(scale, scale, scale));
                scope.interaction_box.position.copy(new THREE.Vector3(box.center[0], box.center[1], box.center[2]));
            }
            */
        }
    }

    function onGesture(gesture)
    {
        

    }

    //-----------------------------------------------------------------------------------------
	// public methods
    //

    this.getCanvas = function() {
        return this.canvas;
    }
   
    //// leapmotion space transformation
    this.rotateCameraBody = function(alpha, beta, gamma)
    {   
        this.leapmotion_trans.rotateCameraBody(alpha, beta, gamma);
    }

    this.moveLeapmotionSpace = function(dx, dy, dz)
    {
        this.leapmotion_trans.moveLeapmotionSpace(dx, dy, dz);
    }

    this.moveLeapmotionSpaceByClick = function(client_x, client_y)
    {
        this.leapmotion_trans.moveLeapmotionSpaceByClick(client_x, client_y, 
            scope.camera.projectionMatrix,
            scope.ib_y_offset);
    }
    
    this.alignLeapmotionSpace = function()
    {
        if(scope.tracking)
        {
            this.leapmotion_trans.alignLeapmotionSpaceToGround();
        }
        else
        {
            this.leapmotion_trans.alignLeapmotionSpaceToCamera();
        }
    }

    this.rotateLeapmotionSpace = function(dtheta)   // in degree
    {
        this.leapmotion_trans.rotateLeapmotionSpace(dtheta);
    }

    this.zoominoutCamera = function(delta)
    {
        this.leapmotion_trans.zoominoutCamera(delta);
    }

    this.setCameraDistance = function(d)
    {
        this.leapmotion_trans.setCameraDistance(d);
    }
    
    this.resetCameraParam = function()
    {
        this.leapmotion_trans.reset();        
    }

    this.updateCamera = function()
    {
        pose = this.leapmotion_trans.getCameraPose();    
        scope.camera.position.copy(pose[0]);
        scope.camera.quaternion.copy(pose[1]);        
    }

    this.updateCameraByParameter = function(position, quaternion)
    {        
        scope.camera.position.copy(position);
        scope.camera.quaternion._w = quaternion._w;
        scope.camera.quaternion._x = quaternion._x;
        scope.camera.quaternion._y = quaternion._y;
        scope.camera.quaternion._z = quaternion._z;
        //scope.camera.quaternion.copy(quaternion);
    }

    this.updateCameraType = function(type)
    {
        switch (type)
        {
            case "P":
                scope.camera = scope.cameraPerspective;
                break;
            case "O":
                scope.camera = scope.cameraOrtho;
                break;
        }
    }

    this.toggleTrackingMode = function()
    {
        scope.tracking = !scope.tracking;
        //reset
        this.camera.position.fromArray([0, 200, 700]);
        this.camera.lookAt(new THREE.Vector3(0, 200, 0));        
    }

    this.toggleAlignNormalMode = function()
    {
        scope.align_normal = !scope.align_normal;
    }
    this.toggleGestureMode = function()
    {
        scope.gesture = !scope.gesture;
    }

    //// animate
    animate();
}
