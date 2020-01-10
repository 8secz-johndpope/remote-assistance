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
    var wrtc:WRTCClient!
    var motionManager = CMMotionManager()
    var remoteHands:TSRemoteHands!
    var lastTimeStamp:TimeInterval = 0


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)

        initWebRTCClient()
        initMediaStream()
        initGyro()
        initARKit()
        
        SocketIOManager.sharedInstance.connect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        if ARConfiguration.supportsFrameSemantics(ARConfiguration.FrameSemantics.personSegmentation) {
            configuration.frameSemantics.insert(.personSegmentation)
        }
        else {
            print("personSegmentation is not supported")
        }
        configuration.planeDetection = [.horizontal, .vertical]
    
        
        // Run the view's session
        self.arView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
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
    
    func initARKit() {
        self.arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.arView.scene = SCNScene()
        self.arView.autoenablesDefaultLighting = true;
        self.arView.session.delegate = self
    }

}

extension AceARViewController: WRTCClientDelegate {
    func wrtc(_ wrtc:WRTCClient, didAdd stream:RTCMediaStream) {
        print("wrtc: \(stream) add stream")
    }

    func wrtc(_ wrtc:WRTCClient, didRemove stream:RTCMediaStream) {
        print("wrtc: \(stream) remove stream")
    }
}

extension AceARViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // If you want to render raw camera frame.
        // self.capturer.captureFrame(frame.capturedImage)

        let now = Date().timeIntervalSince1970

        if now - self.lastTimeStamp > 0.040 {
            let image = self.arView.snapshot()
            self.capturer.captureFrame(image)
            self.lastTimeStamp = now
        }
    }
}

