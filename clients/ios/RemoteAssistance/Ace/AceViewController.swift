//
//  AceViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/10/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import WebRTC

class AceViewController : UIViewController {
    
    var arVC: AceARViewController?
    var handsVC: AceHandsViewController?
    var uiVC: AceUIViewController?
    var sketchVC: AceSketchViewController?
    
    var wrtc:WRTCClient = WRTCClient()
    var mode:String = "none"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        
        initSetMode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        self.view.makeToast("Joined room \(store.ace.state.roomName)", duration: 2.0, position: .center)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier) {
        case "arVC":
            if let vc = segue.destination as? AceARViewController {
                addChild(vc)
                vc.wrtc = self.wrtc
                arVC = vc
            }
            break
        case "handsVC":
            if let vc = segue.destination as? AceHandsViewController {
                addChild(vc)
                handsVC = vc
            }
            break
        case "sketchVC":
            if let vc = segue.destination as? AceSketchViewController {
                addChild(vc)
                sketchVC = vc
            }
            break
        case "uiVC":
            if let vc = segue.destination as? AceUIViewController {
                addChild(vc)
                vc.wrtc = self.wrtc
                uiVC = vc
                uiVC?.delegate = self
            }
            break
        default:
            break
        }
    }
    
    func initSetMode() {
        let socket = SocketIOManager.sharedInstance
        socket.on("set_mode") { data, ack in
            if let object = data[0] as? [String:String],
                let mode = object["mode"] {
                self.setMode(mode)
            }
        }
    }
    
    func setMode(_ mode:String) {
        self.mode = mode
        print("set_mode: \(mode)")
        
        if (mode != "hands") {
            handsVC?.view.isHidden = true
        }
        
        if (mode != "sketch") {
            sketchVC?.view.isHidden = true
        }
        
//         if (mode != "pointer") {
//            arVC?.resetPointer()
//         }

//         if (mode != "screenar") {
//            arVC?.resetScreenAR()
//         }
                
        switch (self.mode) {
            case "hands":
                handsVC?.view.isHidden = false
                break
            case "sketch":
                arVC?.searchForObjects()
                sketchVC?.view.isHidden = false
                break
            case "pointer":
                arVC?.enablePointer()
                break
            case "screenar":
                arVC?.enableScreenAR()
                break
            default:
                break
        }
    }

}

extension AceViewController : AceUIViewDelegate {
    func onResetScreenAR(_ btn: UIButton) {
        arVC?.onResetScreenAR(btn)
    }
    
    func onSettings(_ btn:UIButton) {
        // uncomment to show the unified view ace view controller
        let vc = SettingsViewController.instantiate(fromAppStoryboard: .Main)
        self.navigationController?.pushViewController(vc)
    }
    
    func onToggleVR(_ btn: UIButton) {
        arVC?.onToggleVR(btn)
    }
    
    func onHangup(_ btn: UIButton) {
        self.wrtc.disconnect()
        self.navigationController?.popViewController()
    }

    func onObjectDetect(_ btn: UIButton) {
        //arVC?.searchForObjects()
    }
}

extension AceViewController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
