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
        //initObjectDetection()
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
        screenAR(renderer, didAdd:node, for:anchor)
        //objectAnnotation(renderer, didAdd:node, for:anchor)
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
