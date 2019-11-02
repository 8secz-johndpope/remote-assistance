//
//  TSRemoteHands.swift
//  teleskele
//
//  Created by Yulius Tjahjadi on 10/8/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import Foundation
import ARKit
import SwifterSwift
import ReSwift

class TSRemoteHands {
    
    struct HandInfo {
        var model:SCNNode = SCNNode()
        var wrist:SCNNode = SCNNode()
        var fingers:[String:SCNNode] = [String:SCNNode]()
        var fingerOrientation:[String:SCNQuaternion] = [String:SCNQuaternion]()
        var middleProximalMeshLength:Float = 1
    }
    
    private var scene:SCNScene
    private var decoder:JSONDecoder = JSONDecoder()
    private var camera:SCNNode = SCNNode()
    private var leftHandInfo:HandInfo = HandInfo()
    private var rightHandInfo:HandInfo = HandInfo()
    public var root = SCNNode()
    
    init(_ scene:SCNScene) {
        self.scene = scene
        
        let fingerNames = [
            "Finger_00", "Finger_01", "Finger_02", "Finger_03",
            "Finger_10", "Finger_11", "Finger_12", "Finger_13",
            "Finger_20", "Finger_21", "Finger_22", "Finger_23",
            "Finger_30", "Finger_31", "Finger_32", "Finger_33",
            "Finger_40", "Finger_41", "Finger_42", "Finger_43",
        ]
        
        self.scene.rootNode.addChildNode(self.root)
        
        for i in 0...1 {
            let handName:String  = i == 0 ? "Right" : "Left"
            
            let url = Bundle.main.url(forResource: "Leapmotion_Handsolo_Rig_\(handName)", withExtension: "dae")!
            let source = SCNSceneSource(url: url, options: nil)
            let hand = source!.entryWithIdentifier("Leapmotion_Basehand_Rig_\(handName)", withClass: SCNNode.self)!
            hand.opacity = 0.5
            self.root.addChildNode(hand)
            
            let wrist = source!.entryWithIdentifier("Wrist", withClass: SCNNode.self)!
            
            var fingers = [String:SCNNode]()
            var fingerOrientation = [String:SCNQuaternion]()
            for name in fingerNames {
                if let node = source!.entryWithIdentifier(name, withClass: SCNNode.self) {
                    fingers[name] = node
                    fingerOrientation[name] = node.orientation
                }
            }
            
            var middleProximalMeshLength:Float = 1
            if let node = fingers["Finger_20"] {
                middleProximalMeshLength = node.position.length
            }
            
            let info = HandInfo(model: hand, wrist: wrist, fingers: fingers, fingerOrientation: fingerOrientation, middleProximalMeshLength: middleProximalMeshLength)
            if i == 0 {
                self.rightHandInfo = info
            } else {
                self.leftHandInfo = info
            }
        }

        self.initSocket()
        self.initScene(scene)
        
        store.ts.subscribe(self)
    }
    
    func initSocket() {

        // setup socket
        let socket = SocketIOManager.sharedInstance.lmSocket
        socket.on("frame") { data, ack in
            if let frameJson = data[0] as? String,
                let data = frameJson.data(using: .utf8)
            {
                do {
                    let frame = try self.decoder.decode(LMFrame.self, from:data)
                    self.updateFrame(frame)
                } catch {
                    print(error)
                }
            }
        }

        // get udpate to the camera
        let rtcSocket = SocketIOManager.sharedInstance.rtcSocket
        rtcSocket.on("camera_update") { data, ack in
            
            if
                let msg = data[0] as? [String:Any],
                let position = msg["position"] as? [String:Double],
                let quaternion = msg["quaternion"] as? [String:Double]
            {
                self.camera.position.x = Float(position["x"]!)
                self.camera.position.y = Float(position["y"]!)
                self.camera.position.z = Float(position["z"]!)
                
                self.camera.orientation.x = Float(quaternion["_x"]!)
                self.camera.orientation.y = Float(quaternion["_y"]!)
                self.camera.orientation.z = Float(quaternion["_z"]!)
                self.camera.orientation.w = Float(quaternion["_w"]!)
            }
        }
    }
    
    func initScene(_ scene:SCNScene) {
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        camera.automaticallyAdjustsZRange = true
        camera.fieldOfView = 45.0
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 200, 700)
        cameraNode.look(at:SCNVector3(0, 200, 0))
        self.camera = cameraNode

        let light1 = SCNLight()
        light1.type = SCNLight.LightType.directional
        light1.color = UIColor.white.cgColor
        light1.intensity = 1000
        let lightNode1 = SCNNode()
        lightNode1.light = light1
        lightNode1.position = SCNVector3(0, 700, 100)
        scene.rootNode.addChildNode(lightNode1)
        
        let light2 = SCNLight()
        light2.type = SCNLight.LightType.directional
        light2.color = UIColor.white.cgColor
        light2.intensity = 1000
        let lightNode2 = SCNNode()
        lightNode2.light = light2
        lightNode2.position = SCNVector3(0, -500, 100)
        scene.rootNode.addChildNode(lightNode2)

