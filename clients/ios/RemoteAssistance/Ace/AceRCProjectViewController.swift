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
    weak var delegate: AceRCProjectViewControllerDelegate?

    override func viewDidLoad() {
        configuration.planeDetection = [.horizontal]
        if showDebug {
            arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        }
        loadScene(sceneName)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.run(configuration, options: [])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.delegate?.aceRCProjectViewControllerResponse(text: "")
        super.viewWillDisappear(animated)
        arView.session.pause()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.aceRCProjectViewControllerResponse(text: "")
    }
    
    func loadScene(_ name:String) {
        
        guard let realityFileURL = Bundle.main.url(forResource: name, withExtension: "reality") else {
            return
        }

        let realityFileSceneURL = realityFileURL.appendingPathComponent("Start", isDirectory: false)
        if let anchorEntity = try? AnchorEntity.loadAnchor(contentsOf: realityFileSceneURL) {
            let start = AnchorEntity()
            start.anchoring = anchorEntity.anchoring
            start.addChild(anchorEntity)
            
            arView.scene.anchors.append(start)
        }
    }
}
