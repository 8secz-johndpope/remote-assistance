//
//  ARSceneViewController.swift
//  RemoteAssistance
//
//  Created by Gerry Filby on 1/8/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import ARKit
import AVKit
import AVFoundation

class ARSceneViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var detectObjectsButton: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.delegate = self
    }
    
    @IBAction func detectObjectsButtonTUI(_ sender: Any) {
//        guard let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "LaserJet400", bundle: nil) else {
//            fatalError("Missing expected asset catalog resources.")
//        }
//        self.configuration.detectionObjects = referenceObjects
//        sceneView.session.run(self.configuration)
        self.performSegue(withIdentifier: "showVideoClip", sender: self)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let objectAnchor = anchor as? ARObjectAnchor {
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVideoClip" {
            let avPlayerViewController = segue.destination as! AVPlayerViewController
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
