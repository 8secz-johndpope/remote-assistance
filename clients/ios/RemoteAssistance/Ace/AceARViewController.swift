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
    var poinerIdentifier:String = ""
    var pointerObjects:[String:AceVirtualObject] = [:]
    var textObjects:[String:AceVirtualText] = [:]
    
    // VR
    var vrVC:AceVRViewController?
    
    // Object Annotation
    var renderer:SCNSceneRenderer?
    var objectGroupName:String!
    var imageGroupName:String!
    var clickableImages:[UIImage]!
    var imagePositions:[SCNVector3]!
    var videoURLs:[URL]!
    var anchorFound = false
    var nodeFound:SCNNode?
    var recordingUuid:String?
    var clipThumbnailReady = false
    var clipReady = false
    var liveAnnotation = true
    var recordingUrl:URL?
    var clipNode = [String:ObjectAnnotationNode]()
    var objectTap:UITapGestureRecognizer?
    
    // mode
    var mode = "none"

    override func viewDidLoad() {
        super.viewDidLoad()
        
       initWebRTCClient()
       initMediaStream()
       initARKit()
       initScreenAR()
       initARPointer()
       initObjectDetection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)

        super.viewWillAppear(animated)
        self.setupAR()
        self.wrtc?.connect()
        self.objectAnnotationViewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        rectangleNodes.forEach({ $1.removeFromParentNode() })
        rectangleNodes.removeAll()
        
        // Pause the view's session
        self.arView.session.pause()
        
        self.objectAnnotationViewWillDisappear()
        self.arPointerVieWillDisappear()
    }
    
    func setupAR() {
//        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
//                fatalError("Missing expected asset catalog resources.")
//        }

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
    
//        configuration.detectionImages = refImages
        configuration.maximumNumberOfTrackedImages = 1
        
        // Run the view's session
        self.arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking, .stopTrackedRaycasts])
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
//        self.arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.arView.scene = SCNScene()
        self.arView.autoenablesDefaultLighting = true;
        self.arView.delegate = self
        self.arView.session.delegate = self
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

extension AceARViewController: WRTCClientDelegate {
    func wrtc(_ wrtc: WRTCClient, didReceiveData data: Data) {
        //let text = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
        //print("wrtc: received datachannel message \(text)")
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

    func wrtc(_ wrtc:WRTCClient, didAdd stream:RTCMediaStream) {
        print("wrtc: \(stream) add stream")
        if let dict = UserDefaults.standard.object(forKey: "conversation_archive") as? [String:Any] {
            SocketIOManager.sharedInstance.emit("conversation_archive", dict)
        }
    }

    func wrtc(_ wrtc:WRTCClient, didRemove stream:RTCMediaStream) {
        print("wrtc: \(stream) remove stream")
    }
}

extension AceARViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        self.renderer = renderer
        screenAR(renderer, didAdd:node, for:anchor)
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
        
        // make sure all corners are in the frame
        for pt in points {
            if (pt.x < 0 || pt.y < 0) {
                return nil
            }
            if (CGFloat(pt.x) >= imageSize.width || CGFloat(pt.y) >= imageSize.height) {
                return nil
            }
        }

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
            } else {
                self.capturer.captureFrame(image)
            }

            self.lastTimeStamp = now
        }
    }
}
