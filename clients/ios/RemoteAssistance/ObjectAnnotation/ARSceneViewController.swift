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


protocol ARSceneViewControllerDelegate: class
{
    func arSceneViewControllerResponse(text: String)
}

class ARSceneViewController: UIViewController, ARSCNViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var thumbNailCollectionView: UICollectionView!
    @IBOutlet weak var warningLabel: UILabel!
    
    let api = AceAPI.sharedInstance
    let configuration = ARWorldTrackingConfiguration()
    var objectGroupName:String!
    var imageGroupName:String!
    var clickableImages:[UIImage] = []
    var imagePositions:[SCNVector3] = []
    var videoURLs:[URL] = []
    var searchBarButton:UIBarButtonItem!
    var pauseBarButton:UIBarButtonItem!
    var renderer:SCNSceneRenderer?
    var anchorFound = false
    var nodeFound:SCNNode?
    var recordingUuid:String?
    var clipThumbnailReady = false
    var clipReady = false
    var remoteReferenceObject:ARReferenceObject?
    var clipNode = [String:ObjectAnnotationNode]()
    var clickableNodes:[ObjectAnnotationNode] = []
    var thumbNails:[UIImage] = []
    var stepInScene:Int = 0
    var lastVideoEnabled:Int = -1
    var nowPlayingVideo:Bool = false

    var recordingUrl:URL?

    weak var delegate: ARSceneViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Search Scene"
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.delegate = self
        self.configuration.automaticImageScaleEstimationEnabled = true
        self.objectGroupName = "VariousPrinters"
        self.imageGroupName = "AR Resources"
        self.thumbNailCollectionView.delegate = self
        self.thumbNailCollectionView.dataSource = self
        self.thumbNailCollectionView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.5)
        self.thumbNailCollectionView.isHidden = true
        self.warningLabel.text = ""
        
        self.initSocket()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.nowPlayingVideo {
            AppUtility.lockOrientation(.landscape, andRotateTo: .landscapeRight)
            self.searchForObjects()
        }
        else {
            self.nowPlayingVideo = false
        }
        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
//        self.view.addGestureRecognizer(tap)
        
