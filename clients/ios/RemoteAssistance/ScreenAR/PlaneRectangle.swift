import Foundation
import ARKit
import Vision

class PlaneRectangle: NSObject {
    
    // Plane anchor this rectangle is attached to
    private(set) var anchor: ARPlaneAnchor
    
    // Center position in 3D space
    private(set) var position: SCNVector3
    
    // Dimensions of the rectangle
    private(set) var size: CGSize
    
    // Orientation of the rectangle based on how much it's rotated around the y axis
    private(set) var orientation: Float
    
    private(set) var verticalPlaneAnchor: Bool
    //private(set) var verticalOrientation: Float

    // Creates a rectangleon 3D space based on a VNRectangleObservation found in a given ARSCNView
    // Returns nil if no plane can be found that contains the rectangle
    init?(for rectangle: VNRectangleObservation, in sceneView: ARSCNView, transform: CGAffineTransform) {
        guard let cornersAndAnchor = getCorners(for: rectangle, in: sceneView, transform: transform) else {
            return nil
        }
        
        let corners = cornersAndAnchor.corners
        self.verticalPlaneAnchor = cornersAndAnchor.anchor.alignment == ARPlaneAnchor.Alignment.vertical
        self.anchor = cornersAndAnchor.anchor
        self.position = corners.center
        
        //placeBlockOnPlaneAt(cornersAndAnchor.hit, sceneView: sceneView, position3d: corners.center, width: corners.height, height: corners.width, orientation: corners.orientation, vertical: self.verticalPlaneAnchor)
        
        self.size = CGSize(width: corners.width, height: corners.height)
        self.orientation = corners.orientation
    
        // from https://stackoverflow.com/questions/49011619/arkit-1-5-how-to-get-the-rotation-of-a-vertical-plane
    }
    
    init(anchor: ARPlaneAnchor, position: SCNVector3, size: CGSize, orientation: Float) {
        self.anchor = anchor
        self.position = position
        self.size = size
        self.orientation = orientation
        self.verticalPlaneAnchor = false
        //self.verticalOrientation = 0
        super.init()
    }
    
    private override init() {
        fatalError("Not implemented")
    }
}

fileprivate enum RectangleCorners {
    case topLeft(topLeft: SCNVector3, topRight: SCNVector3, bottomLeft: SCNVector3)
    case topRight(topLeft: SCNVector3, topRight: SCNVector3, bottomRight: SCNVector3)
    case bottomLeft(topLeft: SCNVector3, bottomLeft: SCNVector3, bottomRight: SCNVector3)
    case bottomRight(topRight: SCNVector3, bottomLeft: SCNVector3, bottomRight: SCNVector3)
}


/*func placeBlockOnPlaneAt(_ hit: ARHitTestResult, sceneView: ARSCNView, position3d: SCNVector3, width: CGFloat, height: CGFloat, orientation: Float, vertical: Bool) -> SCNNode? {
    let box: SCNNode
    if (vertical) {
        box = createBox(width:width, height:height, color: UIColor.green)
    }
    else {
        box = createBox(width:height, height:width, color: UIColor.green)
    }
    //position(node: box, atHit: hit, orientation: orientation, vertical: vertical)
    box.position = position3d
    box.rotation = SCNVector4Make(orientation + Float.pi, 0, 1, 0)
    box.eulerAngles.x += Float.pi / 2

    //let subbox = createBox(width: width, height: height, color: UIColor.blue)
    //subbox.eulerAngles.z = Float.pi / 2
    //box.addChildNode(subbox)

    sceneView.scene.rootNode.addChildNode(box)
    return box
}*/

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

/*private func position(node: SCNNode, atHit hit: ARHitTestResult, orientation: Float, vertical:Bool) {
    //node.transform = SCNMatrix4(hit.anchor!.transform)
    node.eulerAngles = SCNVector3Make(node.eulerAngles.x + (Float.pi / 2), node.eulerAngles.y, node.eulerAngles.z)
    //node.eulerAngles = SCNVector3Make(node.eulerAngles.x + (Float.pi / 2), node.eulerAngles.y+GLKMathDegreesToRadians(45), node.eulerAngles.z)

    let position = SCNVector3Make(hit.worldTransform.columns.3.x + node.geometry!.boundingBox.min.z, hit.worldTransform.columns.3.y, hit.worldTransform.columns.3.z)
    node.position = position
    //node.rotation = SCNVector4(0,0,0,0)
}*/

