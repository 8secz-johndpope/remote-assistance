//
//  AceTextNode.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 3/11/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import SceneKit

class AceTextNode : AceVirtualObject {
    private let text:SCNText
    private let textNode:SCNNode
    
    private let plane:SCNPlane
    private let planeNode:SCNNode
    private let fontScale:Float = 0.01
    private let paddingSize:Float = 2

    var string: String? {
        didSet {
            text.string = string
            self.resize()
        }
    }
    
    override init() {
        text = SCNText(string: "...", extrusionDepth: 0.01)
        text.font = UIFont.systemFont(ofSize: 1)
        text.flatness = 0.005
        
        textNode = SCNNode(geometry: text)
        textNode.scale = SCNVector3(fontScale, fontScale, fontScale)
        
        let (min, max) = (text.boundingBox.min, text.boundingBox.max)
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        textNode.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        
        let width = (max.x - min.x) * fontScale
        let height = (max.y - min.y) * fontScale
        plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        planeNode = SCNNode(geometry: plane)
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.6)
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        planeNode.position = textNode.position
        textNode.eulerAngles = planeNode.eulerAngles
        
        super.init()
        planeNode.addChildNode(textNode)
        self.addChildNode(planeNode)
        
        self.constraints = [SCNBillboardConstraint()]
    }
    
    func resize() {
        let (min, max) = (text.boundingBox.min, text.boundingBox.max)
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        
        let width = (max.x - min.x + paddingSize) * fontScale
        let height = (max.y - min.y + paddingSize) * fontScale

        plane.cornerRadius = CGFloat(paddingSize/2 * fontScale)
        plane.width = CGFloat(width)
        plane.height = CGFloat(height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
