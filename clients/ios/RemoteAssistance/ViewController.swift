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
  
        // uncomment to show the unified view ace view controller
        let vc = AceLandingViewController.instantiate(fromAppStoryboard: .Ace)
        let navVC = UINavigationController()
        navVC.tabBarItem = vc.tabBarItem
        navVC.pushViewController(vc)
        self.viewControllers?.prepend(navVC)
        
        let up = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeUp))
        up.direction = .up
        self.view.addGestureRecognizer(up)

        let down = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeDown))
        down.direction = .down
        self.view.addGestureRecognizer(down)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // hide the bar for now
        self.changeTabBar(hidden:true, animated:true)
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
