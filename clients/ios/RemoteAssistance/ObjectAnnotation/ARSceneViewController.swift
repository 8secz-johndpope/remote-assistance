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
import Alamofire

class ARSceneViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let api = AceAPI.sharedInstance
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
    var nodeFound:SCNNode?
    var recordingUuid:String?
    var clipThumbnailReady = false
    var clipReady = false
    var liveAnnotation = true
    var recordingUrl:URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Search Scene"
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.delegate = self
        // TODO: This should be pulled from previous activity in other sections of the app
        self.objectGroupName = "VariousPrinters"
        self.imageGroupName = "AR Resources"
        self.initSocket()
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
                if self.liveAnnotation {
                    self.showVideo(tag: -1)
                }
                else {
                    if let tag = self.clickableImages.firstIndex(of: obj) {
                        self.showVideo(tag: tag)
                    }
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
                self.showToast(message: "Found image anchor: \(String(describing: node.name))")
                DispatchQueue.main.async {
                    self.nodeFound = node
                    if !self.liveAnnotation {
                        for i in 0..<self.clickableImages.count {
                            let material = SCNMaterial()
                            material.diffuse.contents = self.clickableImages[i]
                            let clickableNode = self.buildNode(material: material, scnVector3: self.imagePositions[i])
                            node.addChildNode(clickableNode)
                        }
                    }
                }
            }
            
            if let _ = anchor as? ARObjectAnchor {
                self.anchorFound = true
                print("ObjectAnnotation found objectAnchor!")
                self.showToast(message: "Found object anchor: \(String(describing: node.name))")
                DispatchQueue.main.async {
                    self.nodeFound = node
                    if !self.liveAnnotation {
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
    
    func showToast(message:String) {
        DispatchQueue.main.async {
            self.view.makeToast(message)
        }
    }
    
    func showVideo(tag:Int) {
                
        if tag == -1 {
            if let url = self.recordingUrl {
                let player = AVPlayer(url: url)
                let playerViewController = AVKit.AVPlayerViewController()
                playerViewController.player = player
                self.navigationController?.pushViewController(playerViewController)
            }
        }
        else {
            let videoURL = self.videoURLs[tag]
            let player = AVPlayer(url: videoURL)
            let playerViewController = AVKit.AVPlayerViewController()
            playerViewController.player = player
            self.navigationController?.pushViewController(playerViewController)
        }
    }
    
    func loadInteralAssets() {
        self.clickableImages = [UIImage(named: "PrinterThumb1")!, UIImage(named: "PrinterThumb2")!, UIImage(named: "PrinterThumb3")!]
        self.imagePositions = [SCNVector3(x: -0.2, y: +0.4, z: +0.05), SCNVector3(x: +0.1, y: +0.4, z: +0.05), SCNVector3(x: -0.2, y: +0.1, z: +0.05)]
        self.videoURLs = [URL(fileURLWithPath: Bundle.main.path(forResource: "clip1", ofType: "mp4")!), URL(fileURLWithPath: Bundle.main.path(forResource: "clip2", ofType: "mp4")!), URL(fileURLWithPath: Bundle.main.path(forResource: "clip3", ofType: "mp4")!)]
    }
    
    func initSocket() {
        let socket = SocketIOManager.sharedInstance
        socket.on("recording_started") { data, ack in
            self.showToast(message: "recording_started")
            if let object = data[0] as? [String:Any], let uuid = object["clip_uuid"] as? String {
                self.recordingUuid = uuid
                self.annotateObjectWithRecordingPlaceholder()
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
    
    func annotateObjectWithRecordingPlaceholder() {
        if let node = self.nodeFound {
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "PrinterThumb1")!
            let placeholderNode = self.buildNode(material: material, scnVector3: SCNVector3(x: 0.0, y: 0.0, z: 0.0))
            node.addChildNode(placeholderNode)
        }
    }
    
    func tryAnnotateObjectWithRecording() {
        if self.clipThumbnailReady && self.clipReady {
            if let recUuid = self.recordingUuid, let node = self.nodeFound {
                self.api.getClip(recUuid) { result, error in
                    if let err = error {
                        self.showToast(message: "getClip exception: \(err)")
                        return
                    }
                    if let res = result {
                        let thumb_url_string = store.ace.state.serverUrl + res.thumbnail_url!
                        let mp4_url = store.ace.state.serverUrl + res.mp4_url!
                        print(thumb_url_string)
                        print(mp4_url)
                        self.recordingUrl = URL(string: mp4_url)
                        let recordingThumbnail = self.getImageFromStor(url: thumb_url_string)
                        node.enumerateChildNodes { (nd, stop) in
                            nd.removeFromParentNode()
                        }
                        let material = SCNMaterial()
                        material.diffuse.contents = recordingThumbnail
                        let thumbnailNode = self.buildNode(material: material, scnVector3: SCNVector3(x: 0.0, y: 0.0, z: 0.0))
                        node.addChildNode(thumbnailNode)
                    }
                }
            }
        }
    }
    
    func getImageFromStor(url:String) -> UIImage? {
        var image:UIImage?
        AF.request(url).responseData { (response) in
            if response.error == nil {
                print(response.result)
                if let data = response.data {
                    image = UIImage(data: data)
                }
            }
            else {
                print(response.error ?? "getImageFromStor Error")
            }
        }
        return image
    }
}
