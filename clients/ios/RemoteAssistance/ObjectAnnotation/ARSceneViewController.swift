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
    
    let configuration = ARWorldTrackingConfiguration()
    var objectGroupName:String!
    var imageGroupName:String!
    var clickableImages:[UIImage]!
    var imagePositions:[SCNVector3]!
    var videoURLs:[URL]!
    var searchBarButton:UIBarButtonItem!
    var pauseBarButton:UIBarButtonItem!
    var renderer:SCNSceneRenderer?
    var anchorFound = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Search Scene"
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.delegate = self
        // TODO: This should be pulled from previous activity in other sections of the app
        self.objectGroupName = "VariousPrinters"
        self.imageGroupName = "AR Resources"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchForObjects()

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.view.addGestureRecognizer(tap)
        // TODO: Optionally load assets from API
        self.loadInteralAssets()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sceneView.session.pause()
        self.anchorFound = false
        
        self.view.removeGestureRecognizers()
    }
    
    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        print("onTap from ARSceneViewController")

        let location = gesture.location(in: self.sceneView)

        let hitResults = self.renderer?.hitTest(location, options:nil)
        if let hit = hitResults?.first {
            let node = hit.node
            if let obj = node.geometry?.firstMaterial?.diffuse.contents as? UIImage {
                if let tag = self.clickableImages.firstIndex(of: obj) {
                    self.showVideo(tag: tag)
                }
            }
        }
    }
    
    @objc func searchForObjects() {
        self.anchorFound = false
        var foundAllObjects = true
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: self.objectGroupName, bundle: Bundle.main) {
            self.configuration.detectionObjects = referenceObjects
        }
        else {
            foundAllObjects = false
            self.showMessage(title:"Assets Missing", message: "Missing expected assets in catalog: \(String(describing: self.objectGroupName))")
        }
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: self.imageGroupName, bundle: Bundle.main) {
            self.configuration.detectionImages = referenceImages
        }
        else {
            foundAllObjects = false
            self.showMessage(title:"Assets Missing", message: "Missing expected assets in catalog: \(String(describing: self.imageGroupName))")
        }
        if foundAllObjects {
            let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
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
                DispatchQueue.main.async {
                    for i in 0..<self.clickableImages.count {
                        let material = SCNMaterial()
                        material.diffuse.contents = self.clickableImages[i]
                        let clickableNode = self.buildNode(material: material, scnVector3: self.imagePositions[i])
                        node.addChildNode(clickableNode)
                    }
                }
            }
            
            if let _ = anchor as? ARObjectAnchor {
                self.anchorFound = true
                print("ObjectAnnotation found objectAnchor!")
                DispatchQueue.main.async {
                    for i in 0..<self.clickableImages.count {
                        let material = SCNMaterial()
                        material.diffuse.contents = self.clickableImages[i]
                        let clickableNode = self.buildNode(material: material, scnVector3: self.imagePositions[i])
                        node.addChildNode(clickableNode)
                    }
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
                
        let videoURL = self.videoURLs[tag]
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVKit.AVPlayerViewController()
        playerViewController.player = player
        self.navigationController?.pushViewController(playerViewController)
    }
    
    func loadInteralAssets() {
        self.clickableImages = [UIImage(named: "PrinterThumb1")!, UIImage(named: "PrinterThumb2")!, UIImage(named: "PrinterThumb3")!]
        self.imagePositions = [SCNVector3(x: -0.2, y: +0.4, z: +0.05), SCNVector3(x: +0.1, y: +0.4, z: +0.05), SCNVector3(x: -0.2, y: +0.1, z: +0.05)]
        self.videoURLs = [URL(fileURLWithPath: Bundle.main.path(forResource: "clip1", ofType: "mp4")!), URL(fileURLWithPath: Bundle.main.path(forResource: "clip2", ofType: "mp4")!), URL(fileURLWithPath: Bundle.main.path(forResource: "clip3", ofType: "mp4")!)]
    }
}
