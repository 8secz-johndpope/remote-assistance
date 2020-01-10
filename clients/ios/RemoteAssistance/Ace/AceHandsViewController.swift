//
//  TSViewController.swift
//  teleskele
//
//  Created by Yulius Tjahjadi on 9/27/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import UIKit
import WebRTC
import CoreMotion
import SceneKit

class AceHandsViewController: UIViewController {

    @IBOutlet var handView: SCNView!
    
    static let mediaContraints = RTCMediaConstraints(mandatoryConstraints: [
        "OfferToReceiveAudio": "true",
        "OfferToReceiveVideo": "true",
    ], optionalConstraints: nil)

    static let offerAnswerContraints = RTCMediaConstraints(mandatoryConstraints: [String:String](), optionalConstraints: nil)
    
    var capturer:WRTCCustomCapturer!
    var videoSource:RTCVideoSource!
    var socketManager:SocketIOManager = SocketIOManager.sharedInstance
    var pcs:[String:RTCPeerConnection] = [String:RTCPeerConnection]()
    var iceCandidates:[String:[RTCIceCandidate]] = [String:[RTCIceCandidate]]()
    var sid:String = ""
    var stream:RTCMediaStream!
    var wrtc:WRTCClient!
    var motionManager = CMMotionManager()
    var remoteHands:TSRemoteHands!
    var lastTimeStamp:TimeInterval = 0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        initWebRTCClient()
        initMediaStream()
        initRemoteHands()
        initGyro()
        
        SocketIOManager.sharedInstance.connect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.wrtc.disconnect()
        self.remoteHands.cleanup();
    }
    
    func initMediaStream() {
        let factory = self.wrtc.factory
        self.videoSource = self.wrtc.factory.videoSource()
        let capturer = WRTCCustomCapturer(delegate: self.videoSource)
        self.capturer = capturer


        self.stream = factory.mediaStream(withStreamId: "fxpal_stream_\(self.sid)")
        let audioSource = factory.audioSource(with: AceHandsViewController.mediaContraints)
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "fxpal_audio0")
        let videoTrack = factory.videoTrack(with: self.videoSource, trackId: "fxpal_video0")
        self.stream.addVideoTrack(videoTrack)
        self.stream.addAudioTrack(audioTrack)
        
        self.wrtc.stream = self.stream
    }
    
    func initWebRTCClient() {
        self.wrtc = WRTCClient()
        self.wrtc.delegate = self
    }
    
    func initGyro() {
        motionManager.deviceMotionUpdateInterval = 0.016
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (gyroData, error) in
            if let data = gyroData {
                let absolute = true
                let alpha = -data.attitude.yaw * 180 / Double.pi
                let beta = -data.attitude.pitch * 180 / Double.pi
                let gamma = -data.attitude.roll * 180 / Double.pi
                
                let socket = SocketIOManager.sharedInstance.rtcSocket
                socket.emit("gyro", [
                    "msg": "from customer",
                    "alpha": alpha,
                    "beta": beta,
                    "gamma": gamma,
                    "absolute": absolute
                ])
            }
        }
    }
        
    func initRemoteHands() {
        let scene = SCNScene()
        self.handView.scene = scene
        self.remoteHands = TSRemoteHands(scene)
    }
}

extension AceHandsViewController: WRTCClientDelegate {
    func wrtc(_ wrtc:WRTCClient, didAdd stream:RTCMediaStream) {
        print("wrtc: \(stream) add stream")
    }

    func wrtc(_ wrtc:WRTCClient, didRemove stream:RTCMediaStream) {
        print("wrtc: \(stream) remove stream")
    }
}

//extension AceHandsViewController: ARSessionDelegate {
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        // If you want to render raw camera frame.
//        // self.capturer.captureFrame(frame.capturedImage)
//
//        let now = Date().timeIntervalSince1970
//
//        if now - self.lastTimeStamp > 0.040 {
//            let image = self.sceneView.snapshot()
//            self.capturer.captureFrame(image)
//            self.lastTimeStamp = now
//
//            // process image for qr code
//            DispatchQueue.global(qos: .background).async {
//                let ciImage = CIImage.init(cgImage: image.cgImage!)
//                let handler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation.up, options: [:])
//
//                do {
//                    try handler.perform([self.detectBarcodeRequest])
//                } catch {
//                    print("Error Decoding Barcode: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//}
