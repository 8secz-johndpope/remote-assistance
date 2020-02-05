//
//  AceARViewController+ARPointer.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/23/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import ARKit

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
            print("ERROR: Unexpected case: the update handler is always supposed to return at least one result.")
            return
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
    
    func resetPointer() {
        removeArrow()
        self.arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    func enablePointer() {
        self.arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
}
