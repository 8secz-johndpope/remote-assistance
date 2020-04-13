//
//  AceNavigationController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 4/9/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit

class AceNavigationController : UINavigationController {
    
    override var shouldAutorotate : Bool{
        if let selectedVC = self.topViewController {
            if selectedVC.responds(to: #selector(getter: self.shouldAutorotate)) {
                return selectedVC.shouldAutorotate
            }
        }
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
         if let selectedVC = self.topViewController {
             if selectedVC.responds(to: #selector(getter: self.supportedInterfaceOrientations)) {
                return selectedVC.supportedInterfaceOrientations
            }
        }
        return .all
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
         if let selectedVC = self.topViewController {
             if selectedVC.responds(to: #selector(getter: self.preferredStatusBarStyle)) {
                return selectedVC.preferredStatusBarStyle
            }
        }
        return .lightContent
    }

}
