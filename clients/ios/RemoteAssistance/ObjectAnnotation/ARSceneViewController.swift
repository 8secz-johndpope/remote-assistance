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
    var remoteReferenceObject:ARReferenceObject?
    
    // Yulius - this is my mode switch
    var liveAnnotation = true
    
    var recordingUrl:URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Search Scene"
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.delegate = self
        self.configuration.automaticImageScaleEstimationEnabled = true
        // TODO: This should be pulled from previous activity in other sections of the app
        self.objectGroupName = "VariousPrinters"
        self.imageGroupName = "AR Resources"
        self.initSocket()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.searchForObjects()

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.view.addGestureRecognizer(tap)
        // TODO: Optionally load assets from API
//        self.loadInteralAssets()
        self.loadAnchorFromServer(anchorUuid: "demo_image_1")
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
                    self.nodeFound = node
                    if !self.liveAnnotation {
                        for i in 0..<self.clickableImages.count {
                            let material = SCNMaterial()
                            material.diffuse.contents = self.clickableImages[i]
                            let clickableNode = self.buildNode(material: material, scnVector3: self.imagePositions[i], nodeQuat: node.orientation)
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
    
    func buildNode(material: SCNMaterial, scnVector3: SCNVector3, nodeQuat:SCNQuaternion) -> SCNNode {
        let node = self.buildNode(material: material, scnVector3: scnVector3)
        let orientationNode = SCNNode()
        orientationNode.orientation = SCNVector4(x: -nodeQuat.x, y: -nodeQuat.y, z:-nodeQuat.z, w: nodeQuat.w)
        orientationNode.addChildNode(node)
        return orientationNode
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
        socket.connect()
    }
    
    func annotateObjectWithRecordingPlaceholder() {
        if let node = self.nodeFound {
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "Standby")!
            let placeholderNode = self.buildNode(material: material, scnVector3: SCNVector3(x: 0.0, y: 0.0, z: 0.0), nodeQuat: node.orientation)
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
                    if let clip = result {
                        let thumb_url_string = store.ace.state.serverUrl + clip.thumbnail_url!
                        let mp4_url = store.ace.state.serverUrl + clip.mp4_url!
                        print(thumb_url_string)
                        print(mp4_url)
                        self.recordingUrl = URL(string: mp4_url)
                        AF.request(thumb_url_string).responseData { (response) in
                            if response.error == nil {
                                print(response.result)
                                if let data = response.data {
                                    let recordingThumbnail = UIImage(data: data)
                                    node.enumerateChildNodes { (nd, stop) in
                                        nd.removeFromParentNode()
                                    }
                                    let material = SCNMaterial()
                                    material.diffuse.contents = recordingThumbnail
                                    let thumbnailNode = self.buildNode(material: material, scnVector3: SCNVector3(x: 0.0, y: 0.0, z: 0.0), nodeQuat: node.orientation)
                                    node.addChildNode(thumbnailNode)
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
    
    func searchForAndLoadAnchors(searchText:String) {
        self.api.getAllAnchors(searchText) { result, error in
            if let err = error {
                self.showToast(message: "getAllAnchors exception: \(err)")
                print("getAllAnchors exception: \(err)")
                return
            }
            if let anchors = result {
                
            }
        }
    }
    
    func loadAnchorFromServer(anchorUuid:String) {
        self.api.getAnchor(anchorUuid) { result, error in
            if let err = error {
                self.showToast(message: "getAnchor exception: \(err)")
                print("getAnchor exception: \(err)")
                return
            }
            if let anchor = result {
                let fileManager = FileManager.default
                do {
                    let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                    let remoteUrlString = store.ace.state.serverUrl + "/" + anchor.url
                    let remoteUrl = URL(string: remoteUrlString)
                    let fileName = remoteUrl?.lastPathComponent
                    let fileURL = documentDirectory.appendingPathComponent(fileName!)
                    AF.request(remoteUrlString).responseData { (response) in
                        if response.error == nil {
                            print(response.result)
                            if let data = response.data {
                                do {
                                    if anchor.type == AceAPI.Anchor.AnchorType.object {
                                        try data.write(to: fileURL)
                                        if (anchor.type == AceAPI.Anchor.AnchorType.object) {
                                            var referenceObject:ARReferenceObject?
                                            try referenceObject = ARReferenceObject.init(archiveURL: fileURL)
                                            if let refObj = referenceObject {
                                                let refObjs:Set = [refObj]
                                                self.searchForObjects(arReferenceObjects: refObjs, arReferenceImages: nil)
                                            }
                                        }
                                    }
                                    else if anchor.type == AceAPI.Anchor.AnchorType.image {
                                        let uiImage = UIImage(data: data)
                                        let ciImage = CIImage(image: uiImage!)
                                        let context = CIContext(options: nil)
                                        let cgImage = context.createCGImage(ciImage!, from: ciImage!.extent)
                                        let referenceImage:ARReferenceImage = ARReferenceImage.init(cgImage!, orientation: CGImagePropertyOrientation.up, physicalWidth:1.0)
                                        referenceImage.name = anchorUuid
                                        let refImgs:Set = [referenceImage]
                                        self.searchForObjects(arReferenceObjects: nil, arReferenceImages: refImgs)
                                    }
                                }
                                catch {
                                    print(error)
                                }
                            }
                        }
                        else {
                            self.showMessage(title: "Get arobject Error", message: "\(String(describing: response.error))")
                            print(response.error ?? "Get arobject Error")
                        }
                    }
                }
                catch {
                    print(error)
                }
            }
        }
    }
}
