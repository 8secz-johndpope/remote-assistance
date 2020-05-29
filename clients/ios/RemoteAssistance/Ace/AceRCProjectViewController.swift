//
//  AceRCProjectViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 4/28/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import RealityKit
import ARKit

protocol AceRCProjectViewControllerDelegate: class
{
    func aceRCProjectViewControllerResponse(text: String)
}

class AceRCProjectViewController : UIViewController {
    
    @IBOutlet weak var arView: ARView!
    
    private let configuration = ARWorldTrackingConfiguration()
    
    var sceneName = "Copier"
    var showDebug = false
    var anchorEntity:AnchorEntity!
    var copierAnchor:Copier.Start!
    var open = false
    weak var delegate: AceRCProjectViewControllerDelegate?

    override func viewDidLoad() {
        configuration.planeDetection = [.horizontal]
        if showDebug {
            arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        }
        
        arView.session.delegate = self
        
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) {
            configuration.detectionImages = referenceImages
        }
        
// uncomment to detect objects
//        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "VariousPrinters", bundle: Bundle.main) {
//            configuration.detectionObjects = referenceObjects
//        }
        
        copierAnchor = try! Copier.loadStart()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tap.delegate = self.parent as? UIGestureRecognizerDelegate
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppUtility.lockOrientation(.landscape, andRotateTo: .landscapeRight)
        arView.session.run(configuration, options: [])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        arView.session.pause()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppUtility.lockOrientation(.all)
        self.delegate?.aceRCProjectViewControllerResponse(text: "")
    }
        
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        // trigger on any taps
        if open {
            open = false
            copierAnchor.notifications.prevTrigger.post()
        } else {
            open = true
            copierAnchor.notifications.nextTrigger.post()
        }
    }
}


extension AceRCProjectViewController : ARSessionDelegate {

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        anchors.forEach { _ in
            // create object
            anchorEntity = AnchorEntity()
            anchorEntity.addChild(copierAnchor)
            arView.scene.anchors.append(anchorEntity)

        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {  
        anchors.compactMap { $0 as? ARImageAnchor }.forEach {
            // update position
            anchorEntity.transform.matrix = $0.transform
        }  
    }
}
