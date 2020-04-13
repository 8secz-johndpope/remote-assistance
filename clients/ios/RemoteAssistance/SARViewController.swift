import UIKit
import SceneKit
import ARKit
import Vision
//import Swifter
//import Fritz
import WebRTC

//let use_fritz = false
//let use_coreml_handdetector = false
let use_people_occlusion = true
let show_grid = false

class SARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {


    let mediaContraints = RTCMediaConstraints(mandatoryConstraints: [
        "OfferToReceiveAudio": "true",
        "OfferToReceiveVideo": "true",
    ], optionalConstraints: nil)

    // MARK: - IBOutlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var debugButton: UIButton!

    //var anchorSize: CGSize = CGSize(width: 10, height: 10)
    var buttons: [UIButton]!
    var currentTransform: CGAffineTransform = CGAffineTransform.identity
    var capturer:WRTCCustomCapturer!
//    var factory:RTCPeerConnectionFactory!
    var videoSource:RTCVideoSource!
    var socketManager:SocketIOManager = SocketIOManager.sharedInstance
    var pcs:[String:RTCPeerConnection] = [String:RTCPeerConnection]()
    var iceCandidates:[String:[RTCIceCandidate]] = [String:[RTCIceCandidate]]()
    var sid:String = ""
    var stream:RTCMediaStream!
    var wrtc:WRTCClient!

    var overlayContent: String = "empty"
    var orientation = UIInterfaceOrientation.landscapeRight// UIInterfaceOrientation.portrait//UIApplication.shared.statusBarOrientati
    var viewportSize: CGSize!// = self.sceneView.bounds.size
    //var correctedImage: UIImage?
    var textureImage: UIImage?
    var webView: UIWebView?//WKWebView?
    // MARK: - Internal properties used to identify the rectangle the user is selecting

//    let handDetector = HandDetector()
    // Displayed rectangle outline
    private var selectedRectangleOutlineLayer: CAShapeLayer?
    private var projectedRectangleOutlineLayer: CAShapeLayer?

    // Observed rectangle currently being touched
    private var selectedRectangleObservation: VNRectangleObservation?
    
    // The time the current rectangle selection was last updated
    private var selectedRectangleLastUpdated: Date?
    
    // Current touch location
    private var currTouchLocation: CGPoint?
    
    // Gets set to true when actively searching for rectangles in the current frame
    private var searchingForRectangles = false
    
    //var server = HttpServer()
    //var socketSession: WebSocketSession? = nil
    //var binaryImage: [UInt8] = []

    var maskNode : SCNNode!
    var maskMaterial : SCNMaterial!

    // MARK: - Rendered items
    
    // RectangleNodes with keys for rectangleObservation.uuid
    //private var rectangleNodes = [VNRectangleObservation:RectangleNode]()
    private var rectangleNodes = [SCNNode:RectangleNode]()
    // Used to lookup SurfaceNodes by planeAnchor and update them
    private var surfaceNodes = [ARPlaneAnchor:SurfaceNode]()
    
    let visionQueue = DispatchQueue(label: "com.fxpal.screenarqueue")

    func initMediaStream() {
        // create media stream
        let factory = self.wrtc.factory
        self.videoSource = self.wrtc.factory.videoSource()
        let capturer = WRTCCustomCapturer(delegate: videoSource)
        self.capturer = capturer


        self.stream = factory.mediaStream(withStreamId: "fxpal_stream_\(self.sid)")
        let audioSource = factory.audioSource(with: mediaContraints)
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "fxpal_audio0")
        let videoTrack = factory.videoTrack(with: self.videoSource, trackId: "fxpal_video0")
        self.stream.addVideoTrack(videoTrack)
        self.stream.addAudioTrack(audioTrack)

