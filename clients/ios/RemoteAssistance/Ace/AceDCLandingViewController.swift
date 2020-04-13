//
//  AceDCLandingViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 4/9/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit

class AceDCLandingViewController : UIViewController {

    @IBOutlet weak var labelVersion: UILabel!
    @IBOutlet weak var btnChat: UIButton!
    
    override func viewDidLoad() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            labelVersion.text = "Version: \(version)"
        }

        btnChat.titleLabel?.numberOfLines = 2
        btnChat.imageView?.contentMode = .scaleAspectFit
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @IBAction func onClickChat(_ sender: UIButton) {
        let vc = ChatViewController.instantiate(fromAppStoryboard: .Main)
        self.navigationController?.pushViewController(vc)
    }
    
    @IBAction func onClickDevTools(_ sender: UIButton) {
        let vc = SettingsViewController.instantiate(fromAppStoryboard: .Main)
        self.navigationController?.pushViewController(vc)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }

    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
