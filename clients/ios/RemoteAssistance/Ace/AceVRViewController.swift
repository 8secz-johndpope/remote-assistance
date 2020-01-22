//
//  AceVRViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/21/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import ARKit

class AceVRViewController : UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView?
    @IBOutlet weak var sceneViewLeft: ARSCNView!
    @IBOutlet weak var sceneViewRight: ARSCNView!
    
    let eyeCamera : SCNCamera = SCNCamera()
    var lastFrame: ARFrame?

    // Pass-through uses a camera to show the outside world (like Merge VR, Gear VR). See-through headsets allow your eyes to see the real world (Aryzon, Hololens, Northstar).
    let _HEADSET_IS_PASSTHROUGH_VS_SEETHROUGH = true
    let _CAMERA_IS_ON_LEFT_EYE = false
    
    // This is the value for the distance between two pupils (in metres). The Interpupilary Distance (IPD).
    let interpupilaryDistance : Float = 0.066
     
     /*
      SET eyeFOV and cameraImageScale. UNCOMMENT any of the below lines to change FOV:
      */
     //    let eyeFOV = 38.5; var cameraImageScale = 1.739; // (FOV: 38.5 ± 2.0) Brute-force estimate based on iPhone7+
    // Calculation based on iPhone7+ // <- Works ok for cheap mobile headsets. Rough guestimate.
    let eyeFOV = 60
    var cameraImageScale = 3.478

    override func viewDidLoad() {
        super.viewDidLoad()
        
         // Set up Left-Eye SceneView
         sceneViewLeft.scene = sceneView!.scene
         sceneViewLeft.showsStatistics = sceneView!.showsStatistics
         sceneViewLeft.isPlaying = true
         
         // Set up Right-Eye SceneView
         sceneViewRight.scene = sceneView!.scene
         sceneViewRight.showsStatistics = sceneView!.showsStatistics
         sceneViewRight.isPlaying = true
        
        if #available(iOS 11.3, *) {
            print("iOS 11.3 or later")
            cameraImageScale = cameraImageScale * 1080.0 / 720.0
        } else {
            print("earlier than iOS 11.3")
        }
        
        // Create CAMERA
        eyeCamera.zNear = 0.001
        /*
         Note:
         - camera.projectionTransform was not used as it currently prevents the simplistic setting of .fieldOfView . The lack of metal, or lower-level calculations, is likely what is causing mild latency with the camera.
         - .fieldOfView may refer to .yFov or a diagonal-fov.
         - in a STEREOSCOPIC layout on iPhone7+, the fieldOfView of one eye by default, is closer to 38.5°, than the listed default of 60°
         */
        eyeCamera.fieldOfView = CGFloat(eyeFOV)

    }
    
    func updateFrame() {
        updatePOVs()
    }

    func updatePOVs() {
        /////////////////////////////////////////////
        // CREATE POINT OF VIEWS
        guard let sceneView = self.sceneView else { return }
        
        let pointOfView : SCNNode = SCNNode()
        pointOfView.transform = (sceneView.pointOfView?.transform)!
        pointOfView.scale = (sceneView.pointOfView?.scale)!
        // Create POV from Camera
        pointOfView.camera = eyeCamera
        
        let sceneViewMain = _CAMERA_IS_ON_LEFT_EYE ? sceneViewLeft! : sceneViewRight!
        let sceneViewScnd = _CAMERA_IS_ON_LEFT_EYE ? sceneViewRight! : sceneViewLeft!
        
        //////////////////////////
        // Set PointOfView of Main Camera Eye
        
        sceneViewMain.pointOfView = pointOfView

        //////////////////////////
        // Set PointOfView of Virtual Second Eye
        
        // Clone pointOfView for Right-Eye SceneView
        let pointOfView2 : SCNNode = (sceneViewMain.pointOfView?.clone())! // Note: We clone the pov of sceneViewLeft here, not sceneView - to get the correct Camera FOV.
        
        // Determine Adjusted Position for Right Eye
        
        // Get original orientation. Co-ordinates:
        let orientation : SCNQuaternion = pointOfView2.orientation // not '.worldOrientation'
        // Convert to GLK
        let orientation_glk : GLKQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        
        // Set Transform Vector (this case it's the Positive X-Axis.)
        let xdir : Float = _CAMERA_IS_ON_LEFT_EYE ? 1.0 : -1.0
        let alternateEyePos : GLKVector3 = GLKVector3Make(xdir, 0.0, 0.0) // e.g. This would be GLKVector3Make(- 1.0, 0.0, 0.0) if we were manipulating an eye to the 'left' of the source-View. Or, in the odd case we were manipulating an eye that was 'above' the eye of the source-view, it'd be GLKVector3Make(0.0, 1.0, 0.0).
        
        // Calculate Transform Vector
        let transformVector = getTransformForNewNodePovPosition(orientationQuaternion: orientation_glk, eyePosDirection: alternateEyePos, magnitude: interpupilaryDistance)
        
        // Add Transform to PointOfView2
        pointOfView2.localTranslate(by: transformVector) // works - just not entirely certain
        
        // Set PointOfView2 for SceneView-RightEye
        sceneViewScnd.pointOfView = pointOfView2
    }
    
    /**
     Used by POVs to ensure correct POVs.
     
     For EyePosVector e.g. This would be GLKVector3Make(- 1.0, 0.0, 0.0) if we were manipulating an eye to the 'left' of the source-View. Or, in the odd case we were manipulating an eye that was 'above' the eye of the source-view, it'd be GLKVector3Make(0.0, 1.0, 0.0).
     */
    private func getTransformForNewNodePovPosition(orientationQuaternion: GLKQuaternion, eyePosDirection: GLKVector3, magnitude: Float) -> SCNVector3 {
        
        // Rotate POV's-Orientation-Quaternion around Vector-to-EyePos.
        let rotatedEyePos : GLKVector3 = GLKQuaternionRotateVector3(orientationQuaternion, eyePosDirection)
        // Convert to SceneKit Vector
        let rotatedEyePos_SCNV : SCNVector3 = SCNVector3Make(rotatedEyePos.x, rotatedEyePos.y, rotatedEyePos.z)
        
        // Multiply Vector by magnitude (interpupilary distance)
        let transformVector : SCNVector3 = SCNVector3Make(rotatedEyePos_SCNV.x * magnitude,
                                                          rotatedEyePos_SCNV.y * magnitude,
                                                          rotatedEyePos_SCNV.z * magnitude)
        
        return transformVector
        
    }
}
