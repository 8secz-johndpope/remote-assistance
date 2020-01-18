//
//  AceUIViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/10/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit

class AceUIViewController : UIViewController {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    
    weak var timer: Timer?
    weak var wrtc:WRTCClient?
    var delegate:AceUIViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topView.isHidden = true
        bottomView.isHidden = true
        menuView.isHidden = true
        menuView.backgroundColor = UIColor(hexString:"#fff", transparency: 0.8)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.view.addGestureRecognizer(tap)

        infoLabel.text = "url: \(store.ts.state.serverUrl)\nroom: \(store.ts.state.roomName)"
        
    }

    func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(onHide(_:)), userInfo: nil, repeats: false)
    }
    
    func showUI(_ show:Bool) {
        if self.topView.isHidden == !show {
            return
        }

        self.topView.alpha = !show ? 1.0 : 0
        self.bottomView.alpha = !show ? 1.0 : 0
        self.topView.isHidden = false
        self.bottomView.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            self.topView.alpha = show ? 1.0 : 0
            self.bottomView.alpha = show ? 1.0 : 0
        }, completion: { finished in
            self.topView.isHidden = !show
            self.bottomView.isHidden = !show
        })
        resetTimer()
    }
    
    func showMenu(_ show:Bool) {
        if self.menuView.isHidden == !show {
            return
        }
        
        self.menuView.alpha = !show ? 1.0 : 0
        self.menuView.isHidden = false
        self.menuView.transform = CGAffineTransform(a:1, b:0, c:0, d:1, tx:0, ty: show ? 50 : 0)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.menuView.alpha = show ? 1.0 : 0
            self.menuView.transform = CGAffineTransform(a:1, b:0, c:0, d:1, tx:0, ty: show ? 0 : 50)
        }, completion: { finished in
            self.menuView.isHidden = !show
        })
        resetTimer()

    }
    
    // callbacks
    @IBAction func onHangupClick(_ sender: Any) {
        self.navigationController?.popViewController()
    }

    @objc func onTap(recognizer: UITapGestureRecognizer) {
        showUI(true)
        resetTimer()
    }
    
    @objc func onHide(_ timer: Timer) {
        showUI(false)
    }
    
    @IBAction func onMuteMic(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if (sender.isSelected) {
            // unmuted
            wrtc?.setAudioEnabled(false)
        } else {
            // mute
            wrtc?.setAudioEnabled(true)
        }
        
    }
    
    @IBAction func onToggleSpeaker(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if (sender.isSelected) {
            // headset
            wrtc?.enableSpeaker(false)
        } else {
            // use loud speakers
            wrtc?.enableSpeaker(true)
        }
        
    }
    
    @IBAction func onMenu(_ sender: UIButton) {
        showMenu(menuView.isHidden)
        resetTimer()
    }
    
    @IBAction func onResetScreenAR(_ sender:UIButton) {
        delegate?.onResetScreenAR(sender)
        onCloseMenu(sender)
        resetTimer()
    }

    @IBAction func onSettings(_ sender:UIButton) {
        delegate?.onSettings(sender)
        onCloseMenu(sender)
        resetTimer()
    }

    @IBAction func onCloseMenu(_ sender:UIButton) {
        showMenu(false)
        resetTimer()
    }
    
    @IBAction func onToggleVR(_ sender:UIButton) {
        delegate?.onToggleVR(sender)
    }

}

protocol AceUIViewDelegate {
    func onResetScreenAR(_ btn:UIButton)
    func onSettings(_ btn:UIButton)
    func onToggleVR(_ btn:UIButton)
}
