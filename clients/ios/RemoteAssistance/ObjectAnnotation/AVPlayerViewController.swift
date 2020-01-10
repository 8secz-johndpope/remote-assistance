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

        // Do any additional setup after loading the view.
        self.playVideo()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(AVPlayerViewController.orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @IBAction func doneButtonTUI(_ sender: Any) {
        self.player.pause()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func orientationChanged() {
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        } else {
            print("Portrait")
        }
        self.playerLayer.frame = self.view.bounds //bounds of the view in which AVPlayer should be displayed
    }
    
    func playVideo() {
        let video = Bundle.main.path(forResource: "clip3", ofType: "mp4")
        self.url = URL(fileURLWithPath: video!)
        //self.url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")
        self.asset = AVAsset(url: url)
        self.playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: playerItem)
        self.playerLayer = AVPlayerLayer(player: player)
        self.playerLayer.frame = self.view.bounds //bounds of the view in which AVPlayer should be displayed
        self.playerLayer.videoGravity = .resizeAspect
        self.view.layer.addSublayer(playerLayer)
        self.player.play()
    }
}
