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
                
                self.setArrow(point:msg.pos, identifier:msg.identifier)
            }
        }

        socket.on("pointer_clear") { data, ack in
            let identifier:String = "TODO"
            self.removeArrow(identifer:identifier)
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

        let arrowObject = AceVirtualObject.object(byName: "\(pointerName).scn")
        self.arrowObjects[identifier] = arrowObject
        self.arrowObjects[identifier]?.identifier = identifier
        
        // animate
//        let animation = CABasicAnimation(keyPath: "rotation")
//        animation.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
//        animation.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat.pi*2)))
//        animation.duration = 3.0
//        animation.autoreverses = false
//        animation.repeatCount = .infinity
//        self.arrowObjects[identifier]!.addAnimation(animation, forKey: "spinAround")
    }
    
    func setArrow(point:CGPoint, identifier:String) {
        if let arrowObject = self.arrowObjects[identifier] {
            arrowObject.stopTrackedRaycast()
            
            // Prepare to update the object's anchor to the current location.
            arrowObject.shouldUpdateAnchor = true
            
            // Attempt to create a new tracked raycast from the current location.
            if let query = arView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: arrowObject.allowedAlignment),
                let raycast = self.createTrackedRaycastAndSet3DPosition(of: arrowObject, from: query) {
                arrowObject.raycast = raycast
            } else {
                // If the tracked raycast did not succeed, simply update the anchor to the object's current position.
                arrowObject.shouldUpdateAnchor = false
                self.updateQueue.async {
                    self.addOrUpdateAnchor(for: arrowObject)
                }
            }
        }
    }
    
    func removeArrow(identifer:String) {
        if let object = self.arrowObjects[identifer] {
            removeAnchor(object)
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
    private func setVirtualObject3DPosition(_ results: [ARRaycastResult], with arrowObject: AceVirtualObject) {
        
        guard let result = results.first else {
            print("ERROR: Unexpected case: the update handler is always supposed to return at least one result.")
            return
        }
        
        self.setTransform(of: arrowObject, with: result)
        
        // If the virtual object is not yet in the scene, add it.
        if arrowObject.parent == nil {
            self.arView.scene.rootNode.addChildNode(arrowObject)
            arrowObject.shouldUpdateAnchor = true
            if let textObject = self.textObjects[arrowObject.identifier] {
                self.arView.scene.rootNode.addChildNode(textObject)
            }
        }
        
        if arrowObject.shouldUpdateAnchor {
            arrowObject.shouldUpdateAnchor = false
            self.updateQueue.async {
                self.addOrUpdateAnchor(for: arrowObject)
            }
        }
    }
    
    func setTransform(of arrowObject: AceVirtualObject, with result: ARRaycastResult) {
        arrowObject.simdWorldTransform = result.worldTransform
    }
    
    func addOrUpdateAnchor(for arrowObject: AceVirtualObject) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = arrowObject.anchor {
            arView.session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: arrowObject.simdWorldTransform)
        arrowObject.anchor = newAnchor
        arView.session.add(anchor: newAnchor)

        if let textObject = self.textObjects[arrowObject.identifier] {
            arrowObject.addChildNode(textObject)
        }
        
        print("updated anchor")
    }

    func removeAnchor(_ object: AceVirtualObject) {
        if let anchor = object.anchor {
            arView.session.remove(anchor: anchor)
            object.removeFromParentNode()
        }
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
