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
    weak var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topView.isHidden = true
        bottomView.isHidden = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.view.addGestureRecognizer(tap)

        
    }

    @IBAction func onHangupClick(_ sender: Any) {
        self.navigationController?.popViewController()
    }

    @IBAction func onMuteMic(_ sender: Any) {
    }

    @IBAction func onMenu(_ sender: Any) {
    }

    @objc func onTap(recognizer: UITapGestureRecognizer) {
        showUI(true)
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(onHide(_:)), userInfo: nil, repeats: false)
    }
    
    func showUI(_ show:Bool) {
        topView.isHidden = !show
        bottomView.isHidden = !show
    }
    
    @objc func onHide(_ timer: Timer) {
        showUI(false)
    }
}
