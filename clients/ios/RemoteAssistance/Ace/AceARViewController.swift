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
    var wrtc:WRTCClient = WRTCClient()
    var motionManager = CMMotionManager()
    var remoteHands:TSRemoteHands!
    var lastTimeStamp:TimeInterval = 0

    // ScreenAR
    var webView:UIWebView?
    var rectangleNodes = [SCNNode:RectangleNode]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
    self.navigationController?.setNavigationBarHidden(true, animated: true)

        initWebRTCClient()
        initMediaStream()
        initARKit()
        initScreenAR()
        
//        SocketIOManager.sharedInstance.connect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
        self.arView.session.run(configuration)
        
        self.wrtc.connect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        rectangleNodes.forEach({ $1.removeFromParentNode() })
        rectangleNodes.removeAll()
        
        // Pause the view's session
        self.arView.session.pause()
        
        self.wrtc.disconnect()
    }
    
    func initMediaStream() {
        let factory = self.wrtc.factory
        self.videoSource = self.wrtc.factory.videoSource()
        let capturer = WRTCCustomCapturer(delegate: self.videoSource)
        self.capturer = capturer

        
        let mediaContraints = RTCMediaConstraints(mandatoryConstraints: [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true",
        ], optionalConstraints: nil)

        self.stream = factory.mediaStream(withStreamId: "fxpal_stream_\(self.sid)")
        let audioSource = factory.audioSource(with: mediaContraints)
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "fxpal_audio0")
        let videoTrack = factory.videoTrack(with: self.videoSource, trackId: "fxpal_video0")
        self.stream.addVideoTrack(videoTrack)
        self.stream.addAudioTrack(audioTrack)
        
        self.wrtc.stream = self.stream
    }
    
    func initWebRTCClient() {
        self.wrtc.delegate = self
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

}