        self.wrtc.stream = self.stream
    }
    
    func initWebRTCClient() {
        self.wrtc = WRTCClient()
        self.wrtc.delegate = self
        
        // TODO: Remove these 2 lines
        self.wrtc.enableSpeaker(false)
        self.wrtc.setAudioEnabled(false)
    }

    /*func createHandMaskNode() {
        maskMaterial = SCNMaterial()
        maskMaterial.diffuse.contents = UIColor.blue
        maskMaterial.colorBufferWriteMask = .alpha // needs to be alpha to show original image above instead of black on white mask, other value=.all
        
        let rectangle = SCNPlane(width: 0.0326, height: 0.058)
        rectangle.materials = [maskMaterial]
        
        maskNode = SCNNode(geometry: rectangle)
        maskNode?.eulerAngles = SCNVector3Make(0, 0, Float.pi/2) // we are in landscape
        maskNode?.position = SCNVector3Make(0, 0, -0.05)
        maskNode.renderingOrder = -10
        
        
        sceneView.pointOfView?.presentation.addChildNode(maskNode!)
    }*/
    
    /*func createPeopleMaskNode() {
        maskMaterial = SCNMaterial()
        maskMaterial.diffuse.contents = UIColor.blue
        maskMaterial.colorBufferWriteMask = .all // needs to be alpha to show original image above instead of black on white mask, other value=.all
        //maskMaterial.diffuse.contentsTransform = SCNMatrix4MakeRotation(Float.pi/2, 0, 0, 1)
        let rectangle = SCNPlane(width: 0.0326, height: 0.058)
        rectangle.materials = [maskMaterial]
        
        maskNode = SCNNode(geometry: rectangle)
        maskNode?.eulerAngles = SCNVector3Make(0, 0, Float.pi/2) // we are in landscape
        maskNode?.position = SCNVector3Make(0, 0, -0.05)
        maskNode.renderingOrder = -10
        sceneView.pointOfView?.presentation.addChildNode(maskNode!)
    }*/

    // MARK: - Debug properties
    
    var showDebugOptions = false {
        didSet {
            if showDebugOptions {
                sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
            } else {
              sceneView.debugOptions = []
            }
        }
    }
    
    
    // MARK: - Message displayed to the user
    
    private var message: Message? {
        didSet {
            DispatchQueue.main.async {
                if let message = self.message {
                    self.messageView.isHidden = false
                    self.messageLabel.text = message.localizedString
                    self.messageLabel.numberOfLines = 0
                    self.messageLabel.sizeToFit()
                    self.messageLabel.superview?.setNeedsLayout()
                } else {
                    self.messageView.isHidden = true
                }
            }
        }
    }
    
    
    // MARK: - UIViewController
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
        
    
    /*private func createBox(width: CGFloat, height: CGFloat, color: UIColor) -> SCNNode {
        //let box = SCNBox(width: 0.15, height: 0.20, length: 0.00, chamferRadius: 0.02)
        let box = SCNBox(width: width, height: height, length: 0.002, chamferRadius: 0.02)
        //let box = SCNPlane(width:width,height:height)
        let green = SCNMaterial()
        green.diffuse.contents = color
        box.materials = [green]
        let boxNode = SCNNode(geometry: box)
        return boxNode
    }*/

    /*func addCornerBox(position: SCNVector3, sceneView: ARSCNView, name: String)
    {
        let box = createBox(width: 0.1, height: 0.1, color: UIColor.red)
        box.position = position
        sceneView.scene.rootNode.addChildNode(box)
        box.name = name
    }*/

    /*func createRemoteCorner(idx: Int, pt: CGPoint)
    {
        let hitTestResult = sceneView.hitTest(sceneView.convertFromCamera(pt), types: .existingPlaneUsingGeometry)
        if !hitTestResult.isEmpty {
            guard let hitResult = hitTestResult.first else {
                return
            }
            print("found point on plane")
            switch (idx) {
            case 0:
                addCornerBox(position: hitResult.worldVector, sceneView: self.sceneView, name: "tl")
            case 1:
                addCornerBox(position: hitResult.worldVector, sceneView: self.sceneView, name: "tr")
            case 2:
                addCornerBox(position: hitResult.worldVector, sceneView: self.sceneView, name: "bl")
            case 3:
                addCornerBox(position: hitResult.worldVector, sceneView: self.sceneView, name: "br")
            default:
                addCornerBox(position: hitResult.worldVector, sceneView: self.sceneView, name: "\(idx)")
            }
        }
    }*/

    func loadHTML()
    {
        if let filepath = Bundle.main.path(forResource: "overlay", ofType: "html") {
            do {
                overlayContent = try String(contentsOfFile: filepath)
            } catch {
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        orientation = UIApplication.shared.statusBarOrientation
        //orientation = (UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene!.interfaceOrientation)!
        self.loadHTML()
        self.webView = UIWebView(frame:CGRect(x:0,y:0,width: 640, height:480))
        //self.webView = WKWebView(frame:CGRect(x:0,y:0,width: 640, height:480))
        self.webView?.isOpaque = false
        self.webView?.backgroundColor = UIColor.clear
        self.webView?.scrollView.backgroundColor = UIColor.clear
        self.webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView?.loadHTMLString(overlayContent, baseURL: nil)
        //self.webView?.loadRequest(URLRequest(url: URL(string:"http://\(ipaddress):9080/overlay.html")!))
        // Set the view's delegates
        sceneView.delegate = self
        
        // Comment out to disable rectangle tracking
        sceneView.session.delegate = self
        
        // Show world origin and feature points if desired
        if showDebugOptions {
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        }

        // Enable default lighting
        sceneView.autoenablesDefaultLighting = true
        
        // Create a new scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Don't display message
        message = nil
        
        // Style clear button
        styleButton(clearButton, localizedTitle: NSLocalizedString("Clear Rects", comment: ""))
        styleButton(restartButton, localizedTitle: NSLocalizedString("Restart", comment: ""))
        styleButton(debugButton, localizedTitle: NSLocalizedString("Debug", comment: ""))
        debugButton.isSelected = showDebugOptions
        
        /*if use_fritz {
            createHandMaskNode()
        }
        else if use_coreml_handdetector {
            createHandMaskNode()
        }*/
        //else if use_people_occlusion {
        //    createPeopleMaskNode()
        //}
//        initFactory()
        initWebRTCClient()
        initMediaStream()
        
//        SocketIOManager.sharedInstance.connect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.wrtc.connect()
        
        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
                fatalError("Missing expected asset catalog resources.")
        }

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
      
        //print(ARWorldTrackingConfiguration.supportedVideoFormats)
        //configuration.videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats[1]
        // iPhone6S 1920, 1080 or 1280, 720
        // iPhoneX 1920, 1440 or 1280, 720
        configuration.isLightEstimationEnabled = true
        configuration.isAutoFocusEnabled = true

        if ARWorldTrackingConfiguration.supportsFrameSemantics(ARWorldTrackingConfiguration.FrameSemantics.personSegmentation) {
        print("personSegmentation is supported! Setting frameSemantics.")
        configuration.frameSemantics = .personSegmentation
        } else {
            print("personSegmentation not supported")
        }
            
        if ARWorldTrackingConfiguration.supportsFrameSemantics(ARWorldTrackingConfiguration.FrameSemantics.personSegmentationWithDepth) {
            print("personSegmentationWithDepth is supported! Ignoring for now.")
            //configuration.frameSemantics = .personSegmentationWithDepth
        } else {
            print("personSegmentationWithDepth not supported")
        }

        configuration.planeDetection = [.horizontal, .vertical]
    
        configuration.detectionImages = refImages
        configuration.maximumNumberOfTrackedImages = 1

        // Run the view's session
        sceneView.session.run(configuration)

        viewportSize = self.sceneView.frame.size
        let boundsize = self.sceneView.bounds.size
        orientation = UIApplication.shared.statusBarOrientation
        print("viewportsize=",viewportSize,"orientation=",orientation,"boundsize=",boundsize)
        // Tell user to find the a surface if we don't know of any
        if surfaceNodes.isEmpty {
            message = .helpFindSurface
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        // disconnect webrtc
        self.wrtc.disconnect()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
            let currentFrame = sceneView.session.currentFrame else {
            return
        }
        
        currTouchLocation = touch.location(in: sceneView)
        findRectangle(locationInScene: currTouchLocation!, frame: currentFrame)
        message = .helpTapReleaseRect
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ignore if we're currently searching for a rect
        if searchingForRectangles {
            return
        }
        
        guard let touch = touches.first,
            let currentFrame = sceneView.session.currentFrame else {
                return
        }
        
        currTouchLocation = touch.location(in: sceneView)
        findRectangle(locationInScene: currTouchLocation!, frame: currentFrame)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currTouchLocation = nil
        message = .helpTapHoldRect

        guard let selectedRect = selectedRectangleObservation else {
            return
        }
        
        DispatchQueue.main.async {
            // Create a planeRect and add a RectangleNode
            self.addPlaneRect(for: selectedRect, transform: self.currentTransform)
        }
    }
    
    // MARK: - IBOutlets
    
    @IBAction func onClearButton(_ sender: Any) {
        //self.nRemoteCorners = 0
        //self.points2d = nil
        //self.correctedImage = nil
        rectangleNodes.forEach({ $1.removeFromParentNode() })
        rectangleNodes.removeAll()
        if let layer = projectedRectangleOutlineLayer {
            layer.removeFromSuperlayer()
            projectedRectangleOutlineLayer = nil
        }
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
    }
    
    @IBAction func onRestartButton(_ sender: Any) {
        // Remove all rectangles
        rectangleNodes.forEach({ $1.removeFromParentNode() })
        rectangleNodes.removeAll()
        if let layer = projectedRectangleOutlineLayer {
            layer.removeFromSuperlayer()
            projectedRectangleOutlineLayer = nil
        }
        // Remove all surfaces and tell session to forget about anchors
        surfaceNodes.forEach { (anchor, surfaceNode) in
            sceneView.session.remove(anchor: anchor)
            surfaceNode.removeFromParentNode()
        }
        surfaceNodes.removeAll()
        
        // Update message
        message = .helpFindSurface
    }
    
    @IBAction func onDebugButton(_ sender: Any) {
        showDebugOptions = !showDebugOptions
        debugButton.isSelected = showDebugOptions
        
        if showDebugOptions {
            debugButton.layer.backgroundColor = UIColor.yellow.cgColor
            debugButton.layer.borderColor = UIColor.yellow.cgColor
        } else {
            debugButton.layer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
            debugButton.layer.borderColor = UIColor.white.cgColor
        }
    }
    
    // MARK: - ARSessionDelegate
    
    // Update selected rectangle if it's been more than 1 second and the screen is still being touched
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

        if searchingForRectangles {
            return
        }
        
        guard let currTouchLocation = currTouchLocation,
            let currentFrame = sceneView.session.currentFrame else {
                return
        }
        
        if selectedRectangleLastUpdated?.timeIntervalSinceNow ?? 0 < 1 {
            return
        }
        
        findRectangle(locationInScene: currTouchLocation, frame: currentFrame)
    }
    
    // MARK: - ARSCNViewDelegate
    
    private var lastTimeUpdate: TimeInterval = 0

    func sendAnchorSize(size: CGSize)
    {
        let anchorString = "\(Int(size.width * 2048)),\(Int(size.height*2048))"
        if let anchorData = anchorString.data(using: .utf8) {
            self.wrtc.sendData(anchorData)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer,
                  updateAtTime time: TimeInterval)
    {
        if time - lastTimeUpdate > 0.1
        {
            lastTimeUpdate = time;
            let image = self.sceneView.snapshot()
            if let coords = self.getPoints2D(imageSize: image.size) {
                if let borderedImage = self.imageWithBorderPoints(image: image, points: coords) {
                    let newSize: CGSize
                    // resize frame to a multiple of 32 pixels
                    // otherwise WebRTC seems to crop the frame
                    // making us lose the encoded corner points
                    if borderedImage.size.width > borderedImage.size.height {
                        newSize = CGSize(width:768, height:320)
                    }
                    else
                    {
                        newSize = CGSize(width:320,height:768)
                    }
                    if let resized = borderedImage.resize(to: newSize) {
                        self.capturer.captureFrame(resized)
                    }
                }
            }
            else
            {
                self.capturer.captureFrame(image)
            }
        }
    }

    func drawCornerPoints(context: CGContext?, rect: CGRect, points: [CGPoint])
    {
        let markSize: CGFloat = 8
        
        // draw an outline in BLACK around the frame
        // to make sure the WHITE blocks will be detected
        context?.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
        // top border black
        context?.fill(CGRect(x: 0, y: 0, width: rect.width, height: markSize))
        // bottom border black
        context?.fill(CGRect(x: 0, y: rect.height-markSize, width: rect.width, height: markSize))
        // left border black
        context?.fill(CGRect(x: 0, y: 0, width: markSize, height: rect.height))
        // right border black
        context?.fill(CGRect(x: rect.width-markSize, y: 0, width: markSize, height: rect.height))

        // now use WHITE to draw the blocks encoding the 4 points
        context?.setFillColor(red: 255, green: 255, blue: 255, alpha: 1)

        let tl = points[2]
        let tr = points[3]
        let bl = points[0]
        let br = points[1]

        // encode x positions of tl and tr on the top border
        context?.fill(CGRect(x: tl.x-4, y: 0, width: 8, height: markSize))
        context?.fill(CGRect(x: tr.x-4, y: 0, width: 8, height: markSize))
        // encode x positions of bl and br on the bottom border
        context?.fill(CGRect(x: bl.x-4, y: rect.size.height, width: 8, height: -markSize))
        context?.fill(CGRect(x: br.x-4, y: rect.size.height, width: 8, height: -markSize))
        // encode y positions of tl and bl on the left border
        context?.fill(CGRect(x: 0, y: tl.y-4, width: markSize, height: 8))
        context?.fill(CGRect(x: 0, y: bl.y-4, width: markSize, height: 8))
        // encode y positions of tr and br on the right border
        context?.fill(CGRect(x: rect.size.width, y: tr.y-4, width: -markSize, height: 8))
        context?.fill(CGRect(x: rect.size.width, y: br.y-4, width: -markSize, height: 8))
    }

    func imageWithBorderPoints(image: UIImage, points: [CGPoint]) -> UIImage?
    {
        let size = CGSize(width: image.size.width, height: image.size.height)
        UIGraphicsBeginImageContext(size)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        image.draw(in: rect, blendMode: .normal, alpha: 1.0)

        let context = UIGraphicsGetCurrentContext()
        self.drawCornerPoints(context: context, rect: rect, points: points)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor {
            print("found imageAnchor!")
            DispatchQueue.main.async {
                print("adding rectanglenode for imageanchor")
                self.removeCornerBoxes()
                let anchorSize = imageAnchor.referenceImage.physicalSize
                self.sendAnchorSize(size: anchorSize)
                let rectangleNode = RectangleNode(imageAnchor: imageAnchor, rootNode: node, view: self.webView!)
                self.rectangleNodes[node] = rectangleNode
            }
        }

        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        if (show_grid)
        {
            let surface = SurfaceNode(anchor: anchor)
            surfaceNodes[anchor] = surface
            node.addChildNode(surface)
        }

        if message == .helpFindSurface {
            message = .helpTapHoldRect
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let _ = anchor as? ARImageAnchor {
            // users might overlap the image anchor with their hands
            // so we don't hide the node even when the image anchor is not tracked
            /*if imageAnchor.isTracked {
                node.isHidden = false
            }
            else
            {
                //print("ref image not tracked")
                node.isHidden = true;
            }*/
        }

        if (show_grid)
        {
            // See if this is a plane we are currently rendering
            guard let anchor = anchor as? ARPlaneAnchor,
                let surface = surfaceNodes[anchor] else {
                    return
            }
            surface.update(anchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if (show_grid)
        {
            guard let anchor = anchor as? ARPlaneAnchor,
                let surface = surfaceNodes[anchor] else {
                    return
            }
            surface.removeFromParentNode()
            surfaceNodes.removeValue(forKey: anchor)
        }
    }
    
    // MARK: - Helper Methods
    
    // from https://stackoverflow.com/questions/54061482/how-to-translate-x-axis-correctly-from-vnfaceobservation-boundingbox-vision-a
    func visionTransform(frame: ARFrame, viewport: CGRect, orientation: UIInterfaceOrientation) -> CGAffineTransform {
        let transform = frame.displayTransform(for: orientation,
                                               viewportSize: viewport.size)
        let scale = CGAffineTransform(scaleX: viewport.width,
                                      y: viewport.height)

        var t = CGAffineTransform()
        if orientation.isPortrait {
            t = CGAffineTransform(scaleX: -1, y: 1)
            t = t.translatedBy(x: -viewport.width, y: 0)
        } else if orientation.isLandscape {
            t = CGAffineTransform(scaleX: 1, y: -1)
            t = t.translatedBy(x: 0, y: -viewport.height)
        }
        return transform.concatenating(scale).concatenating(t)
    }

    // Updates selectedRectangleObservation with the the rectangle found in the given ARFrame at the given location
    private func findRectangle(locationInScene location: CGPoint, frame currentFrame: ARFrame) {
        // Note that we're actively searching for rectangles
        searchingForRectangles = true
        selectedRectangleObservation = nil
        
        let capturedImage = currentFrame.capturedImage
        self.currentTransform = visionTransform(frame: currentFrame, viewport: self.sceneView.frame, orientation: self.orientation)

        // Perform request on background thread
        DispatchQueue.global(qos: .background).async {
            let request = VNDetectRectanglesRequest(completionHandler: { (request, error) in
                
                // Jump back onto the main thread
                DispatchQueue.main.async {
                    
                    // Mark that we've finished searching for rectangles
                    self.searchingForRectangles = false
                    
                    // Access the first result in the array after casting the array as a VNClassificationObservation array
                    guard let observations = request.results as? [VNRectangleObservation],
                        let _ = observations.first else {
                            print ("No results")
                            self.message = .errNoRect
                            return
                    }
                    
                    print("\(observations.count) rectangles found")
                    
                    // Remove outline for selected rectangle
                    if let layer = self.selectedRectangleOutlineLayer {
                        layer.removeFromSuperlayer()
                        self.selectedRectangleOutlineLayer = nil
                    }

                    // Find the rect that overlaps with the given location in sceneView
                    guard let selectedRect = observations.filter({ (result) -> Bool in
                        let convertedRect = result.boundingBox.applying(self.currentTransform)
                        return convertedRect.contains(location)
                    }).first else {
                        print("No results at touch location")
                        self.message = .errNoRect
                        return
                    }
                    
                    // Outline selected rectangle
                    let points = [selectedRect.topLeft, selectedRect.topRight, selectedRect.bottomRight, selectedRect.bottomLeft]
                    let convertedPoints = points.map { $0.applying(self.currentTransform) }

                    self.selectedRectangleOutlineLayer = self.drawPolygon(convertedPoints, color: UIColor.red)
                    self.sceneView.layer.addSublayer(self.selectedRectangleOutlineLayer!)
                    
                    // Track the selected rectangle and when it was found
                    self.selectedRectangleObservation = selectedRect
                    self.selectedRectangleLastUpdated = Date()
                    
                    // Check if the user stopped touching the screen while we were in the background.
                    // If so, then we should add the planeRect here instead of waiting for touches to end.
                    if self.currTouchLocation == nil {
                        // Create a planeRect and add a RectangleNode
                        DispatchQueue.main.async {
                            self.addPlaneRect(for: selectedRect, transform: self.currentTransform)
                        }
                    }
                }
            })
            
            // Don't limit resulting number of observations
            request.maximumObservations = 0
            // Note that the pixel buffer's orientation doesn't change even when the device rotates.
            let handler = VNImageRequestHandler(cvPixelBuffer: capturedImage, orientation: .up)
            try? handler.perform([request])
        }
    }

    private func addPlaneRect(for observedRect: VNRectangleObservation, transform: CGAffineTransform) {
        // Remove old outline of selected rectangle
        if let layer = selectedRectangleOutlineLayer {
            layer.removeFromSuperlayer()
            selectedRectangleOutlineLayer = nil
        }
        
        // Convert to 3D coordinates
        guard let planeRectangle = PlaneRectangle(for: observedRect, in: sceneView, transform: transform) else {
            print("No plane for this rectangle")
            message = .errNoPlaneForRect
            return
        }
        
        print("removing existing rectanglenodes")
        //self.rectangleNodes.forEach({ $1.removeFromParentNode() })
        //self.rectangleNodes.removeAll()
        print("removing corner boxes")
        self.removeCornerBoxes()

        let rectangleNode = RectangleNode(planeRectangle, view: self.webView!)
        //rectangleNodes[observedRect] = rectangleNode
        rectangleNodes[rectangleNode] = rectangleNode
        sceneView.scene.rootNode.addChildNode(rectangleNode)
        print("added rectangle node")
    }

    func removeCornerBoxes()
    {
        for name in ["tl","tr","br","bl"]
        {
            if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
                node.removeFromParentNode()
                print("removed node",name)
            }
        }
    }

    func getPoints2D(imageSize: CGSize) -> [CGPoint]?
    {
       guard let tl = sceneView.scene.rootNode.childNode(withName: "tl", recursively: true) else { return nil}
       guard let tr = sceneView.scene.rootNode.childNode(withName: "tr", recursively: true)  else { return nil}
       guard let bl = sceneView.scene.rootNode.childNode(withName: "bl", recursively: true)  else { return nil}
       guard let br = sceneView.scene.rootNode.childNode(withName: "br", recursively: true)  else { return nil}

       let worldTopLeft = tl.worldPosition
       let worldTopRight = tr.worldPosition
       let worldBottomLeft = bl.worldPosition
       let worldBottomRight = br.worldPosition

       let points = [
        self.sceneView.projectPoint(worldTopLeft),
        self.sceneView.projectPoint(worldTopRight),
        self.sceneView.projectPoint(worldBottomLeft),
        self.sceneView.projectPoint(worldBottomRight)
        ]
        
        for pt in points {
            if (pt.x < 0 || pt.y < 0) {
                return nil
            }
            if (CGFloat(pt.x) >= self.viewportSize.width || CGFloat(pt.y) >= self.viewportSize.height) {
                return nil
            }
        }
        
        let scalex = imageSize.width / self.viewportSize.width
        let scaley = imageSize.height / self.viewportSize.height
        let cgPoints: [CGPoint] = points.map {
            return CGPoint(x:scalex*CGFloat($0.x),y:scaley*CGFloat($0.y))
        }
        
        return cgPoints
    }

    /*func getPoints2D() -> String?
    {
        //let startTime = CFAbsoluteTimeGetCurrent()
        guard let tl = sceneView.scene.rootNode.childNode(withName: "tl", recursively: true) else { return nil}
        guard let tr = sceneView.scene.rootNode.childNode(withName: "tr", recursively: true)  else { return nil}
        guard let bl = sceneView.scene.rootNode.childNode(withName: "bl", recursively: true)  else { return nil}
        guard let br = sceneView.scene.rootNode.childNode(withName: "br", recursively: true)  else { return nil}

        let worldTopLeft = tl.worldPosition;
        let worldTopRight = tr.worldPosition;
        let worldBottomLeft = bl.worldPosition
        let worldBottomRight = br.worldPosition;

        // self.sceneView.projectPoint returns CGPoints in the self.sceneView.frame.size
        // we scale them because the webrtc stack might encode the images at different width/height
        // the web client will unscale properly using the received video frame size (/1024)
        let scalex = 2048 / Float(self.viewportSize.width)
        let scaley = 2048 / Float(self.viewportSize.height)

        let pos1 = self.sceneView.projectPoint(worldTopLeft);
        let pos2 = self.sceneView.projectPoint(worldTopRight);
        let pos3 = self.sceneView.projectPoint(worldBottomLeft);
        let pos4 = self.sceneView.projectPoint(worldBottomRight);

        /*DispatchQueue.main.async {
            self.buttons[0].frame = CGRect(x:CGFloat(pos1.x-10),y:CGFloat(pos1.y-10),width:20,height:20)
            self.buttons[1].frame = CGRect(x:CGFloat(pos2.x-10),y:CGFloat(pos2.y-10),width:20,height:20)
            self.buttons[2].frame = CGRect(x:CGFloat(pos3.x-10),y:CGFloat(pos3.y-10),width:20,height:20)
            self.buttons[3].frame = CGRect(x:CGFloat(pos4.x-10),y:CGFloat(pos4.y-10),width:20,height:20)
            
        }*/
 
        let str = "\(Int(pos1.x * scalex)),\(Int(pos1.y * scaley)),\(Int(pos2.x * scalex)),\(Int(pos2.y * scaley)),\(Int(pos3.x * scalex)),\(Int(pos3.y * scaley)),\(Int(pos4.x * scalex)),\(Int(pos4.y * scaley)),\(Int(self.anchorSize.width*2048)),\(Int(self.anchorSize.height*2048))"
        //let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        //print("\(title):: Time: \(timeElapsed)")
        return str
    }*/
   
    /*func remotePerspective(frame: ARFrame) -> UIImage?
    {
        func cartesianForPoint(point: CGPoint, extent: CGRect) -> CGPoint {
            //print(point.x,point.y)
            return CGPoint(x: point.x, y: extent.height - point.y)
        }
        let camera = frame.camera
        guard
            let snapshot = frame.getCapturedImage(orientation: self.orientation, viewportSize: self.viewportSize),
            let coreImage = CIImage(image: snapshot)
        else { return nil }
        guard let tl = sceneView.scene.rootNode.childNode(withName: "tl", recursively: true) else { return nil}
        guard let tr = sceneView.scene.rootNode.childNode(withName: "tr", recursively: true)  else { return nil}
        guard let bl = sceneView.scene.rootNode.childNode(withName: "bl", recursively: true)  else { return nil}
        guard let br = sceneView.scene.rootNode.childNode(withName: "br", recursively: true)  else { return nil}
        let pointsWorldSpace = [
            tr.simdWorldPosition,
            br.simdWorldPosition,
            bl.simdWorldPosition,
            tl.simdWorldPosition,
            ]

        let pointsImageSpace: [CGPoint] = pointsWorldSpace.map {
            var point = camera.projectPoint($0,
                                            orientation: orientation,
                                            viewportSize: self.viewportSize)
            point.x *= UIScreen.main.scale
            point.y *= UIScreen.main.scale
            return point
        }

        let topRight = pointsImageSpace[0]
        let bottomRight = pointsImageSpace[1]
        let bottomLeft = pointsImageSpace[2]
        let topLeft = pointsImageSpace[3]
        
        let deskewed = coreImage.perspectiveCorrected(
            topLeft: cartesianForPoint(point: topLeft, extent: coreImage.extent),
            topRight: cartesianForPoint(point: topRight, extent: coreImage.extent),
            bottomLeft: cartesianForPoint(point: bottomLeft, extent: coreImage.extent),
            bottomRight: cartesianForPoint(point: bottomRight, extent: coreImage.extent)
        )
        return UIImage(ciImage: deskewed)
        
    }*/

    

    // we fixed the app to always be in landscape mode
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewportSize = size
        coordinator.animate(alongsideTransition: nil) { _ in
            // Your code here
            self.orientation = UIApplication.shared.statusBarOrientation
            switch self.orientation {
            case .portrait, .unknown:
                print("portrait")
            case .landscapeLeft:
                print("landscapeLeft")
            case .landscapeRight:
                print("landscapeRight")
            case .portraitUpsideDown:
                print("portraitUpsideDown")
            }
            print("viewWillTransition orientation=",self.orientation,"size=",self.viewportSize)
        }
    }

    private func drawPolygon(_ points: [CGPoint], color: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.fillColor = nil
        layer.strokeColor = color.cgColor
        layer.lineWidth = 8
        let path = UIBezierPath()
        print(points[0])
        path.move(to: points.last!)
        /*for (index, point) in points.enumerated() {
            //print("Point \(index): \(point)")
            path.addLine(to: point)
            let textLayer = CATextLayer()
            textLayer.string = "\(index)"
            textLayer.frame = CGRect(x: point.x, y: point.y, width: 44, height: 44)
            layer.addSublayer(textLayer)
        }*/
        points.forEach { point in
            //print(point)
            path.addLine(to: point)
        }
        layer.path = path.cgPath
        
        /*let textLayer = CATextLayer()
        textLayer.string = "tl"
        textLayer.frame = CGRect(x: points[0].x, y: points[0].y, width: 44, height: 44)
        layer.addSublayer(textLayer)

        let textLayer2 = CATextLayer()
        textLayer2.string = "tr"
        textLayer2.frame = CGRect(x: points[1].x, y: points[1].y, width: 44, height: 44)
        layer.addSublayer(textLayer2)*/

        return layer
    }
    
    private func styleButton(_ button: UIButton, localizedTitle: String?) {
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
        button.setTitle(localizedTitle, for: .normal)
    }
}

extension SARViewController: WRTCClientDelegate {
    func wrtc(_ wrtc:WRTCClient, didAdd stream:RTCMediaStream) {
        print("wrtc: \(stream) add stream")
    }

    func wrtc(_ wrtc:WRTCClient, didRemove stream:RTCMediaStream) {
        print("wrtc: \(stream) remove stream")
    }

    func wrtc(_ wrtc:WRTCClient, didReceiveData data: Data) {
        let text = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
        print("wrtc: received datachannel message \(text)")
        let coords = text.components(separatedBy: ",")
        var textContent = ""
        if coords.count >= 3 {
            textContent = coords[2]
        }
        
        if let x = Int(coords[0]), let y = Int(coords[1]) {
            DispatchQueue.main.async {
                let js = "showMark(\(x),\(y),\"\(textContent)\",\"rectangle\")"
                //print("sending js=",js)
                self.webView?.stringByEvaluatingJavaScript(from: js)
                //self.webView?.evaluateJavaScript(js, completionHandler: { (res, err) in })
            }
        }
    }

}

extension Data {
    var bytes : [UInt8]{
        return [UInt8](self)
    }
}

extension CIImage {

    func perspectiveCorrected(topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        return self.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight),
        ])
    }

}

