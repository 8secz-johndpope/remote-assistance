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
import AVFoundation
import Alamofire

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
        self.imageGroupName = "AR Resources"
        self.liveAnnotation = false
        self.initSocket()
    }
    
    func initSocket() {
        let socket = SocketIOManager.sharedInstance
        socket.on("recording_started") { data, ack in
            if let object = data[0] as? [String:Any], let uuid = object["clip_uuid"] as? String {
                self.recordingUuid = uuid
                self.annotateObjectWithRecordingPlaceholder()
                self.showToast(message: "recording_started: \(self.recordingUuid ?? "unknown")")
            }
            else {
                self.showMessage(title: "recording_started", message: "data was null")
            }
        }
        socket.on("clip_ready") { data, ack in
            self.showToast(message: "clip_ready")
            self.clipReady = true
            self.tryAnnotateObjectWithRecording()
        }
        socket.on("clip_thumbnail_ready") { data, ack in
            self.showToast(message: "clip_thumbnail_ready")
            self.clipThumbnailReady = true
            self.tryAnnotateObjectWithRecording()
        }
    }

    
    func objectAnnotationViewWillAppear() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tap.delegate = self.parent as? UIGestureRecognizerDelegate
        self.objectTap = tap
        self.parent?.view.addGestureRecognizer(tap)
        // Postponing this until we have the detected object/image name - we will determine which assets to load depending
//        self.loadInteralAssets()
    }
    
    func objectAnnotationViewWillDisappear() {
        if let tap = self.objectTap {
            self.parent?.view.removeGestureRecognizer(tap)
        }
        self.anchorFound = false
    }
    
    @objc func searchForObjects() {
        self.arView.session.pause()
        self.view.makeToast("Starting search for \(self.objectGroupName!)...", position: .bottom)
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
            let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors, .stopTrackedRaycasts]
            // remove all objects before reset
            // prevent double free when using .removeExistingAnchors
