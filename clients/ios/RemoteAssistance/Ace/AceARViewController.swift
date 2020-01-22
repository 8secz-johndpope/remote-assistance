//
//  AceARViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/10/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import WebRTC
import CoreMotion

class AceARViewController : UIViewController {
    
    @IBOutlet var arView: ARSCNView!
    
    var capturer:WRTCCustomCapturer!
    var videoSource:RTCVideoSource!
    var socketManager:SocketIOManager = SocketIOManager.sharedInstance
    var pcs:[String:RTCPeerConnection] = [String:RTCPeerConnection]()
    var iceCandidates:[String:[RTCIceCandidate]] = [String:[RTCIceCandidate]]()
    var sid:String = ""
    var stream:RTCMediaStream!
    weak var wrtc:WRTCClient?
    var motionManager = CMMotionManager()
    var remoteHands:TSRemoteHands!
    var lastTimeStamp:TimeInterval = 0
    var configuration = ARWorldTrackingConfiguration()

    // ScreenAR
    var webView:UIWebView?
    var rectangleNodes = [SCNNode:RectangleNode]()
    let updateQueue = DispatchQueue(label: "com.fxpal.ace")
    
    // AR Pointer
    var arrowObject:AceVirtualObject?
    
    // VR
    var vrVC:AceVRViewController?
    
    // Object Annotation
    var objectGroupName:String!
    var videoTag:Int = -1
    var clickableImages:[UIImage]!
    var imagePositions:[SCNVector3]!
    var videoURLs:[URL]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    self.navigationController?.setNavigationBarHidden(true, animated: true)

        initWebRTCClient()
        initMediaStream()
        initARKit()
        initScreenAR()
        initARPointer()
        initObjectDetection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupAR()
        self.wrtc?.connect()
    }
    
    func setupAR() {
        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
                fatalError("Missing expected asset catalog resources.")
        }

        // Create a session configuration
      
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
        self.arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        rectangleNodes.forEach({ $1.removeFromParentNode() })
        rectangleNodes.removeAll()
        
        // Pause the view's session
        self.arView.session.pause()
        
        self.wrtc?.disconnect()
    }
    
    func initMediaStream() {
        self.videoSource = self.wrtc?.factory.videoSource()
        let capturer = WRTCCustomCapturer(delegate: self.videoSource)
        self.capturer = capturer

        
        let mediaContraints = RTCMediaConstraints(mandatoryConstraints: [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true",
        ], optionalConstraints: nil)

        if let factory = self.wrtc?.factory {
            self.stream = factory.mediaStream(withStreamId: "fxpal_stream_\(self.sid)")
            let audioSource = factory.audioSource(with: mediaContraints)
            let audioTrack = factory.audioTrack(with: audioSource, trackId: "fxpal_audio0")
            let videoTrack = factory.videoTrack(with: self.videoSource, trackId: "fxpal_video0")
            self.stream.addVideoTrack(videoTrack)
            self.stream.addAudioTrack(audioTrack)
            
            self.wrtc?.stream = self.stream
        }
    }
    
    func initWebRTCClient() {
        self.wrtc?.delegate = self
    }
        
    func initARKit() {
        self.arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.arView.scene = SCNScene()
        self.arView.autoenablesDefaultLighting = true;
        self.arView.delegate = self
        self.arView.session.delegate = self
    }

}

extension AceARViewController: WRTCClientDelegate {
    func wrtc(_ wrtc: WRTCClient, didReceiveData data: Data) {
        let text = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
        print("wrtc: received datachannel message \(text)")
    }

    func wrtc(_ wrtc:WRTCClient, didAdd stream:RTCMediaStream) {
        print("wrtc: \(stream) add stream")
    }

    func wrtc(_ wrtc:WRTCClient, didRemove stream:RTCMediaStream) {
        print("wrtc: \(stream) remove stream")
    }
}

extension AceARViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor {
            print("found imageAnchor!")
            DispatchQueue.main.async {
                print("adding rectanglenode for imageanchor")
                let rectangleNode = RectangleNode(imageAnchor: imageAnchor, rootNode: node, view: self.webView!)
                self.rectangleNodes[node] = rectangleNode
            }
        }
        objectAnnotation(renderer, didAdd:node, for:anchor)
    }
}

extension AceARViewController: ARSessionDelegate {
    
    func getPoints2D(imageSize: CGSize) -> [CGPoint]?
    {
       guard let tl = arView.scene.rootNode.childNode(withName: "tl", recursively: true) else { return nil}
       guard let tr = arView.scene.rootNode.childNode(withName: "tr", recursively: true)  else { return nil}
       guard let bl = arView.scene.rootNode.childNode(withName: "bl", recursively: true)  else { return nil}
       guard let br = arView.scene.rootNode.childNode(withName: "br", recursively: true)  else { return nil}

       let worldTopLeft = tl.worldPosition;
       let worldTopRight = tr.worldPosition;
       let worldBottomLeft = bl.worldPosition
       let worldBottomRight = br.worldPosition;

       let points = [
        self.arView.projectPoint(worldTopLeft),
        self.arView.projectPoint(worldTopRight),
        self.arView.projectPoint(worldBottomLeft),
        self.arView.projectPoint(worldBottomRight)
        ]
        
        let scalex = imageSize.width / self.view.frame.width
        let scaley = imageSize.height / self.view.frame.height
        let cgPoints: [CGPoint] = points.map {
            return CGPoint(x:scalex*CGFloat($0.x),y:scaley*CGFloat($0.y))
        }
        return cgPoints;
    }
        
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // If you want to render raw camera frame.
        // self.capturer.captureFrame(frame.capturedImage)
        
