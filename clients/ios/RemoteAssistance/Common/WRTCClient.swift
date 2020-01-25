//
//  WRTCClient.swift
//  teleskele
//
//  Created by Yulius Tjahjadi on 10/8/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import WebRTC
import ReSwift

class WRTCClient : NSObject {
    
    private var pcs:[String:RTCPeerConnection] = [String:RTCPeerConnection]()
    private var iceCandidates:[String:[RTCIceCandidate]] = [String:[RTCIceCandidate]]()
    private var sid:String = ""
    public var factory:RTCPeerConnectionFactory
    public var stream:RTCMediaStream?
    public var delegate:WRTCClientDelegate?
    private var remoteDataChannel: RTCDataChannel?
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private var useSpeaker = true

    static private var offerAnswerContraints = RTCMediaConstraints(mandatoryConstraints: [String:String](), optionalConstraints: nil)
    static private var mediaContraints = RTCMediaConstraints(mandatoryConstraints: [
        "OfferToReceiveAudio": "true",
        "OfferToReceiveVideo": "true",
    ], optionalConstraints: nil)

    override init() {
        // create webrtc factory
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let codecs = encoderFactory.supportedCodecs()
        for codec in codecs {
            if codec.name == "VP8" {
                encoderFactory.preferredCodec = codec
                break
            }
        }
        
        self.factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        super.init()


        // configure audio
        rtcAudioSession.lockForConfiguration()
        do {
            rtcAudioSession.useManualAudio = false
            rtcAudioSession.isAudioEnabled = true
            try rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue, with: [.mixWithOthers, .allowBluetooth])
            try rtcAudioSession.setMode(AVAudioSession.Mode.videoChat.rawValue)
            try rtcAudioSession.overrideOutputAudioPort(.none)
            try rtcAudioSession.setActive(true)
        } catch let error {
            debugPrint("Error changeing AVAudioSession category: \(error)")
        }
        rtcAudioSession.unlockForConfiguration()
        
        
        initSocket()
        store.ace.subscribe(self)                
    }
    
    func connect() {
        initSocket()
        SocketIOManager.sharedInstance.connect()
    }
    
    func disconnect() {
        store.ace.unsubscribe(self)
        self.delegate = nil
        self.stream = nil
        
        for (_, pc) in pcs {
            pc.close()
        }
        self.pcs = [String:RTCPeerConnection]()
        self.iceCandidates = [String:[RTCIceCandidate]]()
    }

    func initSocket() {
        let socket = SocketIOManager.sharedInstance
        
        socket.on("left") { [weak self] data, ack in
            if let object = data[0] as? [String:Any],
                let sid = object["sid"] as? String,
                let pc = self?.pcs[sid]
            {
                pc.close()
                self?.pcs.removeValue(forKey: sid);
            }
        }
        
        socket.on("sid") { [weak self] data, ack in
            if let object = data[0] as? [String:Any],
                let sid = object["sid"] as? String
            {
                self?.sid = sid
            }
        }
        
        socket.on("users") { [weak self] data, ack in
            if let users = data[0] as? [String]
            {
                for id in users {
                    if id != self?.sid,
                        let pc = self?.getPC(id)
                    {
                        pc.offer(for: WRTCClient.offerAnswerContraints) { sdp, error in
                            
                            if let errorString = error?.localizedDescription {
                                print(errorString)
                            }

                            if let localSDP = sdp {
                                pc.setLocalDescription(localSDP) { error in
                                    
                                    if let errorString = error?.localizedDescription {
                                        print(errorString)
                                    }

                                    socket.emit("webrtc", id, [
                                        "type": "offer",
                                        "payload": [
                                            "sdp": localSDP.sdp,
                                            "type": "offer"
                                        ]
                                    ])
                                }
                            }
                        }
                    }
                }
            }
        }
        
        socket.on("webrtc") { [weak self] data, ack in
            if let object = data[0] as? [String:Any],
                let from = object["from"] as? String,
                let type = object["type"] as? String,
                let pc = self?.getPC(from)
            {
                switch (type) {
                case "offer":
                    if let payload = object["payload"] as? [String:String],
                        let sdpString = payload["sdp"] {
                        let sdp = RTCSessionDescription(type: .offer, sdp: sdpString)
                        pc.setRemoteDescription(sdp) { error in
                            if let errorString = error?.localizedDescription {
                                print(errorString)
                            }
                            
                            // clear local candidate
                            self?.addCandidates(from)

                            pc.answer(for: WRTCClient.offerAnswerContraints) { sdp, error in
                                
                                if let errorString = error?.localizedDescription {
                                    print(errorString)
                                }

                                if let answerSDP = sdp {
                                    pc.setLocalDescription(answerSDP) { error in
                                        
                                        if let errorString = error?.localizedDescription {
                                            print(errorString)
                                        }
                                        
                                        socket.emit("webrtc", from, [
                                            "type": "answer",
                                            "payload": [
                                                "sdp": answerSDP.sdp,
                                                "type": "answer"
                                            ]
                                        ])
                                    }
                                }
                            }
                        }
                    }
                    break
                case "answer":
                    if let payload = object["payload"] as? [String:String],
                        let sdpString = payload["sdp"] {
                        let sdp = RTCSessionDescription(type: .answer, sdp: sdpString)
                        pc.setRemoteDescription(sdp) { error in
                            
                            self?.addCandidates(from)
                            
                            if let errorString = error?.localizedDescription {
                                print(errorString)
                            }
                        }
                    }
                    break
                case "icecandidate":
                    if let payload = object["payload"] as? [String:String],
                        let sdpString = payload["candidate"],
                        let mline = Int32(payload["sdpMLineIndex"]!),
                        let mid = payload["sdpMid"]
                    {
                        let candidate = RTCIceCandidate(sdp: sdpString, sdpMLineIndex: mline, sdpMid: mid)
                        print("recv icecandidate: \(from) \(candidate)")
                        if pc.remoteDescription != nil {
                            // we have both local & remote description
                            pc.add(candidate)
                        } else {
                            // we need to cache the ice candidates
                            self?.iceCandidates[from]? += [candidate]
                        }
                    }
                    break
                default:
                    break
                }
            }
        }
    }
    
    private func getPC(_ id:String) -> RTCPeerConnection? {
        if let pc = self.pcs[id] {
            return pc
        } else {
            let config = RTCConfiguration()
            config.iceServers = [
                RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
                RTCIceServer(urlStrings: ["stun:rhelp.fxpal.net"]),
                ]
            config.sdpSemantics = .unifiedPlan
            config.certificate = RTCCertificate.generate(withParams: ["expires": 100000, "name": "RSASSA-PKCS1-v1_5"])
            
            let newPC = self.factory.peerConnection(with: config, constraints: WRTCClient.mediaContraints, delegate: self)
           
            if let stream = self.stream {
                let streamId = stream.streamId
                for audioTrack in stream.audioTracks {
                    newPC.add(audioTrack, streamIds: [streamId])
                }
                for videoTrack in stream.videoTracks {
                    newPC.add(videoTrack, streamIds: [streamId])
                }
                
                self.pcs[id] = newPC
                self.iceCandidates[id] = [RTCIceCandidate]()

                return newPC
            } else {
                return nil
            }
        }
    }
    
    private func addCandidates(_ from:String) {
        // print("addCandidates from \(from)")
        if let candidates = self.iceCandidates[from],
            let pc = self.getPC(from)
        {
            for candidate in candidates {
                pc.add(candidate)
            }
            self.iceCandidates[from] = [RTCIceCandidate]()
        }
    }

    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        self.remoteDataChannel?.sendData(buffer)
    }
    
    func enableSpeaker(_ enable:Bool) {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.useSpeaker = enable
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.overrideOutputAudioPort(enable ? .speaker : .none)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    func setAudioEnabled(_ enable:Bool) {
        if let audioTracks = stream?.audioTracks {
            audioTracks.forEach { $0.isEnabled = enable }
        }
    }
}