//        if let _ = self.nodeFound {
//            self.prevButton.isHidden = false
//            self.nextButton.isHidden = false
//        }
//        else {
//            self.prevButton.isHidden = true
//            self.nextButton.isHidden = true
//        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !self.nowPlayingVideo {
            self.sceneView.session.pause()
            self.anchorFound = false
            self.delegate?.arSceneViewControllerResponse(text: "")
            
            let socket = SocketIOManager.sharedInstance
            socket.off("recording_started")
            socket.off("clip_ready")
            socket.off("clip_thumbnail_ready")
            
            AppUtility.lockOrientation(.all)
        }
        //        self.view.removeGestureRecognizers()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.clickableImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width * 0.75), height: (collectionView.frame.width * 0.5))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "thumbnailCell", for: indexPath as IndexPath)
        var image = self.clickableImages[indexPath.row]
        image = image.resize(toWidth: collectionView.frame.width * 0.75)!
        let imageView = UIImageView(image: image)
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.cornerRadius = 5
        if indexPath.row == self.lastVideoEnabled {
            imageView.layer.borderColor = UIColor.systemYellow.cgColor
        }
        else {
            imageView.layer.borderColor = UIColor.systemGray.cgColor
        }
        cell.addSubview(imageView)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row <= self.lastVideoEnabled {
            self.showVideo(tag: indexPath.row)
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
//            sceneView.session.delegate = self
            sceneView.session.run(self.configuration, options: options)
        }
    }
    
    @objc func pauseSession() {
        self.sceneView.session.pause()
    }
    
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        // Do something with the new transform
//        let currentTransform = frame.camera.transform
//        print(currentTransform)
//    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        self.renderer = renderer

        if !self.anchorFound {
            if let _ = anchor as? ARImageAnchor {
                self.anchorFound = true
                print("ObjectAnnotation found imageAnchor!")
                DispatchQueue.main.async {
                    self.loadInteralAssets(detectedName: anchor.name ?? "Unknown")
                    self.view.makeToast("Found image anchor \(anchor.name ?? "Unknown")", position: .bottom)
                    let orientationNode = SCNNode()
                    orientationNode.eulerAngles = SCNVector3(x:-Float.pi/2, y:0, z:0)
                    node.addChildNode(orientationNode)
                    self.nodeFound = node
                    
                    self.enableNextVideo()
                }
            }
            
            if let _ = anchor as? ARObjectAnchor {
                self.anchorFound = true
                print("ObjectAnnotation found objectAnchor!")
                DispatchQueue.main.async {
                    self.loadInteralAssets(detectedName: anchor.name ?? "Unknown")
                    self.view.makeToast("Found object anchor \(anchor.name ?? "Unknown")", position: .bottom)
                    self.nodeFound = node

                    self.enableNextVideo()
                }
            }
        }
    }
    
    func addFirstClickableNode() {
        self.nodeFound?.addChildNode(self.clickableNodes[self.stepInScene])
//        self.prevButton.isHidden = false
//        self.prevButton.backgroundColor = UIColor.systemGray4
//        self.nextButton.isHidden = false
//        self.nextButton.backgroundColor = UIColor.systemGray4
    }
    
    func createThumbnail(_ image:UIImage) -> UIImage {
        let imgView = AceClipThumbnail(image:image)
        imgView.frame = CGRect(x:0, y:0, width: 800, height:800)
        let img = imgView.asImage()
        self.thumbNails.append(img)
        return img
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
    
    func showToast(message:String) {
        DispatchQueue.main.async {
            self.view.makeToast(message)
        }
    }
    
    func showVideo(tag:Int) {
                
        let videoURL = self.videoURLs[tag]
        let player = AVPlayer(url: videoURL)
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        let playerViewController = AVKit.AVPlayerViewController()
        playerViewController.player = player
        // This flag gets reset in viewWillAppear as player is dismissed
        self.nowPlayingVideo = true
        self.navigationController?.pushViewController(playerViewController)
        self.enableNextVideo()
    }
    
    @objc func videoDidEnd() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        // TODO: This may be too restrictive - Scott suggests simply enabling next as video player is launched,
        // rather than forcing user to complete the video
//        self.enableNextVideo()
    }
    
    func enableNextVideo() {
        DispatchQueue.main.async {
            if self.lastVideoEnabled < (self.clickableImages.count - 1) {
                self.lastVideoEnabled += 1
                print("Enabling video # \(self.lastVideoEnabled) (zero based)")
                self.addPointer2(self.nodeFound!, position: self.imagePositions[self.lastVideoEnabled])
                let positionInCameraSpace = self.nodeFound!.convertPosition(self.nodeFound!.position, to: self.sceneView.pointOfView)
                print(positionInCameraSpace)
                // TODO: These positions and calculations need tuning for good visual performance
                if positionInCameraSpace.z < +0.05 {
                    self.warningLabel.text = "If the marker is not visible, back up or walk around the object"
                }
                else {
                    self.warningLabel.text = ""
                }
                self.thumbNailCollectionView.isHidden = false
                self.thumbNailCollectionView.reloadData()
            }
        }
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
        case "DOCUCOLORTONER":
            self.clickableImages = [UIImage(named: "3DPrinterThumb1")!, UIImage(named: "3DPrinterThumb2")!, UIImage(named: "3DPrinterThumb3")!]
            self.imagePositions = [SCNVector3(x: -0.2, y: +0.4, z: +0.05), SCNVector3(x: +0.1, y: +0.4, z: +0.05), SCNVector3(x: -0.2, y: +0.1, z: +0.05)]
            self.videoURLs = [
                URL(fileURLWithPath: Bundle.main.path(forResource: "3DPrinter1", ofType: "mp4")!),
                URL(fileURLWithPath: Bundle.main.path(forResource: "3DPrinter2", ofType: "mp4")!),
                URL(fileURLWithPath: Bundle.main.path(forResource: "3DPrinter3", ofType: "mp4")!)
            ]
        default:
            // The QR codes end up in this option
            self.clickableImages = [UIImage(named: "3DPrinterThumb1")!, UIImage(named: "3DPrinterThumb2")!, UIImage(named: "3DPrinterThumb3")!]
            self.imagePositions = [SCNVector3(x: -0.1, y: +0.1, z: +0.05), SCNVector3(x: +0.1, y: +0.1, z: +0.05), SCNVector3(x: -0.1, y: -0.1, z: +0.05)]
            self.videoURLs = [
                URL(fileURLWithPath: Bundle.main.path(forResource: "3DPrinter1", ofType: "mp4")!),
                URL(fileURLWithPath: Bundle.main.path(forResource: "3DPrinter2", ofType: "mp4")!),
                URL(fileURLWithPath: Bundle.main.path(forResource: "3DPrinter3", ofType: "mp4")!)
            ]
        }

        for i in 0..<self.clickableImages.count {
            let material = SCNMaterial()
            material.diffuse.contents = self.createThumbnail(self.clickableImages[i])
            let url = self.videoURLs[i]
            let clickableNode = self.buildNode(material: material, scnVector3: self.imagePositions[i], url: url)
            self.clickableNodes.append(clickableNode)
        }
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
    
    func addPointer2(_ node:SCNNode, position: SCNVector3) {
        let pointerNode = SCNNode(geometry: SCNPlane(width: 0.05, height: 0.05))
        pointerNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ObjectPointer")
        pointerNode.position = position
        pointerNode.constraints = [SCNBillboardConstraint()]
        node.addChildNode(pointerNode)
    }
    
    // MARK: - Likely deprecated functions
    
    func addPointer(_ node:SCNNode) {
        let pointerNode = SCNNode(geometry: SCNPlane(width: 0.05, height: 0.05))
        pointerNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ObjectPointer")
        pointerNode.position = SCNVector3(0, 0, 0)
        pointerNode.constraints = [SCNBillboardConstraint()]
        node.addChildNode(pointerNode)
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
            if let recUuid = self.recordingUuid, let _ = self.nodeFound {
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
                                        if let placeholderNode = self.clipNode[self.recordingUuid ?? "none"] {
                                            placeholderNode.url = self.recordingUrl
                                            placeholderNode.geometry?.firstMaterial?.diffuse.contents = self.createThumbnail(recordingThumbnail)
                                        }
                                }
                                else {
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
    
    func searchForAndLoadAnchors(searchText:String) {
        self.api.getAllAnchors(searchText) { result, error in
            if let err = error {
                self.showToast(message: "getAllAnchors exception: \(err)")
                print("getAllAnchors exception: \(err)")
                return
            }
//            if let anchors = result {
//                
//            }
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

    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        print("onTap from ARSceneViewController")

        let location = gesture.location(in: self.sceneView)

        let hitResults = self.renderer?.hitTest(location, options:nil)
        if let hit = hitResults?.first {
            let node = hit.node
            if let obj = node.geometry?.firstMaterial?.diffuse.contents as? UIImage {
                if let tag = self.thumbNails.firstIndex(of: obj) {
                    self.showVideo(tag: tag)
                }
            }
        }
    }

    @IBAction func prevButtonTUI(_ sender: Any) {
        if self.stepInScene > 0 {
            self.clickableNodes[self.stepInScene].removeFromParentNode()
            self.stepInScene -= 1
        }
    }
    
    @IBAction func nextButtonTUI(_ sender: Any) {
        if self.stepInScene < self.clickableNodes.count-1 {
            self.stepInScene += 1
            self.nodeFound?.addChildNode(self.clickableNodes[self.stepInScene])
        }
    }
}