        // update vr view controller w/ new frame
        if let vrVC = self.vrVC {
            vrVC.lastFrame = frame
            vrVC.updateFrame()
        }

        let now = Date().timeIntervalSince1970

        if now - self.lastTimeStamp > 0.040 {
            let image = self.arView.snapshot()
            
            if let coords = self.getPoints2D(imageSize: image.size) {
                if let borderedImage = self.imageWithBorderPoints(image: image, points: coords) {
                    self.capturer.captureFrame(borderedImage)
                }
            } else {
                self.capturer.captureFrame(image)
            }
            self.lastTimeStamp = now
        }
    }
}

// AR SCreen

extension AceARViewController {
    
    func initScreenAR() {
        let overlayContent = self.loadHTML()
        self.webView = UIWebView(frame:CGRect(x:0,y:0,width: 640, height:480))
        //self.webView = WKWebView(frame:CGRect(x:0,y:0,width: 640, height:480))
        self.webView?.isOpaque = false
        self.webView?.backgroundColor = UIColor.clear
        self.webView?.scrollView.backgroundColor = UIColor.clear
        self.webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView?.loadHTMLString(overlayContent, baseURL: nil)
    }

    func loadHTML() -> String
    {
        do {
            if let filepath = Bundle.main.path(forResource: "overlay", ofType: "html") {
                let overlayContent = try String(contentsOfFile: filepath)
                return overlayContent
            }
        } catch {
            return ""
        }
        return ""
    }
    
    func imageWithBorderPoints(image: UIImage, points: [CGPoint]) -> UIImage?
    {
        let size = CGSize(width: image.size.width, height: image.size.height)
        UIGraphicsBeginImageContext(size)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        image.draw(in: rect, blendMode: .normal, alpha: 1.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1)
        //context?.setLineWidth(8)
        context?.stroke(rect, width: 8)
        context?.setFillColor(red: 255, green: 255, blue: 255, alpha: 1)

        /*let tl = points[0]
        let tr = points[1]
        let bl = points[2]
        let br = points[3]*/

        let tl = points[2]
        let tr = points[3]
        let bl = points[0]
        let br = points[1]

        let barheight: CGFloat = 16
        // encode x positions of tl and tr on the top border
        context?.fill(CGRect(x: tl.x-4, y: 0, width: 8, height: barheight))
        context?.fill(CGRect(x: tr.x-4, y: 0, width: 8, height: barheight))
        // encode x positions of bl and br on the bottom border
        context?.fill(CGRect(x: bl.x-4, y: size.height, width: 8, height: -barheight))
        context?.fill(CGRect(x: br.x-4, y: size.height, width: 8, height: -barheight))
        // encode y positions of tl and bl on the left border
        context?.fill(CGRect(x: 0, y: tl.y-4, width: barheight, height: 8))
        context?.fill(CGRect(x: 0, y: bl.y-4, width: barheight, height: 8))
        // encode y positions of tr and br on the right border
        context?.fill(CGRect(x: size.width, y: tr.y-4, width: -barheight, height: 8))
        context?.fill(CGRect(x: size.width, y: br.y-4, width: -barheight, height: 8))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @IBAction func onResetScreenAR(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.arView.session.pause()
            self.rectangleNodes.forEach({ $1.removeFromParentNode() })
            self.rectangleNodes.removeAll()
            self.arView.scene.rootNode.enumerateChildNodes { (node, stop) in
                node.removeFromParentNode()
            }
            self.arView.session.run(self.configuration, options: [.removeExistingAnchors, .resetTracking])
        }
    }
    
    @IBAction func onToggleVR(_ sender: Any) {
        // Toggle VR view
        if let vrVC = self.vrVC {
            self.arView.isHidden = false
            vrVC.view.removeFromSuperview()
            vrVC.removeFromParent()
            self.vrVC = nil
        } else {
            self.arView.isHidden = true
            let vc = AceVRViewController.instantiate(fromAppStoryboard: .Ace)
            vc.sceneView = self.arView
            vc.view.frame = self.view.frame
            vc.viewDidLoad()
            self.view.addSubview(vc.view)
            self.addChild(vc)
            self.vrVC = vc
        }
    }
}

extension AceARViewController {
    
    class PointerSet {
        var pos = CGPoint(x:0, y:0)
        var size = CGSize(width: 0, height: 0)
        
        func parse(_ data:[String:CGFloat]) -> PointerSet {
            if let x = data["x"] {
                pos.x = x
            }
            if let y = data["y"] {
                pos.y = y
            }
            if let cW = data["w"] {
                size.width = cW
            }
            if let cH = data["h"] {
                size.height = cH
            }
            return self
        }
        