extension WRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("dataChannel did change state: \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.wrtc(self, didReceiveData: buffer.data)
    }
}

extension WRTCClient : RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        let track = transceiver.receiver.track
        print("peerConnection: \(peerConnection) transceiver: \(String(describing: track?.kind)) \(String(describing: track?.trackId))")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("peerConnection: \(peerConnection) signale state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("peerConnection: \(peerConnection) add stream")
//        stream.videoTracks[0].add(self.remoteView)
        self.delegate?.wrtc(self, didAdd:stream)

        // set speaker because we have to wait until a stream
        // is added before the audio subsystem is initialized
        self.enableSpeaker(self.useSpeaker)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("peerConnection: \(peerConnection) remove stream")
        self.delegate?.wrtc(self, didRemove:stream)
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnection: \(peerConnection) should renegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("peerConnection: \(peerConnection) ice state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("peerConnection: \(peerConnection) gathering state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        DispatchQueue.main.async(execute: { () -> Void in
            let socket =  SocketIOManager.sharedInstance

            // find the correct session id
            var sid = ""
            for (id, pc) in self.pcs {
                if peerConnection == pc {
                    sid = id
                    break
                }
            }
            
            socket.emit("webrtc", sid, [
                "type": "icecandidate",
                "payload": [
                    "candidate": candidate.sdp,
                    "sdpMLineIndex": String(candidate.sdpMLineIndex),
                    "sdpMid": candidate.sdpMid
                ]
            ])
        })
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("data channel didOpen",dataChannel)
        self.remoteDataChannel = dataChannel
        self.remoteDataChannel?.delegate = self
    }
}

