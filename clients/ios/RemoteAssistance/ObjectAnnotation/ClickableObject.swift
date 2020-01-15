//
//  ClickableObject.swift
//  RemoteAssistance
//
//  Created by Gerry Filby on 1/14/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import Foundation

protocol ClickableObjectDelegate: AnyObject {
    func showMessage(title: String, message:String)
    func showVideo(tag:Int)
}

class ClickableObject: UIButton {

    weak var delegate: ClickableObjectDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action:  #selector(objectTapped(_:)), for: .touchUpInside)
    }
    
    @objc func objectTapped(_ sender: UIButton){
        self.delegate?.showVideo(tag: sender.tag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
