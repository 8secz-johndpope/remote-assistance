
import UIKit
import SceneKit
import ARKit
import Vision

private let meters2inches = CGFloat(39.3701)

class RectangleNode: SCNNode {
    
    private let markTextureRed = UIImage(named: "hollow-mark-red.png")
    private let markTexture = UIImage(named: "hollow-mark.png")
    private let borderTexture = UIImage(named: "hollow-border.png")
    private(set) var textureImage: UIImage?
    //private var timer:Timer?
    //private var view:UIView
    private var material:SCNMaterial = SCNMaterial()
    //let renderingOrderFirst = -1

    convenience init(_ planeRectangle: PlaneRectangle, /*view: UIView,*/ color: UIColor?) {
        self.init(center: planeRectangle.position,
        width: planeRectangle.size.width,
        height: planeRectangle.size.height,
        orientation: planeRectangle.orientation, vertical: planeRectangle.verticalPlaneAnchor)
    }
    
    init(imageAnchor: ARImageAnchor, rootNode: SCNNode)
    {
        //self.view = view
        super.init()

        let width = imageAnchor.referenceImage.physicalSize.width
        let height = imageAnchor.referenceImage.physicalSize.height

        let planeGeometry = SCNPlane(width: width, height: height)
        planeGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        self.geometry = planeGeometry

        // Rotate The PlaneNode To Horizontal
        //planeNode.eulerAngles.x = -.pi/2
        self.eulerAngles.x = -.pi/2

        rootNode.addChildNode(self)
        createCornerAnchors(imageAnchor: imageAnchor, rootNode: rootNode)
        
        self.showMark(px: 0, py: 0, pw: 1024, ph: 1024, name: "title")
    }
    