        scene.rootNode.addChildNode(cameraNode)
    }
    
    func updateFingerBone(_ bone:SCNNode, _ worldDirection:SCNVector3, _ parentWorldDirection:SCNVector3, _ parentWorldUp:SCNVector3, _ parentOrientation:SCNQuaternion, _ originalOrientation:SCNQuaternion) -> (SCNVector3, SCNQuaternion) {
        let directionDotParentDirection = worldDirection.dot(parentWorldDirection)
        let angle = acos(directionDotParentDirection)
        let worldAxis = parentWorldDirection.cross(worldDirection).normalized
        
        // http://en.wikipedia.org/wiki/Rodrigues'_rotation_formula
        // v = palmNormal = parentUp
        // k = rotation axis = worldAxis
        var worldUp = SCNVector3(x:0, y:0, z:0)
        worldUp += (parentWorldUp * directionDotParentDirection)
        worldUp += worldAxis.cross(parentWorldUp) * sin(angle)
        worldUp += worldAxis * (worldAxis.dot(parentWorldUp) * (1 - directionDotParentDirection))
        worldUp = worldUp.normalized
        
        var matrix = SCNMatrix4()
        matrix.lookAt(eye:worldDirection, target:SCNVector3(), up: worldUp)
        
        var quat = SCNQuaternion()
        quat.setFromRotationMatrix(matrix)
        
        bone.orientation = parentOrientation.inverse().multiply(quat).multiply(originalOrientation)
        
        return (worldUp, quat)
    }
    
    func updateHandScale(_ model:SCNNode, _ middleProximalMeshLength:Float, _ pipPosition:[Float], _ mcpPosition:[Float]) {
        let middleProximalLeapLength = (SCNVector3(pipPosition) - SCNVector3(mcpPosition)).length
        let scale = ( middleProximalLeapLength / middleProximalMeshLength )
        model.scale = SCNVector3(scale, scale, scale)
    }
    
    func updateFrame(_ frame:LMFrame) {
        self.leftHandInfo.model.isHidden = true
        self.rightHandInfo.model.isHidden = true
        for hand in frame.hands {
            var model:SCNNode
            var wrist:SCNNode
            var fingers:[String:SCNNode]
            var fingerOrientation:[String:SCNQuaternion]
            var middleProximalMeshLength:Float
            switch hand.type {
            case .left:
                model = self.leftHandInfo.model
                wrist = self.leftHandInfo.wrist
                fingers = self.leftHandInfo.fingers
                fingerOrientation = self.leftHandInfo.fingerOrientation
                middleProximalMeshLength = self.leftHandInfo.middleProximalMeshLength
            case .right:
                model = self.rightHandInfo.model
                wrist = self.rightHandInfo.wrist
                fingers = self.rightHandInfo.fingers
                fingerOrientation = self.rightHandInfo.fingerOrientation
                middleProximalMeshLength = self.rightHandInfo.middleProximalMeshLength
            }
            
            model.isHidden = false
            
            // set model position
            model.position = SCNVector3(hand.palmPosition)
            
            // set model rotation
            let handWorldDirection = SCNVector3(hand.direction)
            let handWorldUp = SCNVector3(hand.palmNormal) * -1
            
            model.transform.lookAt(eye:handWorldDirection, target:SCNVector3(0, 0, 0), up:handWorldUp)

            // calculate the scale
            for finger in frame.pointables {
                if (finger.type == 2 && finger.handId == hand.id) {
                    updateHandScale(wrist, middleProximalMeshLength, finger.pipPosition, finger.mcpPosition)
                    break
                }
            }
            
            // set finger
            for finger in frame.pointables {
                if finger.handId != hand.id {
                    continue
                }
                
                let nodeNames = [
                    "Finger_\(finger.type)0",
                    "Finger_\(finger.type)1",
                    "Finger_\(finger.type)2",
                    "Finger_\(finger.type)3",
                ]
                
                let positions = [
                    SCNVector3(finger.mcpPosition),
                    SCNVector3(finger.pipPosition),
                    SCNVector3(finger.dipPosition),
                    SCNVector3(finger.tipPosition),
                ]
                
                var parentWorldUp = handWorldUp
                var parentOrientation = SCNQuaternion()
                parentOrientation.setFromRotationMatrix(model.transform)
                for i in 0..<finger.bases.count-1 {
                    if let node = fingers[nodeNames[i]],
                       let originalOrientation = fingerOrientation[nodeNames[i]]
                    {
                        let worldDirection = (positions[i+1] - positions[i]).normalized
                        let parentWorldDirection:SCNVector3
                        if i == 0 {
                            parentWorldDirection = handWorldDirection
                        } else {
                            parentWorldDirection = (positions[i] - positions[i - 1]).normalized
                        }
                        
                        (parentWorldUp, parentOrientation)  = self.updateFingerBone(node, worldDirection, parentWorldDirection, parentWorldUp, parentOrientation, originalOrientation)
                    }
                }
            }
        }
    }
}

extension TSRemoteHands : StoreSubscriber {
    
    func newState(state: TSState) {
        if store.ts.state.serverUrl != SocketIOManager.sharedInstance.url.absoluteString {
            self.initSocket()
        }
    }
}