func addCornerBox(position: SCNVector3, sceneView: ARSCNView, name: String)
{
    //let box = createBox(width: 0.005, height: 0.005, color: UIColor.red)
    let box = createBox(width: 0.0, height: 0.0, color: UIColor.red)
    box.position = position
    //box.position.y -= 0.005
    sceneView.scene.rootNode.addChildNode(box)
    box.name = name
}

// Finds 3d vector points for the corners of a rectangle on a plane in a given scene
// Returns 3 corners representing the rectangle as well as the anchor for its plane
fileprivate func getCorners(for rectangle: VNRectangleObservation, in sceneView: ARSCNView, transform: CGAffineTransform) -> (corners: RectangleCorners, anchor: ARPlaneAnchor, hit: ARHitTestResult)? {
    
    // Perform a hittest on each corner to find intersecting surfaces
    /*let tl = sceneView.hitTest(sceneView.convertFromCamera(rectangle.topLeft), types: .existingPlaneUsingExtent)
    let tr = sceneView.hitTest(sceneView.convertFromCamera(rectangle.topRight), types: .existingPlaneUsingExtent)
    let bl = sceneView.hitTest(sceneView.convertFromCamera(rectangle.bottomLeft), types: .existingPlaneUsingExtent)
    let br = sceneView.hitTest(sceneView.convertFromCamera(rectangle.bottomRight), types: .existingPlaneUsingExtent)*/

    let tl = sceneView.hitTest(rectangle.topLeft.applying(transform), types: .existingPlaneUsingExtent)
    let tr = sceneView.hitTest(rectangle.topRight.applying(transform), types: .existingPlaneUsingExtent)
    let bl = sceneView.hitTest(rectangle.bottomLeft.applying(transform), types: .existingPlaneUsingExtent)
    let br = sceneView.hitTest(rectangle.bottomRight.applying(transform), types: .existingPlaneUsingExtent)

    print("tl: \(tl.count) tr: \(tr.count) br: \(br.count) bl: \(bl.count)")
    if tl.count > 0 && tr.count > 0 && br.count > 0 && bl.count > 0 {
        print("adding 4 corner boxes to track the rectangle")
        addCornerBox(position: tl.first!.worldVector, sceneView: sceneView, name:"tl")
        addCornerBox(position: tr.first!.worldVector, sceneView: sceneView, name:"tr")
        addCornerBox(position: bl.first!.worldVector, sceneView: sceneView, name:"bl")
        addCornerBox(position: br.first!.worldVector, sceneView: sceneView, name:"br")
    }
    // Not all 4 corners will necessarily be found on the same plane,
    // but we only need 3 corners to define a rectangle.
    // For a set of 3 corners, we will filter out hitResults that don't
    // have a common anchor with all 3 corners and use the closest anchor.
    // For this, we'll need a comparator that returns true if two HitResults use the same anchor
    let hitResultAnchorComparator: (ARHitTestResult, ARHitTestResult) -> Bool = { (hit1, hit2) in
        hit1.anchor == hit2.anchor
    }

    
    // Check top & left corners for a common anchor
    var surfaces = filterByIntersection([tl, tr, bl], where: hitResultAnchorComparator)
    if let tlHit = surfaces[0].first,
        let trHit = surfaces[1].first,
        let blHit = surfaces[2].first,
        let anchor = tlHit.anchor as? ARPlaneAnchor {

        print("Found top left corners: \(tlHit.worldVector), \(trHit.worldVector), \(blHit.worldVector)")
        return (.topLeft(topLeft: tlHit.worldVector,
                         topRight: trHit.worldVector,
                         bottomLeft: blHit.worldVector),
                anchor, tlHit)
    }
    
    // Check top & right corners for a common anchor
    surfaces = filterByIntersection([tl, tr, br], where: hitResultAnchorComparator)
    if let tlHit = surfaces[0].first,
        let trHit = surfaces[1].first,
        let brHit = surfaces[2].first,
        let anchor = tlHit.anchor as? ARPlaneAnchor {
        
        print("Found top right corners: \(tlHit.worldVector), \(trHit.worldVector), \(brHit.worldVector)")
        
        return (.topRight(topLeft: tlHit.worldVector,
                          topRight: trHit.worldVector,
                          bottomRight: brHit.worldVector),
                anchor, tlHit)
    }
    
    // Check bottom & left corners for a common anchor
    surfaces = filterByIntersection([tl, bl, br], where: hitResultAnchorComparator)
    if let tlHit = surfaces[0].first,
        let blHit = surfaces[1].first,
        let brHit = surfaces[2].first,
        let anchor = tlHit.anchor as? ARPlaneAnchor {
        
        print("Found bottom left corners: \(tlHit.worldVector), \(blHit.worldVector), \(brHit.worldVector)")
        
        return (.bottomLeft(topLeft: tlHit.worldVector,
                            bottomLeft: blHit.worldVector,
                            bottomRight: brHit.worldVector),
                anchor, tlHit)
    }
    
    // Check bottom & right corners for a common anchor
    surfaces = filterByIntersection([tr, bl, br], where: hitResultAnchorComparator)
    if let trHit = surfaces[0].first,
        let blHit = surfaces[1].first,
        let brHit = surfaces[2].first,
        let anchor = trHit.anchor as? ARPlaneAnchor {
        
        print("Found bottom right corners: \(trHit.worldVector), \(blHit.worldVector), \(brHit.worldVector)")
        
        return (.bottomRight(topRight: trHit.worldVector,
                             bottomLeft: blHit.worldVector,
                             bottomRight: brHit.worldVector),
                anchor, trHit)
    }
    
    // No set of 3 points have a common anchor, so a rectangle cannot be found on a plane
    return nil
}