    func clearMarks()
    {
        print("clearing all marks")
        self.childNodes.forEach { (mark) in
            if mark.name != "title" {
                mark.removeFromParentNode()
            }
        }
    }
    // px,py,pw,ph are in 1024 of the width/height
    func showMark(px: Int, py: Int, pw: Int, ph: Int, name: String)
    {
        self.clearMarks()
        /*let min = self.boundingBox.min
        let max = self.boundingBox.max
        let nodew = CGFloat(max.x - min.x)
        let nodeh = CGFloat(max.y - min.y)*/
        if let plane: SCNPlane = self.geometry as? SCNPlane {
            let nodew = plane.width
            let nodeh = plane.height
            let w = CGFloat(pw) * nodew / 1024;
            let h = CGFloat(ph) * nodeh / 1024;
            let cx = CGFloat(px+pw/2) * nodew / 1024 - nodew / 2; // because nodes are positioned relative to the center
            let cy = CGFloat(1024-py-ph/2) * nodeh / 1024 - nodeh / 2; // because nodes are positioned relative to the center
            //let boxNode = self.createBox(width: CGFloat(w), height: CGFloat(h), color: UIColor.yellow)
            
            let planeNode = SCNPlane(width: w, height: h)
            let planeMaterial = SCNMaterial()
            //green.diffuse.contents = UIColor.green
            //planeNode.materials = [green]
            
            //let img = UIImage(named: "hollow-mark.png")
            if name == "title"
            {
                planeMaterial.diffuse.contents = borderTexture
            }
            else
            {
                planeMaterial.diffuse.contents = markTextureRed
            }
            planeMaterial.colorBufferWriteMask = .all // needs to be alpha to show original image above instead of black on white mask, other value=.all
            planeNode.materials = [planeMaterial]
            let boxNode = SCNNode(geometry: planeNode)
            boxNode.position = SCNVector3Make(Float(cx), Float(cy), 0)
            boxNode.name = name
            boxNode.opacity = 1
            self.addChildNode(boxNode)
            
            /*let fadeIn = SCNAction.customAction(duration: 1) { (node, elapsedTime) -> () in
                boxNode.opacity = elapsedTime / 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now()) {
                boxNode.runAction(fadeIn)
            }*/
            
            if name != "title"
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    boxNode.geometry?.firstMaterial?.diffuse.contents = self.markTexture
                }
            }

        }
    }
    func updateARImageAnchor(_ anchor: ARImageAnchor) {
        print("update corners?")
    }
    func createCornerAnchors(imageAnchor: ARImageAnchor, rootNode: SCNNode)
    {

        // add the 4 corners so we can track where they are to perspective correct the image sent to the remote side
        let corners = CornerTrackingNode(anchor: imageAnchor)
        rootNode.addChildNode(corners)
        defer {
            corners.removeFromParentNode()
        }

        addCornerBox(position: corners.topLeft.position, node: rootNode, name:"tl", color: UIColor.blue)
        addCornerBox(position: corners.topRight.position, node: rootNode, name:"tr", color: UIColor.blue)
        addCornerBox(position: corners.bottomLeft.position, node: rootNode, name:"bl", color: UIColor.green)
        addCornerBox(position: corners.bottomRight.position, node: rootNode, name:"br", color: UIColor.green)
    }

    private func createBox(width: CGFloat, height: CGFloat, color: UIColor) -> SCNNode {
        //let box = SCNBox(width: width, height: height, length: 0.00, chamferRadius: 0.02)
        let box = SCNBox(width: width, height: height, length: 0.0, chamferRadius: 0)
        //let box = SCNCylinder(radius: 0.003, height: 0.0)
        let green = SCNMaterial()
        green.diffuse.contents = color
        box.materials = [green]
        
        let boxNode = SCNNode(geometry: box)
        //boxNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
        return boxNode
    }

    func addCornerBox(position: SCNVector3, node: SCNNode, name: String, color: UIColor)
    {
        let box = createBox(width: 0.0, height: 0.0, color: color)
        box.position = position
        node.addChildNode(box)
        //sceneView.scene.rootNode.addChildNode(box)
        box.name = name
    }

    init(center position: SCNVector3, width: CGFloat, height: CGFloat, orientation: Float, vertical: Bool)
    {
        //self.view = view
        super.init()
        
        let planeGeometry = SCNPlane(width: width, height: height)
        planeGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        self.geometry = planeGeometry

        var transform: SCNMatrix4
        if (vertical) {
            print("vorientation=vertical")
            transform = SCNMatrix4MakeRotation(-Float.pi, 0.0, 1.0, 0.0)
            transform = SCNMatrix4Rotate(transform, orientation, 0, 0, 1)
        }
        else {
            print("vorientation=horizontal")
            transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
            transform = SCNMatrix4Rotate(transform, orientation, 0, 0, 1)
        }
    
        self.transform = transform
        self.geometry = planeGeometry
        // Set position to the center of rectangle
        //print("position=",position)
        self.position = position
        //self.position.y += 0.001
        self.showMark(px: 0, py: 0, pw: 1024, ph: 1024, name: "title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/*extension UIImage {
    convenience init(_ view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
}*/

private class CornerTrackingNode: SCNNode {

    let topLeft = SCNNode()
    let topRight = SCNNode()
    let bottomLeft = SCNNode()
    let bottomRight = SCNNode()

    init(anchor: ARImageAnchor) {
        super.init()

        let physicalSize = anchor.referenceImage.physicalSize
        let halfWidth = Float(physicalSize.width / 2)
        let halfHeight = Float(physicalSize.height / 2)

        addChildNode(topLeft)
        topLeft.position = position
        topLeft.localTranslate(by: SCNVector3(-halfWidth, 0, halfHeight))

        addChildNode(topRight)
        topRight.position = position
        topRight.localTranslate(by: SCNVector3(halfWidth, 0, halfHeight))

        addChildNode(bottomLeft)
        bottomLeft.position = position
        bottomLeft.localTranslate(by: SCNVector3(-halfWidth, 0, -halfHeight))

        addChildNode(bottomRight)
        bottomRight.position = position
        bottomRight.localTranslate(by: SCNVector3(halfWidth, 0, -halfHeight))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /*static func tracking(anchor: ARImageAnchor, inScene scene: ARSCNView) -> CornerTrackingNode? {
        guard let node = scene.node(for: anchor) else { return nil }
        let tracker = CornerTrackingNode(anchor: anchor)
        node.addChildNode(tracker)
        return tracker
    }*/

}
