//
//  ViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 10/29/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var displayView: UIView!
    
    var isHidden = false
    var vc:UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let up = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeUp))
        up.direction = .up
        self.view.addGestureRecognizer(up)

        let down = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeDown))
        down.direction = .down
        self.view.addGestureRecognizer(down)
        
        
        // 3rd item is help
        tabBar.selectedItem = tabBar.items![3]
        tabBar.delegate = self
        self.tabBar(self.tabBar, didSelect: tabBar.selectedItem!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.invalidateIntrinsicContentSize()
    }
    
    func showTabBar(duration : Double = 0.2) {
        UIView.animate(withDuration: duration, animations: {
            self.isHidden = false
            self.tabBar.transform = CGAffineTransform.identity
        })
    }
    
    func hideTabBar(duration : Double = 0.2) {
        UIView.animate(withDuration: duration, animations: {
            self.isHidden = true
            self.tabBar.transform = CGAffineTransform(translationX: 0, y: 150)
        })
    }
    
    @objc func onSwipeUp(recognizer: UITapGestureRecognizer) {
        self.showTabBar()
    }

    @objc func onSwipeDown(recognizer: UITapGestureRecognizer) {
        self.hideTabBar()
    }
}


extension  ViewController : UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
//        print("\(item.title!) clicked")

        // remove previous view controller
        if let currentVC = self.vc {
            currentVC.removeFromParent()
            self.displayView.removeSubviews()
        }
        
        switch (item.title) {
        case "Hands":
            vc = self.storyboard?.instantiateViewController(identifier: "handsVC")
            let view = vc!.view!
            view.frame = self.view.frame
            self.displayView.addSubview(view)
            break
        case "Screen":
            vc = self.storyboard?.instantiateViewController(identifier: "screenVC")
            let view = vc!.view!
            view.frame = self.view.frame
            self.displayView.addSubview(view)
            break
        case "Object":
            vc = self.storyboard?.instantiateViewController(identifier: "objectAnnotationVC")
            let view = vc!.view!
            view.frame = self.view.frame
            self.displayView.addSubview(view)
            break
        case "Help":
            vc = self.storyboard?.instantiateViewController(identifier: "helpVC")
            let view = vc!.view!
            view.frame = self.view.frame
            self.displayView.addSubview(view)
            break
        case "Chat":
            vc = self.storyboard?.instantiateViewController(identifier: "chatVC")
            let view = vc!.view!
            view.frame = self.view.frame
            self.displayView.addSubview(view)
            break
        case "Settings":
            vc = self.storyboard?.instantiateViewController(identifier: "settingsVC")
            let view = vc!.view!
            view.frame = self.view.frame
            self.displayView.addSubview(view)
            break
        default:
            break
        }
        
        self.view.bringSubviewToFront(self.tabBar)
    }

}