//            self.arView.scene.rootNode.enumerateChildNodes { (node, stop) in
//                node.removeFromParentNode()
//            }
            clipNode = [String:ObjectAnnotationNode]()
            arView.session.run(self.configuration, options: options)
        }
    }
    
    @objc func pauseSession() {
        self.arView.session.pause()
    }

    func objectAnnotation(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        self.renderer = renderer
                
        if !self.anchorFound {
            if let _ = anchor as? ARImageAnchor {
                
                // image anhors need to be named "object_XXX"
                if anchor.name?.hasPrefix("object") == false {
                    return
                }

                self.anchorFound = true
                print("ObjectAnnotation found imageAnchor!")
                self.loadInteralAssets(detectedName: anchor.name ?? "Unknown")
                DispatchQueue.main.async {
                    self.view.makeToast("Found image anchor \(anchor.name ?? "Unknown")", position: .center)
                    let orientationNode = SCNNode()
                    orientationNode.eulerAngles = SCNVector3(x:-Float.pi/2, y:0, z:0)
                    node.addChildNode(orientationNode)
                    self.nodeFound = orientationNode

                    self.addPointer(node)
                    if !self.liveAnnotation {
                        for i in 0..<self.clickableImages.count {
                            let material = SCNMaterial()
                            material.diffuse.contents = self.createThumbnail(self.clickableImages[i])
                            let url = self.videoURLs[i]
                            let clickableNode = self.buildNode(material: material, scnVector3: self.imagePositions[i], url: url)
                            self.nodeFound?.addChildNode(clickableNode)
                        }
                    }
                }
            }
            
            if let _ = anchor as? ARObjectAnchor {
                self.anchorFound = true
                print("ObjectAnnotation found objectAnchor!")
                self.loadInteralAssets(detectedName: anchor.name ?? "Unknown")
                DispatchQueue.main.async {
                    self.view.makeToast("Found object anchor \(anchor.name ?? "Unknown")", position: .center)
                    self.nodeFound = node
                    self.addPointer(node)
                    if !self.liveAnnotation {
                        for i in 0..<self.clickableImages.count {
                            let material = SCNMaterial()
                            material.diffuse.contents = self.createThumbnail(self.clickableImages[i])
                            let url = self.videoURLs[i]
                            let clickableNode = self.buildNode(material: material, scnVector3: self.imagePositions[i], url: url)
                            node.addChildNode(clickableNode)
                        }
                    }
                }
            }
        }
    }
    
    func createThumbnail(_ image:UIImage) -> UIImage {
        let imgView = AceClipThumbnail(image:image)
        imgView.frame = CGRect(x:0, y:0, width: 800, height:800)
        return imgView.asImage()
    }
    
    func buildNode(material: SCNMaterial, scnVector3: SCNVector3, url:URL?) -> ObjectAnnotationNode {
        let node = ObjectAnnotationNode(geometry: SCNPlane(width: 0.2, height: 0.2))
        node.url = url
        node.geometry?.firstMaterial = material
        node.position = scnVector3
        node.opacity = 1
        node.constraints = [SCNBillboardConstraint()]
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
        // show modal instead of nav controller for fullscreen view
        self.present(playerViewController, animated: true, completion: nil)
//        self.navigationController?.setNavigationBarHidden(false, animated: true)
//        self.navigationController?.pushViewController(playerViewController)
    }


    func loadInteralAssets(detectedName: String) {
        
        switch detectedName.uppercased() {
        case "FAKEPRINTER":
            self.clickableImages = [UIImage(named: "PrinterThumb1")!, UIImage(named: "PrinterThumb2")!, UIImage(named: "PrinterThumb3")!]
            self.imagePositions = [SCNVector3(x: -0.2, y: +0.4, z: +0.05), SCNVector3(x: +0.1, y: +0.4, z: +0.05), SCNVector3(x: -0.2, y: +0.1, z: +0.05)]
            self.videoURLs = [
                URL(string:"\(store.ace.state.serverUrl)/static/clipStor/demo1.mp4")!,
                URL(string:"\(store.ace.state.serverUrl)/static/clipStor/demo2.mp4")!,
                URL(string:"\(store.ace.state.serverUrl)/static/clipStor/demo3.mp4")!,
            ]
        case "3DPRINTER":
            self.clickableImages = [UIImage(named: "3DPrinterThumb1")!, UIImage(named: "3DPrinterThumb2")!, UIImage(named: "3DPrinterThumb3")!]
            self.imagePositions = [SCNVector3(x: -0.2, y: +0.4, z: +0.05), SCNVector3(x: +0.1, y: +0.4, z: +0.05), SCNVector3(x: -0.2, y: +0.1, z: +0.05)]
            self.videoURLs = [
                URL(fileURLWithPath: Bundle.main.path(forResource: "3DPrinter1", ofType: "mp4")!),
                URL(fileURLWithPath: Bundle.main.path(forResource: "3DPrinter2", ofType: "mp4")!),
                URL(fileURLWithPath: Bundle.main.path(forResource: "3DPrinter3", ofType: "mp4")!)
            ]
        default:
            print("we don't have assets for \(detectedName)")
        }
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
    
    func annotateObjectWithRecordingPlaceholder() {
        if let node = self.nodeFound {
            let material = SCNMaterial()
            material.diffuse.contents = self.createThumbnail(UIImage(named: "Standby")!)
            let placeholderNode = self.buildNode(material: material, scnVector3: SCNVector3(x:+0.1, y: +0.1, z: +0.05), url: nil)
            self.clipNode[self.recordingUuid ?? "none"] = placeholderNode
            node.addChildNode(placeholderNode)
        }
    }
    
    func tryAnnotateObjectWithRecording() {
        if self.clipThumbnailReady && self.clipReady {
            if let recUuid = self.recordingUuid, let node = self.nodeFound {
                let api = AceAPI.sharedInstance
                api.getClip(recUuid) { result, error in
                    if let err = error {
                        self.showToast(message: "getClip exception: \(err)")
                        return
                    }
                    if let res = result {
                        let thumb_url_string = "\(store.ace.state.serverUrl)/\(res.thumbnail_url!)"
                        let mp4_url = "\(store.ace.state.serverUrl)/\(res.mp4_url!)"
                        print(thumb_url_string)
                        print(mp4_url)
                        self.recordingUrl = URL(string: mp4_url)
                        AF.request(thumb_url_string).responseData { (response) in
                            if response.error == nil {
                                print(response.result)
                                if let data = response.data,
                                    let recordingThumbnail = UIImage(data: data)  {
//                                    node.enumerateChildNodes { (nd, stop) in
//                                        nd.removeFromParentNode()
//                                    }
                                    
                                    if let placeholderNode = self.clipNode[self.recordingUuid ?? "none"] {
                                        placeholderNode.url = self.recordingUrl
                                        placeholderNode.geometry?.firstMaterial?.diffuse.contents = self.createThumbnail(recordingThumbnail)
                                    }
//                                    let material = SCNMaterial()
//                                    material.diffuse.contents = self.createThumbnail(recordingThumbnail!)
//                                    let thumbnailNode = self.buildNode(material: material, scnVector3: SCNVector3(x:+0.1, y: +0.1, z: +0.05), url: self.recordingUrl)
//                                    node.addChildNode(thumbnailNode)
                                } else {
                                    self.showMessage(title: "Get Thumbnail Error", message: "Invalid thumbnail data")
                                }
                            }
                            else {
                                self.showMessage(title: "Get Thumbnail Error", message: "\(String(describing: response.error))")
                                print(response.error ?? "getImageFromStor Error")
                            }
                        }
                    }
                }
            }
            else {
                self.showMessage(title: "tryAnnotateObjectWithRecording", message: "Either clip_uuid or discovered node was null")
            }
        }
    }
    
    func showToast(message:String) {
        DispatchQueue.main.async {
            self.view.makeToast(message)
        }
    }
    
    func addPointer(_ node:SCNNode) {
        let pointerNode = SCNNode(geometry: SCNPlane(width: 0.05, height: 0.05))
        pointerNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ObjectPointer")
        pointerNode.position = SCNVector3(0, 0, 0)
        pointerNode.constraints = [SCNBillboardConstraint()]
        node.addChildNode(pointerNode)
    }
}
