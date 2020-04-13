//
//  AceAnimatorViewController.swift
//  RemoteAssistance
//
//  Created by Gerry Filby on 4/9/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import ARKit
import AVKit
import AVFoundation
import SceneKit

class AceAnimatorViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    var objectGroupName:String!
    var imageGroupName:String!
    var clickableImages:[UIImage]!
    var renderer:SCNSceneRenderer?
    var anchorFound = false
    var nodeFound:SCNNode?
    var copierNode:AceVirtualObject?
    var lastTonerNOde:AceVirtualObject?
    var lastSceneDisplayed:Int = 0
    
    let sceneNames = ["Copier.scn", "Toner1.scn", "Toner2.scn", "Toner3.scn", "Toner4.scn"]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.sceneView.delegate = self
        self.configuration.automaticImageScaleEstimationEnabled = true
        self.objectGroupName = "VariousPrinters"
        self.imageGroupName = "AR Resources"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.view.addGestureRecognizer(tap)

        self.searchForObjects()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sceneView.session.pause()
        self.anchorFound = false
        
        self.view.removeGestureRecognizers()
    }
    
    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        print("onTap from ARSceneViewController")

        DispatchQueue.main.async {

            self.lastSceneDisplayed += 1
            if self.anchorFound && (self.lastSceneDisplayed < self.sceneNames.count) {
                print(self.sceneNames[self.lastSceneDisplayed])
                let tonerNode = AceVirtualObject.object(byName: self.sceneNames[self.lastSceneDisplayed])
                if let _ = self.lastTonerNOde {
                    tonerNode!.position = SCNVector3(0.0054, 0.0, 0.0)
                    self.lastTonerNOde?.addChildNode(tonerNode!)
                }
                else {
                    tonerNode!.scale = SCNVector3(0.9, 0.9, 0.9)
                    tonerNode!.position = SCNVector3(-0.0175, +0.071, 0.05)
                    self.copierNode?.addChildNode(tonerNode!)
                }
                self.lastTonerNOde = tonerNode
            }
            else {
                print("no more scenes")
            }
        }
    }

    @objc func searchForObjects() {
        let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: self.objectGroupName, bundle: Bundle.main)
        let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: self.imageGroupName, bundle: Bundle.main)
        self.searchForObjects(arReferenceObjects: referenceObjects, arReferenceImages: referenceImages)
    }
    
    @objc func searchForObjects(arReferenceObjects:Set<ARReferenceObject>?, arReferenceImages:Set<ARReferenceImage>?) {
        
        self.anchorFound = false
        
        var haveDetectionAssets = false
        if let referenceObjects = arReferenceObjects {
            haveDetectionAssets = true
            self.configuration.detectionObjects = referenceObjects
        }

        if let referenceImages = arReferenceImages {
            haveDetectionAssets = true
            self.configuration.detectionImages = referenceImages
        }
        
        if haveDetectionAssets {
            let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors, .stopTrackedRaycasts]
            self.configuration.automaticImageScaleEstimationEnabled = true
            sceneView.session.run(self.configuration, options: options)
        }
    }

    @objc func pauseSession() {
        self.sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        self.renderer = renderer

        if !self.anchorFound {
            if let _ = anchor as? ARImageAnchor {
                self.anchorFound = true
                print("ObjectAnnotation found imageAnchor!")
                self.showToast(message: "Found image anchor: \(String(describing: anchor.name))")
                DispatchQueue.main.async {

                    let orientationNode = SCNNode()
                    orientationNode.eulerAngles = SCNVector3(x:-Float.pi/2, y:0, z:0)
                    node.addChildNode(orientationNode)
                    self.nodeFound = orientationNode
                    self.copierNode = AceVirtualObject.object(byName: self.sceneNames[self.lastSceneDisplayed])
                    self.copierNode!.scale = SCNVector3(5, 5, 5)
                    self.copierNode!.position = SCNVector3(+0.125,-0.25,-0.2)
                    self.nodeFound?.addChildNode(self.copierNode!)
                }
            }
            
            if let _ = anchor as? ARObjectAnchor {
                self.anchorFound = true
                print("ObjectAnnotation found objectAnchor!")
                self.showToast(message: "Found object anchor: \(String(describing: anchor.name))")
                DispatchQueue.main.async {
                    self.nodeFound = node
                }
            }
        }
    }
    
    func buildNode(scnVector3: SCNVector3, nodeQuat:SCNQuaternion) -> SCNNode {
        let copierNode = AceVirtualObject.object(byName: "Copier.scn")
        copierNode?.scale = SCNVector3(5, 5, 5)
        copierNode?.position = scnVector3
        let orientationNode = SCNNode()
        orientationNode.orientation = SCNVector4(x: -nodeQuat.x, y: -nodeQuat.y, z:-nodeQuat.z, w: nodeQuat.w)
        orientationNode.addChildNode(copierNode!)
        return orientationNode
    }

    func showToast(message:String) {
        DispatchQueue.main.async {
            self.view.makeToast(message)
        }
    }
    
    func getModelUrl(name:String) -> URL? {
        
        let modelsURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil)!
        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!
        var foundUrl:URL?
        for element in fileEnumerator {
            let url = element as! URL
            print(url)
            let fileName = url.pathComponents.last! as String
            if fileName == name {
                foundUrl = url
            }
        }
        
        return foundUrl
    }
}