extension RectangleCorners {
    
    // Returns width based on left and right corners for one either top or bottom side
    var width: CGFloat {
        get {
            switch self {
            case .topLeft(let left, let right, _),
                 .topRight(let left, let right, _),
                 .bottomLeft(_, let left, let right),
                 .bottomRight(_, let left, let right):
                return right.distance(from: left)
            }
        }
    }
    
    // Returns height based on top and bottom corners for either left or right side
    var height: CGFloat {
        get {
            switch self {
            case .topLeft(let top, _, let bottom),
                 .topRight(_, let top, let bottom),
                 .bottomLeft(let top, let bottom, _),
                 .bottomRight(let top, _, let bottom):
                return top.distance(from: bottom)
            }
        }
    }
    
    // Returns the midpoint from opposite corners of rectangle
    var center: SCNVector3 {
        get {
            switch self {
            case .topLeft(_, let c1, let c2),
                 .topRight(let c1, _, let c2),
                 .bottomRight(let c1, let c2, _),
                 .bottomLeft(let c1, _, let c2):
                return c1.midpoint(from: c2)
            }
        }
    }
    
    // Returns the angle of the vertex corner
    /*var cornerAngle: CGFloat {
        get {
            switch self {
            // c is the vertex and a & b are the points of the other corners
            case .topLeft(let c, let a, let b),
                 .topRight(let a, let c, let b),
                 .bottomLeft(let a, let c, let b),
                 .bottomRight(let a, let b, let c):
                
                let distA = c.distance(from: b)
                let distB = c.distance(from: a)
                let distC = a.distance(from: b)
                
                let cosC = ((distA * distA) + (distB * distB) - (distC * distC)) / (2 * distA * distB)
                return acos(cosC)
            }
        }
    }*/
    
    // Returns the orientation of the rectangle based on how much the rectangle is rotated around the y axis
    var orientation: Float {
        get {
            switch self {
            case .topLeft(let left, let right, _),
                 .topRight(let left, let right, _),
                 .bottomLeft(_, let left, let right),
                 .bottomRight(_, let left, let right):
                let distX = right.x - left.x
                let distZ = right.z - left.z
                let result = -atan(distZ / distX)
                print("orientation=",left,right,distX,distZ,result)
                return result
            }
        }
    }
}
