//
//  TSViewController.swift
//  teleskele
//
//  Created by Yulius Tjahjadi on 9/27/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import UIKit
import WebRTC
import CoreMotion
import SceneKit

class AceHandsViewController: UIViewController {

    @IBOutlet var handView: SCNView!
    var motionManager = CMMotionManager()
    var remoteHands:TSRemoteHands!
    var lastTimeStamp:TimeInterval = 0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        initRemoteHands()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initGyro()
        self.remoteHands.connect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopGyroUpdates()
        self.remoteHands.disconnect()
    }
        
    func initGyro() {
        motionManager.deviceMotionUpdateInterval = 0.016
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (gyroData, error) in
            if let data = gyroData {
                let absolute = true
                let alpha = -data.attitude.yaw * 180 / Double.pi
                let beta = -data.attitude.pitch * 180 / Double.pi
                let gamma = -data.attitude.roll * 180 / Double.pi

                let socket = SocketIOManager.sharedInstance
                socket.emit("gyro", [
                    "msg": "from customer",
                    "alpha": alpha,
                    "beta": beta,
                    "gamma": gamma,
                    "absolute": absolute
                ])
            }
        }
    }
        
    func initRemoteHands() {
        let scene = SCNScene()
        self.handView.scene = scene
        self.remoteHands = TSRemoteHands(scene)
    }
}