extension WRTCClient : StoreSubscriber {
    
    func newState(state: AceState) {
        if store.ace.state.serverUrl != SocketIOManager.sharedInstance.url.absoluteString {
            self.initSocket()
        }
    }
}



protocol WRTCClientDelegate {
    func wrtc(_ wrtc:WRTCClient, didAdd stream:RTCMediaStream)
    func wrtc(_ wrtc:WRTCClient, didRemove stream:RTCMediaStream)
    func wrtc(_ wrtc:WRTCClient, didReceiveData data: Data)
}

class WRTCCustomCapturer : RTCVideoCapturer {

    var pixelBuffer:CVPixelBuffer?
    var pixelBufferSize:CGSize = CGSize(width: 0, height: 0)

    func captureFrame(_ frame:CVPixelBuffer) {
        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: frame)
        let timeStampNs = Int64(CACurrentMediaTime() * Double(NSEC_PER_SEC))
        let videoFrame = RTCVideoFrame(buffer: rtcPixelBuffer, rotation: ._0, timeStampNs: timeStampNs)
        self.delegate?.capturer(self, didCapture: videoFrame)
    }
    
    func captureFrame(_ frame:UIImage) {
        guard let cgImage = frame.cgImage else {
            return
        }

        if pixelBufferSize.width != CGFloat(cgImage.width) || pixelBufferSize.height != CGFloat(cgImage.height) {
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            var pixelBuffer : CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(cgImage.width), Int(cgImage.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
            guard (status == kCVReturnSuccess) else {
                return
            }
            self.pixelBufferSize = CGSize(width: cgImage.width, height: cgImage.height)
            self.pixelBuffer = pixelBuffer
        }

        if let pixelBuffer = self.pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(cgImage.width), height: Int(cgImage.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

            context?.translateBy(x: 0, y: CGFloat(cgImage.height))
            context?.scaleBy(x: 1.0, y: -1.0)

            UIGraphicsPushContext(context!)
            frame.draw(in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

            self.captureFrame(pixelBuffer)
        }

    }
}

