import ARKit

class SurfaceNode: SCNNode {
    
    private(set) var anchor: ARPlaneAnchor
    private(set) var planeGeometry: SCNPlane
    let offsety: Float = 0//-0.04 // behind so it will appear behind detected ARAnchorImages
    //let renderingOrderLast = 1000
    init(anchor: ARPlaneAnchor) {
        
        self.anchor = anchor
        
        // Create the 3D plane geometry with the dimensions reported
        // by ARKit in the ARPlaneAnchor instance
        self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        //self.planeGeometry = SCNPlane(width: 0.2, height: 0.2)
        
        super.init()
        
        //self.renderingOrder = renderingOrderLast
        let image = UIImage(named: "Grid")
        
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        /*// Instead of just visualizing the grid as a gray plane, we will render
        // it in some Tron style colours.
        let material = SCNMaterial()
        let img = #imageLiteral(resourceName: "tron_grid")
        material.diffuse.contents = img
        
        // Set grid image to 1" per square (image is 0.4064 m)
        material.diffuse.wrapT = .repeat
        material.diffuse.wrapS = .repeat
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(2.46062992 * anchor.extent.x, 2.46062992 * anchor.extent.z, 0)
        self.planeGeometry.materials = [material]*/
        
        //self.planeGeometry.cornerRadius = 0.008
        self.planeGeometry.materials = [material]

        let planeNode = SCNNode(geometry: self.planeGeometry)

        // Move the plane to the position reported by ARKit
        self.position = SCNVector3(anchor.center.x, offsety, anchor.center.z)
        
        // Planes in SceneKit are vertical by default so we need to rotate
        // 90 degrees to match planes in ARKit
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
        
        self.opacity = 0.4
        // We add the new node to ourself since we inherited from SCNNode
        self.addChildNode(planeNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(_ anchor: ARPlaneAnchor) {
        self.planeGeometry.width = CGFloat(anchor.extent.x)
        self.planeGeometry.height = CGFloat(anchor.extent.z)
        
        let mmPerMeter: Float = 1000
        let mmOfImage: Float = 65
        let repeatAmount: Float = mmPerMeter / mmOfImage
        
        self.planeGeometry.materials.first?.diffuse.contentsTransform = SCNMatrix4MakeScale(anchor.extent.x * repeatAmount, anchor.extent.z * repeatAmount, 1)
        // When the plane is first created it's center is 0,0,0 and
        // the nodes transform contains the translation parameters.
        // As the plane is updated the planes translation remains the
        // same but it's center is updated so we need to update the 3D
        // geometry position
        //print("new position",anchor.center)
        self.position = SCNVector3Make(anchor.center.x, offsety, anchor.center.z);
    }
}
