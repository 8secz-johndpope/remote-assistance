//
//  ArrowNode.swift
//  teleskele
//
//  Created by Yulius Tjahjadi on 10/25/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import SceneKit


class ArrowNode : SCNNode {
    
    override init() {
        super.init()
        
        let vertcount = 48;
        let verts: [Float] = [ -1.4923, 1.1824, 2.5000, -6.4923, 0.000, 0.000, -1.4923, -1.1824, 2.5000, 4.6077, -0.5812, 1.6800, 4.6077, -0.5812, -1.6800, 4.6077, 0.5812, -1.6800, 4.6077, 0.5812, 1.6800, -1.4923, -1.1824, -2.5000, -1.4923, 1.1824, -2.5000, -1.4923, 0.4974, -0.9969, -1.4923, 0.4974, 0.9969, -1.4923, -0.4974, 0.9969, -1.4923, -0.4974, -0.9969 ];

        let facecount = 13;
        let faces: [CInt] = [  3, 4, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 0, 1, 2, 3, 4, 5, 6, 7, 1, 8, 8, 1, 0, 2, 1, 7, 9, 8, 0, 10, 10, 0, 2, 11, 11, 2, 7, 12, 12, 7, 8, 9, 9, 5, 4, 12, 10, 6, 5, 9, 11, 3, 6, 10, 12, 4, 3, 11 ];

        let vertsData  = NSData(
            bytes: verts,
            length: MemoryLayout<Float>.size * vertcount
        )

        let vertexSource = SCNGeometrySource(data: vertsData as Data,
                                             semantic: .vertex,
                                             vectorCount: vertcount,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<Float>.size * 3)

        let polyIndexCount = 61;
        let indexPolyData  = NSData( bytes: faces, length: MemoryLayout<CInt>.size * polyIndexCount )

        let element1 = SCNGeometryElement(data: indexPolyData as Data,
                                          primitiveType: .polygon,
                                          primitiveCount: facecount,
                                          bytesPerIndex: MemoryLayout<CInt>.size)

        let geometry1 = SCNGeometry(sources: [vertexSource], elements: [element1])

        let material1 = geometry1.firstMaterial!

        material1.diffuse.contents = UIColor(red: 0.14, green: 0.82, blue: 0.95, alpha: 1.0)
        material1.lightingModel = .lambert
        material1.transparency = 1.00
        material1.transparencyMode = .dualLayer
        material1.fresnelExponent = 1.00
        material1.reflective.contents = UIColor(white:0.00, alpha:1.0)
        material1.specular.contents = UIColor(white:0.00, alpha:1.0)
        material1.shininess = 1.00

        let node = SCNNode()
//        node.scale = SCNVector3(0.01, 0.01, 0.01)
        node.geometry = geometry1
        node.eulerAngles = SCNVector3(0, Float.pi/2, 0)

        self.addChildNode(node)
//        //Assign the SCNGeometry to a SCNNode, for example:
//        let aNode = SCNNode()
//        aNode.geometry = geometry1
//        //aNode.scale = SCNVector3(0.1, 0.1, 0.1)
//        scene.rootNode.addChildNode(aNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
