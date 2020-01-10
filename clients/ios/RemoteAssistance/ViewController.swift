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
  
        // uncomment to show the unified view ace view controller
//        let vc = AceViewController.instantiate(fromAppStoryboard: .Ace)
//        self.viewControllers?.prepend(vc)
        
        let up = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeUp))
        up.direction = .up
        self.view.addGestureRecognizer(up)

        let down = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeDown))
        down.direction = .down
        self.view.addGestureRecognizer(down)
    }
    
    func changeTabBar(hidden:Bool, animated: Bool){
        if tabBar.isHidden == hidden {
            return
        }
        let frame = tabBar.frame
        let offset = hidden ? frame.size.height : -frame.size.height
        let duration:TimeInterval = (animated ? 0.2 : 0.0)
        tabBar.isHidden = false

        UIView.animate(withDuration: duration, animations: {
            self.tabBar.frame = frame.offsetBy(dx: 0, dy: offset)
        }, completion: { (true) in
            self.tabBar.isHidden = hidden
        })
    }
    
    @objc func onSwipeUp(recognizer: UITapGestureRecognizer) {
        changeTabBar(hidden:false, animated:true)
    }

    @objc func onSwipeDown(recognizer: UITapGestureRecognizer) {
        changeTabBar(hidden:true, animated:true)
    }
}
