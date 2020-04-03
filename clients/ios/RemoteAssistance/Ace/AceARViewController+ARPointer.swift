//
//  AceARViewController+ARPointer.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/23/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import ARKit
import Toast_Swift

extension AceARViewController {
    
    class PointerSet {
        var pos = CGPoint(x:0, y:0)
        var size = CGSize(width: 0, height: 0)
        var pointer = ""
        var message = ""
        var identifier = ""
        
        func parse(_ data:[String:AnyObject]) -> PointerSet {
            if let x = data["x"] {
                pos.x = x as! CGFloat
            }
            if let y = data["y"] {
                pos.y = y as! CGFloat
            }
            if let cW = data["w"] {
                size.width = cW as! CGFloat
            }
            if let cH = data["h"] {
                size.height = cH as! CGFloat
            }
            if let pntr = data["pointer"] {
                pointer = pntr as! String
            }
            if let msg = data["message"] {
                message = msg as! String
            }
            if let ident = data["identifier"] {
                identifier = ident as! String
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
        
        // listen for pointer messages
        let socket = SocketIOManager.sharedInstance
        socket.on("pointer_set") { data, ack in
            for line in data {
                let msg = PointerSet()
                    .parse(line as! [String:AnyObject])
                    .transformToFrame(self.view.frame.size)
                
                self.showToast(message: "\(msg.identifier) - \(msg.pointer) - \(msg.message)")

                self.initArrowAndTextObjects(pointerName: msg.pointer, identifier: msg.identifier, message: msg.message)
                
                self.setPointerObject(point:msg.pos, identifier:msg.identifier)
            }
        }

        socket.on("pointer_clear") { data, ack in
            for line in data {
                let msg = PointerSet().parse(line as! [String:AnyObject])
                let identifier:String = msg.identifier
                self.removePointerObject(identifer:identifier)
                if self.pointerObjects.has(key: identifier) {
                    self.pointerObjects.removeValue(forKey: identifier)
                }
                if self.textObjects.has(key: identifier) {
                    self.textObjects.removeValue(forKey: identifier)
                }
            }
        }
    }

    func arPointerVieWillDisappear() {
        let socket = SocketIOManager.sharedInstance
        socket.off("pointer_set")
        socket.off("pointer_clear")
    }
    
    func initArrowAndTextObjects(pointerName:String, identifier:String, message:String) {
        
        let textObject = AceVirtualText.object(withMessage: message)
        self.textObjects[identifier] = textObject
        self.textObjects[identifier]?.identifier = identifier
        var pointerObject = AceVirtualObject.object(byName: "\(pointerName).scn")

        if self.pointerObjects.count > 0 && !self.pointerObjects.has(key: identifier) {
            pointerObject = pointerObject?.clone()
            print("new object")
        }
        else {
            print("update object")
        }

        self.pointerObjects[identifier] = pointerObject
        self.pointerObjects[identifier]?.identifier = identifier

        // animate
//        let animation = CABasicAnimation(keyPath: "rotation")
//        animation.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
//        animation.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat.pi*2)))
//        animation.duration = 3.0
//        animation.autoreverses = false
//        animation.repeatCount = .infinity
//        self.pointerObjects[identifier]!.addAnimation(animation, forKey: "spinAround")
    }
    
    func setPointerObject(point:CGPoint, identifier:String) {
        if let pointerObject = self.pointerObjects[identifier] {
            pointerObject.stopTrackedRaycast()
            
            // Prepare to update the object's anchor to the current location.
            pointerObject.shouldUpdateAnchor = true
            
            // Attempt to create a new tracked raycast from the current location.
            if let query = arView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: pointerObject.allowedAlignment),
                let raycast = self.createTrackedRaycastAndSet3DPosition(of: pointerObject, from: query) {
                pointerObject.raycast = raycast
            } else {
                // If the tracked raycast did not succeed, simply update the anchor to the object's current position.
                pointerObject.shouldUpdateAnchor = false
                self.updateQueue.async {
                    self.addOrUpdateAnchor(for: pointerObject)
                }
            }
        }
    }
    
    func removePointerObject(identifer:String) {
        if let pointerObject = self.pointerObjects[identifer] {
            pointerObject.stopTrackedRaycast()
            if let anchor = pointerObject.anchor {
                arView.session.remove(anchor: anchor)
            }
            pointerObject.childNodes.filter({ $0.name == "Message" }).forEach({ $0.removeFromParentNode() })
            pointerObject.removeFromParentNode()
        }
    }
    
    func createTrackedRaycastAndSet3DPosition(of pointerObject: AceVirtualObject, from query: ARRaycastQuery,
                                              withInitialResult initialResult: ARRaycastResult? = nil) -> ARTrackedRaycast? {
        if let initialResult = initialResult {
            self.setTransform(of: pointerObject, with: initialResult)
        }
        
        return arView.session.trackedRaycast(query) { (results) in
            self.setVirtualObject3DPosition(results, with: pointerObject)
        }
    }
    
    // - Tag: ProcessRaycastResults
    private func setVirtualObject3DPosition(_ results: [ARRaycastResult], with pointerObject: AceVirtualObject) {
        
        print("setVirtualObject3DPosition")
        
        guard let result = results.first else {
            print("ERROR: Unexpected case: the update handler is always supposed to return at least one result.")
            return
        }
        
        self.setTransform(of: pointerObject, with: result)
        
        // If the virtual object is not yet in the scene, add it.
        if pointerObject.parent == nil {
            self.arView.scene.rootNode.addChildNode(pointerObject)
            pointerObject.shouldUpdateAnchor = true
            if let textObject = self.textObjects[pointerObject.identifier] {
                self.arView.scene.rootNode.addChildNode(textObject)
            }
        }
        
        if pointerObject.shouldUpdateAnchor {
            pointerObject.shouldUpdateAnchor = false
            self.updateQueue.async {
                self.addOrUpdateAnchor(for: pointerObject)
            }
        }
    }
    
    func setTransform(of pointerObject: AceVirtualObject, with result: ARRaycastResult) {
        pointerObject.simdWorldTransform = result.worldTransform
    }
    
    func addOrUpdateAnchor(for pointerObject: AceVirtualObject) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = pointerObject.anchor {
            arView.session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: pointerObject.simdWorldTransform)
        pointerObject.anchor = newAnchor
        arView.session.add(anchor: newAnchor)

        if let textObject = self.textObjects[pointerObject.identifier] {
            
            pointerObject.childNodes.filter({ $0.name == "Message" }).forEach({ $0.removeFromParentNode() })
            
            pointerObject.addChildNode(textObject)
            print("reset textObject")
        }
        
        print("set anchor")
    }
    
    // func resetPointer() {
    //     self.arView.session.pause()
    //     removeArrow()
    //     self.arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    // }
    
    func enablePointer() {
        self.arView.session.pause()
        self.configuration.detectionObjects = []
        self.configuration.detectionImages = []
        self.arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking, .stopTrackedRaycasts])
    }
}