extension ARFrame {
    /**
     Gives the camera data in the given frame after scaling and cropping it
     in the same way Apple does it for constructing the backing image you
     can retrieve via `sceneView.snapshot()`.
     */
    func getCapturedImage(orientation: UIInterfaceOrientation, viewportSize: CGSize) -> UIImage? {
        let rawImage = getOrientationCorrectedCameraImage(forOrientation: orientation)
        //let viewportSize = sceneView.frame.size
        
        switch orientation {
            
        case .portrait, .portraitUpsideDown:
            guard let resized = rawImage?.resize(toHeight: viewportSize.height) else {
                return nil
            }
            return resized.crop(rect: CGRect(
                x: (resized.size.width - viewportSize.width) / 2,
                y: 0,
                width: viewportSize.width,
                height: viewportSize.height)
            )
            
        case .landscapeLeft, .landscapeRight:
            guard let resized = rawImage?.resize(toWidth: viewportSize.width) else {
                return nil
            }
            return resized.crop(rect: CGRect(
                x: 0,
                y: (resized.size.height - viewportSize.height) / 2,
                width: viewportSize.width,
                height: viewportSize.height)
            )
            
        case .unknown:
            return nil
        }
    }
    
}

extension ARFrame {
    /**
     Rotates the image from the camera to match the orientation of the device.
     */
    private func getOrientationCorrectedCameraImage(forOrientation orientation: UIInterfaceOrientation) -> UIImage? {
        var rotationRadians: Float = 0
        switch orientation {
        case .portrait:
            rotationRadians = .pi / 2
        case .portraitUpsideDown:
            rotationRadians = -.pi / 2
        case .landscapeLeft:
            rotationRadians = .pi
        case .landscapeRight:
            break
        case .unknown:
            return nil
        }
        return UIImage(pixelBuffer: capturedImage)?.rotate(radians: rotationRadians)
    }
    
}

