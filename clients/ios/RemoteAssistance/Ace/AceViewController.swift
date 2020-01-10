//
//  AceViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/10/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class AceViewController : UIViewController {
    
//    @IBOutlet var arView: ARSCNView!
//    
//    public static var roomName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
}


extension AceViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // If you want to render raw camera frame.
        // self.capturer.captureFrame(frame.capturedImage)

//        let now = Date().timeIntervalSince1970
//
//        if now - self.lastTimeStamp > 0.040 {
//            let image = self.sceneView.snapshot()
//            self.capturer.captureFrame(image)
//            self.lastTimeStamp = now
//        }
    }
}
