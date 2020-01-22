//
//  AceSketchViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/10/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit

class AceSketchViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var lastPoint = CGPoint.zero
    var color = UIColor.yellow
    var brushWidth: CGFloat = 5.0
    var opacity: CGFloat = 1.0
    var swiped = false
    
    class AceMessageSketchDraw {
        var start = CGPoint(x:0, y:0)
        var end = CGPoint(x:0, y:0)
        var size = CGSize(width: 0, height: 0)
        
        func parse(_ data:[String:CGFloat]) -> AceMessageSketchDraw {
            if let sX = data["sX"] {
                start.x = sX
            }
            if let sY = data["sY"] {
                start.y = sY
            }
            if let eX = data["eX"] {
                end.x = eX
            }
            if let eY = data["eY"] {
                end.y = eY
            }
            if let cW = data["cW"] {
                size.width = cW
            }
            if let cH = data["cH"] {
                size.height = cH
            }
            return self
        }
        
        // reframe the start and end points to the phone display space
        func transformToFrame(_ frameSize: CGSize) -> AceMessageSketchDraw {
            let aspectRatio = frameSize.width/frameSize.height
            var scale:CGFloat = 1.0
            var offset = CGPoint(x: 0, y: 0)
            
            // if true, width is filled at the expert side
            var spanWidth = false

            if (size.width > size.height) {
                if (frameSize.width > frameSize.height) {
                    spanWidth = true
                } else {
                    spanWidth = false
                }
            } else {
                if (frameSize.width > frameSize.height) {
                    spanWidth = false
                } else {
                    spanWidth = true
                }
            }
            
            if spanWidth {
                scale = frameSize.width/size.width
                offset.x = 0
                offset.y = -(size.height - size.width/aspectRatio)/2
            } else {
                scale = frameSize.height/size.height
                offset.x = -(size.width - size.height*aspectRatio)/2
                offset.y = 0
            }
            
            // transform to screen space
            start.x = (offset.x + start.x)*scale
            start.y = (offset.y + start.y)*scale
            end.x = (offset.x + end.x)*scale
            end.y = (offset.y + end.y)*scale
            
            return self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let socket = SocketIOManager.sharedInstance
        socket.on("sketch_draw") { data, ack in
            for line in data {
                let msg = AceMessageSketchDraw()
                    .parse(line as! [String:CGFloat])
                    .transformToFrame(self.view.frame.size)
                
                self.drawLine(from: msg.start, to: msg.end)
            }
        }

        socket.on("sketch_clear") { data, ack in            
            self.imageView.image = nil
        }
    }
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
      // 1
      UIGraphicsBeginImageContext(view.frame.size)
      guard let context = UIGraphicsGetCurrentContext() else {
        return
      }
      imageView.image?.draw(in: view.bounds)
        
      // 2
      context.move(to: fromPoint)
      context.addLine(to: toPoint)
      
      // 3
      context.setLineCap(.round)
      context.setBlendMode(.normal)
      context.setLineWidth(brushWidth)
      context.setStrokeColor(color.cgColor)
      
      // 4
      context.strokePath()
      
      // 5
      imageView.image = UIGraphicsGetImageFromCurrentImageContext()
      imageView.alpha = opacity
      UIGraphicsEndImageContext()
    }
}
