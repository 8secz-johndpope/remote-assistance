//
//  AceARViewController+ObjectAnnotation.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/22/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import ARKit
import AVKit
import Toast_Swift

class ObjectAnnotationNode : SCNNode {
    
    var url:URL?
    
    init(geometry: SCNGeometry?) {
        super.init()
        self.geometry = geometry
        self.categoryBitMask = 0x1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AceARViewController {
    
    func initObjectDetection() {
        self.objectGroupName = "VariousPrinters"
    }
    
    func objectAnnotationViewWillAppear() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tap.delegate = self.parent as? UIGestureRecognizerDelegate
        self.parent?.view.addGestureRecognizer(tap)
    }
    
    func objectAnnotationViewWillDisappear() {
        self.view.removeGestureRecognizers()
    }
    
    func searchForObjects() {
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: self.objectGroupName, bundle: nil) {
            self.view.makeToast("Starting search for \(self.objectGroupName!)...", position: .bottom)
            self.configuration.detectionObjects = referenceObjects
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
                self.view.makeToast("Found anchor \(anchor.name ?? "Unknown")", position: .center)

                for i in 0..<self.clickableImages.count {
                    let material = SCNMaterial()
                    material.diffuse.contents = self.clickableImages[i]
                    let clickableNode = self.buildNode(material: material, scnVector3: self.imagePositions[i], url:self.videoURLs[i])
                    node.addChildNode(clickableNode)
                }
            }
        }
    }
    
    func buildNode(material: SCNMaterial, scnVector3: SCNVector3, url:URL) -> SCNNode {
        let node = ObjectAnnotationNode(geometry: SCNBox(width: 0.3, height: 0.3, length: 0.001))
        node.url = url
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
        self.showVideo(url:videoURL)
    }
    
    func showVideo(url:URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVKit.AVPlayerViewController()
        playerViewController.player = player
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(playerViewController)
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
    
    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        print("onTap from AceARViewController+ObjectAnnotation")

        let location = gesture.location(in: self.arView)

        let options:[SCNHitTestOption:Any] = [.boundingBoxOnly: true, .categoryBitMask: 0x1]
        if let hitResults = self.renderer?.hitTest(location, options:options) {
            for hit in hitResults {
                if let node = hit.node as? ObjectAnnotationNode,
                    let url = node.url {
                    self.showVideo(url: url)
                } else {
                    print("didn't find ObjectAnnotationNode \(hit.node)")
                }
            }
        }
    }

}
