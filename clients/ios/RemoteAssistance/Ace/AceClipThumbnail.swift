//
//  AceClipThumbnail.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 2/3/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit

class AceClipThumbnail : UIImageView {
    
    var maskImageView = UIImageView()
    var playView:UIImageView = UIImageView()
    @IBInspectable
    var maskImage: UIImage? {
        didSet {
            maskImageView.image = maskImage
            updateView()
        }
    }
    
    override init(image: UIImage?) {
        super.init(image:image)
        self.addSubview(playView)
        maskImage = UIImage(named:"ClipMask")
        maskImageView.image = maskImage
        playView.image = UIImage(named:"PlayIcon")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // This updates mask size when changing device orientation (portrait/landscape)
    override func layoutSubviews() {
        super.layoutSubviews()
        updateView()
    }

    func updateView() {
        playView.frame = self.frame
        if maskImageView.image != nil {
            maskImageView.frame = bounds
            mask = maskImageView
        }
    }
    
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds:bounds)
        return renderer.image { rendererCotext in
            layer.render(in: rendererCotext.cgContext)
        }
    }
}