import UIKit
import VideoToolbox

extension UIImage {
    
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        //VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        guard let image = cgImage else { return nil }
        self.init(cgImage: image)
    }
    
    public func crop(rect: CGRect) -> UIImage? {
        var rect = rect
        rect.origin.x *= scale
        rect.origin.y *= scale
        rect.size.width *= scale
        rect.size.height *= scale
        
        if let imageRef = cgImage?.cropping(to: rect) {
            return UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
    
    public func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Move origin to middle
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        
        self.draw(in: CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width, height: size.height
        ))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    public func getOrCreateCGImage() -> CGImage? {
        return cgImage ?? ciImage.flatMap {
            let context = CIContext()
            return context.createCGImage($0, from: $0.extent)
        }
    }
    
    /**
     Scales the image to the given height while preserving its aspect ratio.
     */
    public func resize(toHeight newHeight: CGFloat) -> UIImage? {
        guard self.size.height != newHeight else { return self }
        let ratio = newHeight / size.height
        let newSize = CGSize(width: size.width * ratio, height: newHeight)
        return resize(to: newSize)
    }
    
    /**
     Scales the image to the given width while preserving its aspect ratio.
     */
    public func resize(toWidth newWidth: CGFloat) -> UIImage? {
        guard self.size.width != newWidth else { return self }
        let ratio = newWidth / size.width
        let newSize = CGSize(width: newWidth, height: size.height * ratio)
        return resize(to: newSize)
    }
    
    public func resize(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
}

/*import CoreImage

extension CIImage {
    
    func perspectiveCorrected(topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        return self.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight),
            ])
    }
    
}*/

extension CVPixelBuffer {
    func makeTransparent(original: CVPixelBuffer) {
        // Get width and height of buffer
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        //print(width,height)
        //let width2 = CVPixelBufferGetWidth(original)
        //let height2 = CVPixelBufferGetHeight(original)
        //print("width2,height2=",width,height)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)

        // Lock buffer
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

        // Unlock buffer upon exiting
        defer {
            CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        }

        if let baseAddress = CVPixelBufferGetBaseAddress(self)/*, let obaseAddress = CVPixelBufferGetBaseAddress(original)*/ {
            let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
            //let obuffer = obaseAddress.assumingMemoryBound(to: UInt8.self)
            // we look at pixels from bottom to top
            for y in (0 ..< height).reversed() {
                for x in (0 ..< width).reversed() {
                    let pixel = buffer[y * bytesPerRow + x * 4]
                    if pixel == 0 {
                        buffer[y * bytesPerRow + x * 4 + 3 ] = 0 // laurent: set to transparent pixel
                    }
                }
            }
        }

    }
}
