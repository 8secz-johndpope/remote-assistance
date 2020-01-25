//
//  AceLandingViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/22/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit

class AceLandingViewController : UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @IBAction func onChatBtn(_ sender: Any) {
        let vc  = ChatViewController.instantiate(fromAppStoryboard: .Main)
        self.navigationController?.pushViewController(vc)
    }
    
    @IBAction func onQRCodeBtn(_ sender: Any) {
        let vc  = QRCodeSCanner()
        vc.delegate = self
        self.navigationController?.pushViewController(vc)
    }
    @IBAction func onARBtn(_ sender: Any) {
        let vc  = AceViewController.instantiate(fromAppStoryboard: .Ace)
        self.navigationController?.pushViewController(vc)
    }
    @IBAction func onSettingsBtn(_ sender: Any) {
        let vc  = SettingsViewController.instantiate(fromAppStoryboard: .Main)
        self.navigationController?.pushViewController(vc)
    }
}

extension AceLandingViewController : QRCodeScannerDelegate {
   
    func qrCodeScannerResponse(code: String) {
        if  code.hasPrefix("http"),
            let url = URL(string: code) {
            let domain = url.host
            let port = url.port
            
            self.navigationController?.popViewController()
            
            if let domain = domain {
                var portStr = ""
                if let port = port {
                    portStr = ":\(String(port))"
                }
                let action = AceAction.SetServerURL(serverUrl: "https://\(domain)\(portStr)")
                store.ace.dispatch(action)
                
                let vc  = AceViewController.instantiate(fromAppStoryboard: .Ace)
                self.navigationController?.pushViewController(vc)
            }
        } else {
            let objectName = code
            
            AceAPI.sharedInstance.createRoom() { result, error in
                guard let roomId = result?.uuid else {
                    print("API Error: createRoom failed: \(error)")
                    return
                }
                
                let action = AceAction.SetRoomName(roomName: "\(objectName)-\(roomId)")
                store.ace.dispatch(action)

                let vc  = AceViewController.instantiate(fromAppStoryboard: .Ace)
                self.navigationController?.pushViewController(vc)
            }
            
        }
    }

}
