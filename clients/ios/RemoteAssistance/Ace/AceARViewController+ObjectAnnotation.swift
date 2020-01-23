//
//  AceARViewController+ObjectAnnotation.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/22/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import ARKit
import Toast_Swift

extension AceARViewController : ClickableObjectDelegate {
    
    func initObjectDetection() {
        self.objectGroupName = "VariousPrinters"
    }
    
    func searchForObjects() {
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: self.objectGroupName, bundle: nil) {
            self.view.makeToast("Starting search for \(self.objectGroupName!)...", position: .center)
            self.configuration.detectionObjects = referenceObjects
            arView.session.run(self.configuration)
        }
        else {
            self.showMessage(title:"Assets Missing", message: "Missing expected asset catalog: \(String(describing: self.objectGroupName))")
        }
    }
    
    func objectAnnotation(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
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
        //self.performSegue(withIdentifier: "showVideoPlayer", sender: self)
        let vc = AVPlayerViewController.instantiate(fromAppStoryboard: .Main)
        vc.url = self.videoURLs[self.videoTag]
        self.navigationController?.pushViewController(vc)
        
        
    }

    func loadInteralAssets() {
        self.clickableImages = [UIImage(named: "PrinterThumb1")!, UIImage(named: "PrinterThumb2")!, UIImage(named: "PrinterThumb3")!]
        self.imagePositions = [SCNVector3(x: -0.2, y: +0.4, z: +0.05), SCNVector3(x: +0.1, y: +0.4, z: +0.05), SCNVector3(x: -0.2, y: +0.1, z: +0.05)]
        self.videoURLs = [
            URL(fileURLWithPath: Bundle.main.path(forResource: "clip1", ofType: "mp4")!),
            URL(fileURLWithPath: Bundle.main.path(forResource: "clip2", ofType: "mp4")!),
            URL(fileURLWithPath: Bundle.main.path(forResource: "clip3", ofType: "mp4")!)
        ]
    }
}
