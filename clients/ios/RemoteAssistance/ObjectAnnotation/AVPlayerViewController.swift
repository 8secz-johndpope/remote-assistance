//
//  AVPlayerViewController.swift
//  RemoteAssistance
//
//  Created by Gerry Filby on 1/8/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class AVPlayerViewController: UIViewController {
    
    var url:URL!
    var asset:AVAsset!
    var playerItem:AVPlayerItem!
    var player:AVPlayer!
    var playerLayer:AVPlayerLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Play Video"
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(AVPlayerViewController.dismissView))
        self.navigationItem.rightBarButtonItems = [doneBarButton]
        // Do any additional setup after loading the view.
        self.playVideo()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(AVPlayerViewController.orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.endVideo()
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func orientationChanged() {
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        } else {
            print("Portrait")
        }
        self.playerLayer.frame = self.view.bounds //bounds of the view in which AVPlayer should be displayed
    }
    
    @objc func dismissView() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func endVideo() {
        self.player.pause()
        self.playerLayer.removeFromSuperlayer()
    }
    
    func playVideo() {
        self.asset = AVAsset(url: self.url)
        self.playerItem = AVPlayerItem(asset: self.asset)
        self.player = AVPlayer(playerItem: self.playerItem)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer.frame = self.view.bounds //bounds of the view in which AVPlayer should be displayed
        self.playerLayer.videoGravity = .resizeAspect
        self.view.layer.addSublayer(playerLayer)
        self.player.play()
    }
}
