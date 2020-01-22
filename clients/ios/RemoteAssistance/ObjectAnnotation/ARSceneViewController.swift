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

class ARSceneViewController: UIViewController, ARSCNViewDelegate, ClickableObjectDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    var objectGroupName:String!
    var videoTag:Int = -1
    var clickableImages:[UIImage]!
    var imagePositions:[SCNVector3]!
    var videoURLs:[URL]!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Search Scene"
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ARSceneViewController.dismissView))
        let searchBarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(ARSceneViewController.searchForObjects))
        self.navigationItem.rightBarButtonItems = [searchBarButton, doneBarButton]

        //self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.delegate = self
        // TODO: Load the reference objects we are going to scan for
        self.objectGroupName = "VariousPrinters"
    }
    
    @objc func searchForObjects() {
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: self.objectGroupName, bundle: nil) {
            self.configuration.detectionObjects = referenceObjects
            sceneView.session.run(self.configuration)
        }
        else {
            self.showMessage(title:"Assets Missing", message: "Missing expected asset catalog: \(String(describing: self.objectGroupName))")
        }
    }
    
    @objc func dismissView() {
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let _ = anchor as? ARObjectAnchor {
            // TODO: Load assets for the object detected
            self.loadInteralAssets()

            DispatchQueue.main.async {
                
                for i in 0..<self.clickableImages.count {
                    let clickableElement = ClickableObject(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
                    clickableElement.setImage(self.clickableImages[i], for: UIControl.State.normal)
                    clickableElement.delegate = self
                    clickableElement.tag = i
                    let material = SCNMaterial()
                    material.diffuse.contents = clickableElement
                    let clickableNode = self.buildNode(material: material, scnVector3: self.imagePositions[i])
                    node.addChildNode(clickableNode)
                }
            }
        }
    }   
    
    func buildNode(material: SCNMaterial, scnVector3: SCNVector3) -> SCNNode {
        let node = SCNNode(geometry: SCNBox(width: 0.3, height: 0.3, length: 0.001))
        node.geometry?.firstMaterial = material
        node.position = scnVector3
        node.opacity = 1
        return node
    }

    func showMessage(title: String, message:String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
                (action : UIAlertAction!) -> Void in
            })
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showVideo(tag:Int) {
        self.videoTag = tag
        self.performSegue(withIdentifier: "showVideoPlayer", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVideoPlayer" {
            let avPlayerViewController = segue.destination as! AVPlayerViewController
            avPlayerViewController.url = self.videoURLs[self.videoTag]
        }
    }

    func loadInteralAssets() {
        self.clickableImages = [UIImage(named: "PrinterThumb1")!, UIImage(named: "PrinterThumb2")!, UIImage(named: "PrinterThumb3")!]
        self.imagePositions = [SCNVector3(x: -0.2, y: +0.4, z: +0.05), SCNVector3(x: +0.1, y: +0.4, z: +0.05), SCNVector3(x: -0.2, y: +0.1, z: +0.05)]
        self.videoURLs = [URL(fileURLWithPath: Bundle.main.path(forResource: "clip1", ofType: "mp4")!), URL(fileURLWithPath: Bundle.main.path(forResource: "clip2", ofType: "mp4")!), URL(fileURLWithPath: Bundle.main.path(forResource: "clip3", ofType: "mp4")!)]
    }
}
