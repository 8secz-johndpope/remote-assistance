//
//  ViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 10/29/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import UIKit

class ViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent Auto-Lock
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Prevent Screen Dimming
        let currentScreenBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = currentScreenBrightness
  
        do {
            // uncomment to show the unified view ace view controller
            let vc = AceLandingViewController.instantiate(fromAppStoryboard: .Ace)
            let navVC = AceNavigationController()
            navVC.tabBarItem = vc.tabBarItem
            navVC.pushViewController(vc)
            self.viewControllers?.prepend(navVC)
        }
        
        do {
            // add digital companion
            let vc = AceDCLandingViewController.instantiate(fromAppStoryboard: .Ace)
            let navVC = AceNavigationController()
            navVC.tabBarItem = vc.tabBarItem
            navVC.pushViewController(vc)
            self.viewControllers?.prepend(navVC)
        }
        
        do {
            // add digital companion
            let vc = AceRCProjectViewController.instantiate(fromAppStoryboard: .Ace)
            let navVC = AceNavigationController()
            navVC.tabBarItem = vc.tabBarItem
            navVC.pushViewController(vc)
            // add to the end
            self.viewControllers?.append(navVC)
        }
        
        self.selectedIndex = 0

        let up = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeUp))
        up.direction = .up
        up.numberOfTouchesRequired = 2
        self.view.addGestureRecognizer(up)

        let down = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeDown))
        down.direction = .down
        down.numberOfTouchesRequired = 2
        self.view.addGestureRecognizer(down)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // hide the bar for now
        self.changeTabBar(hidden:true, animated:true)
    }
        
    override var shouldAutorotate : Bool{
        if let selectedVC = self.selectedViewController {
            if selectedVC.responds(to: #selector(getter: self.shouldAutorotate)) {
                return selectedVC.shouldAutorotate
            }
        }
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
         if let selectedVC = self.selectedViewController {
             if selectedVC.responds(to: #selector(getter: self.supportedInterfaceOrientations)) {
                return selectedVC.supportedInterfaceOrientations
            }
        }
        return .all
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
         if let selectedVC = self.selectedViewController {
             if selectedVC.responds(to: #selector(getter: self.preferredStatusBarStyle)) {
                return selectedVC.preferredStatusBarStyle
            }
        }
        return .lightContent
    }
    
    func changeTabBar(hidden:Bool, animated: Bool){
        // remove animation.  causes bad layout issues
        self.tabBar.isHidden = hidden
    }
    
    @objc func onSwipeUp(recognizer: UITapGestureRecognizer) {
        changeTabBar(hidden:false, animated:true)
    }

    @objc func onSwipeDown(recognizer: UITapGestureRecognizer) {
        changeTabBar(hidden:true, animated:true)
    }
}
