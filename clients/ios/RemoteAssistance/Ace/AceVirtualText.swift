//
//  AceVirtualText.swift
//  RemoteAssistance
//
//  Created by Gerry Filby on 3/26/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class AceVirtualText:SCNNode {
    
    var identifier:String = ""
}

extension AceVirtualText {
    static func object(withMessage message:String) -> AceVirtualText? {
        
        let text:SCNText = SCNText(string: message, extrusionDepth: 2)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.magenta
        text.materials = [material]
        let obj = AceVirtualText()
        obj.scale = SCNVector3(x:0.002, y:0.002, z:0.002)
        obj.position = SCNVector3(x:-(0.005 * Float(message.count)), y:0.08, z:0.0)
        obj.geometry = text
        obj.name = "Message"
        return obj
    }

}