        // reframe the start and end points to the phone display space
        func transformToFrame(_ frameSize: CGSize) -> PointerSet {
            let aspectRatio = frameSize.width/frameSize.height
            var scale:CGFloat = 1.0
            var offset = CGPoint(x: 0, y: 0)
            
            // if true, width is filled at the expert side
            var spanWidth = false

            if (size.width > size.height) {
                if (frameSize.width > frameSize.height) {
                    spanWidth = true
                } else {
                    spanWidth = false
                }
            } else {
                if (frameSize.width > frameSize.height) {
                    spanWidth = false
                } else {
                    spanWidth = true
                }
            }
            
            if spanWidth {
                scale = frameSize.width/size.width
                offset.x = 0
                offset.y = -(size.height - size.width/aspectRatio)/2
            } else {
                scale = frameSize.height/size.height
                offset.x = -(size.width - size.height*aspectRatio)/2
                offset.y = 0
            }
            
            // transform to screen space
            pos.x = (offset.x + pos.x)*scale
            pos.y = (offset.y + pos.y)*scale
            
            return self
        }
    }

    
    func initARPointer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.view.addGestureRecognizer(tap)
        self.arrowObject = AceVirtualObject.object(byName: "Arrow.scn")
        
        // animate
        let animation = CABasicAnimation(keyPath: "rotation")
        animation.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
        animation.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat.pi*2)))
        animation.duration = 3.0
        animation.autoreverses = false
        animation.repeatCount = .infinity
        self.arrowObject?.addAnimation(animation, forKey: "spinAround")
        
        // listen for pointer messages
        let socket = SocketIOManager.sharedInstance
        socket.on("pointer_set") { data, ack in
            for line in data {
                let msg = PointerSet()
                    .parse(line as! [String:CGFloat])
                    .transformToFrame(self.view.frame.size)
                self.setArrow(msg.pos)
            }
        }

        socket.on("pointer_clear") { data, ack in
            self.removeArrow()
        }

    }
    
    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        print("onTap from AceARViewController")
        
        let touchLocation = gesture.location(in: arView)
        setArrow(touchLocation)
    }
    
    func setArrow(_ point:CGPoint) {
        if let object = self.arrowObject {
            setDown(object, basedOn: point)
        }
    }
    
    func removeArrow() {
        if let object = self.arrowObject {
            removeAnchor(object)
        }
    }
    
    func setDown(_ object: AceVirtualObject, basedOn screenPos: CGPoint) {
        object.stopTrackedRaycast()
        
        // Prepare to update the object's anchor to the current location.
        object.shouldUpdateAnchor = true
        
        // Attempt to create a new tracked raycast from the current location.
        if let query = arView.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: object.allowedAlignment),
            let raycast = self.createTrackedRaycastAndSet3DPosition(of: object, from: query) {
            object.raycast = raycast
        } else {
            // If the tracked raycast did not succeed, simply update the anchor to the object's current position.
            object.shouldUpdateAnchor = false
            self.updateQueue.async {
                self.addOrUpdateAnchor(for: object)
            }
        }
    }
    
    func createTrackedRaycastAndSet3DPosition(of virtualObject: AceVirtualObject, from query: ARRaycastQuery,
                                              withInitialResult initialResult: ARRaycastResult? = nil) -> ARTrackedRaycast? {
        if let initialResult = initialResult {
            self.setTransform(of: virtualObject, with: initialResult)
        }
        
        return arView.session.trackedRaycast(query) { (results) in
            self.setVirtualObject3DPosition(results, with: virtualObject)
        }
    }
    
    // - Tag: ProcessRaycastResults
    private func setVirtualObject3DPosition(_ results: [ARRaycastResult], with virtualObject: AceVirtualObject) {
        
        guard let result = results.first else {
            fatalError("Unexpected case: the update handler is always supposed to return at least one result.")
        }
        
        self.setTransform(of: virtualObject, with: result)
        
        // If the virtual object is not yet in the scene, add it.
        if virtualObject.parent == nil {
            self.arView.scene.rootNode.addChildNode(virtualObject)
            virtualObject.shouldUpdateAnchor = true
        }
        
        if virtualObject.shouldUpdateAnchor {
            virtualObject.shouldUpdateAnchor = false
            self.updateQueue.async {
                self.addOrUpdateAnchor(for: virtualObject)
            }
        }
    }
    
    func setTransform(of virtualObject: AceVirtualObject, with result: ARRaycastResult) {
        virtualObject.simdWorldTransform = result.worldTransform
    }
    
    func addOrUpdateAnchor(for object: AceVirtualObject) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = object.anchor {
            arView.session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: object.simdWorldTransform)
        object.anchor = newAnchor
        arView.session.add(anchor: newAnchor)
    }

    func removeAnchor(_ object: AceVirtualObject) {
        if let anchor = object.anchor {
            arView.session.remove(anchor: anchor)
            object.removeFromParentNode()
        }
    }
}
