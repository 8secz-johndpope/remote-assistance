
import UIKit
import SceneKit
import ARKit
import Vision
import WebKit

private let meters2inches = CGFloat(39.3701)

class RectangleNode: SCNNode {
    
    private(set) var textureImage: UIImage?
    private var timer:Timer?
    private var view:UIView
    private var material:SCNMaterial = SCNMaterial()
    //let renderingOrderFirst = -1

    convenience init(_ planeRectangle: PlaneRectangle, view: UIView) {
        self.init(center: planeRectangle.position,
        width: planeRectangle.size.width,
        height: planeRectangle.size.height,
        orientation: planeRectangle.orientation, vertical: planeRectangle.verticalPlaneAnchor, view: view)//, vorientation: planeRectangle.verticalOrientation, anchor: planeRectangle.anchor)
    }
    
    init(imageAnchor: ARImageAnchor, rootNode: SCNNode, view: UIView)
    {
        self.view = view
        super.init()
        //self.renderingOrder = renderingOrderFirst

        let webViewMaterial = self.material
        webViewMaterial.diffuse.contents = UIImage.init(view)
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(RectangleNode.update), userInfo: nil, repeats: true)
        let width = imageAnchor.referenceImage.physicalSize.width
        let height = imageAnchor.referenceImage.physicalSize.height
        //let planeNode = SCNNode()
        let planeGeometry = SCNPlane(width: width, height: height)
        planeGeometry.materials = [webViewMaterial]
        //planeGeometry.firstMaterial?.diffuse.contents = UIColor.white
        //planeNode.opacity = 1.0
        //planeNode.geometry = planeGeometry
        self.geometry = planeGeometry

        // Rotate The PlaneNode To Horizontal
        //planeNode.eulerAngles.x = -.pi/2
        self.eulerAngles.x = -.pi/2

        //planeNode.position.y = 0.05
        // The Node Is Centered In The Anchor (0,0,0)
        //rootNode.addChildNode(planeNode)
        rootNode.addChildNode(self)

        createCornerAnchors(imageAnchor: imageAnchor, rootNode: rootNode)
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

        addCornerBox(position: corners.topLeft.position, node: rootNode, name:"tl")
        addCornerBox(position: corners.topRight.position, node: rootNode, name:"tr")
        addCornerBox(position: corners.bottomLeft.position, node: rootNode, name:"bl")
        addCornerBox(position: corners.bottomRight.position, node: rootNode, name:"br")
    }

    private func createBox(width: CGFloat, height: CGFloat, color: UIColor) -> SCNNode {
        //let box = SCNBox(width: 0.15, height: 0.20, length: 0.00, chamferRadius: 0.02)
        let box = SCNBox(width: width, height: height, length: 0.00, chamferRadius: 0.02)
        //let box = SCNPlane(width:width,height:height)
        let green = SCNMaterial()
        green.diffuse.contents = color
        box.materials = [green]
        
        let boxNode = SCNNode(geometry: box)
        //boxNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
        return boxNode
    }

    func addCornerBox(position: SCNVector3, node: SCNNode, name: String)
    {
        let box = createBox(width: 0.0, height: 0.0, color: UIColor.red)
        box.position = position
        node.addChildNode(box)
        //sceneView.scene.rootNode.addChildNode(box)
        box.name = name
    }

    init(center position: SCNVector3, width: CGFloat, height: CGFloat, orientation: Float, vertical: Bool, view: UIView)//, vorientation: Float, anchor: ARPlaneAnchor)
    {
        self.view = view
        super.init()
        //self.renderingOrder = renderingOrderFirst
        //print("orientation: \(orientation) position: \(position) width: \(width) (\(width * meters2inches)\") height: \(height) (\(height * meters2inches)\")")
        
        // Create the 3D plane geometry with the dimensions calculated from corners
        let planeGeometry = SCNPlane(width: width, height: height)
        let webViewMaterial = self.material
        webViewMaterial.diffuse.contents = UIImage.init(view)
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(RectangleNode.update), userInfo: nil, repeats: true)
        planeGeometry.materials = [webViewMaterial]
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func update() {
        DispatchQueue.main.async {
            self.material.diffuse.contents = UIImage.init(self.view)
            /*let v = self.view as! WKWebView
            v.takeSnapshot(with: nil) { (image, err) in
                if (err != nil) {
                    print("error takeSnapshot wkwebview",err!)
                }
                else if image != nil {
                    self.material.diffuse.contents = image
                }
            }*/

        }
    }
}


extension UIImage {
    convenience init(_ view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
}

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
