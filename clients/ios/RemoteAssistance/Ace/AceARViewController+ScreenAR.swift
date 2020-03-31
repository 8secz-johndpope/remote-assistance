//
//  AceARViewController+ScreenAR.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/23/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import ARKit
import Toast_Swift

// AR Screen
extension AceARViewController {
    
    func initScreenAR() {
        let overlayContent = self.loadHTML()
        self.webView = UIWebView(frame:CGRect(x:0,y:0,width: 640, height:480))
        //self.webView = WKWebView(frame:CGRect(x:0,y:0,width: 640, height:480))
        self.webView?.isOpaque = false
        self.webView?.backgroundColor = UIColor.clear
        self.webView?.scrollView.backgroundColor = UIColor.clear
        self.webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView?.loadHTMLString(overlayContent, baseURL: nil)
    }

    func loadHTML() -> String
    {
        do {
            if let filepath = Bundle.main.path(forResource: "overlay", ofType: "html") {
                let overlayContent = try String(contentsOfFile: filepath)
                return overlayContent
            }
        } catch {
            return ""
        }
        return ""
    }
    
    func drawCornerPoints(context: CGContext?, rect: CGRect, points: [CGPoint])
    {
        let markSize: CGFloat = 8
        
        // draw an outline in BLACK around the frame
        // to make sure the WHITE blocks will be detected
        context?.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
        // top border black
        context?.fill(CGRect(x: 0, y: 0, width: rect.width, height: markSize))
        // bottom border black
        context?.fill(CGRect(x: 0, y: rect.height-markSize, width: rect.width, height: markSize))
        // left border black
        context?.fill(CGRect(x: 0, y: 0, width: markSize, height: rect.height))
        // right border black
        context?.fill(CGRect(x: rect.width-markSize, y: 0, width: markSize, height: rect.height))

        // now use WHITE to draw the blocks encoding the 4 points
        context?.setFillColor(red: 255, green: 255, blue: 255, alpha: 1)

        let tl = points[2]
        let tr = points[3]
        let bl = points[0]
        let br = points[1]

        // encode x positions of tl and tr on the top border
        context?.fill(CGRect(x: tl.x-4, y: 0, width: 8, height: markSize))
        context?.fill(CGRect(x: tr.x-4, y: 0, width: 8, height: markSize))
        // encode x positions of bl and br on the bottom border
        context?.fill(CGRect(x: bl.x-4, y: rect.size.height, width: 8, height: -markSize))
        context?.fill(CGRect(x: br.x-4, y: rect.size.height, width: 8, height: -markSize))
        // encode y positions of tl and bl on the left border
        context?.fill(CGRect(x: 0, y: tl.y-4, width: markSize, height: 8))
        context?.fill(CGRect(x: 0, y: bl.y-4, width: markSize, height: 8))
        // encode y positions of tr and br on the right border
        context?.fill(CGRect(x: rect.size.width, y: tr.y-4, width: -markSize, height: 8))
        context?.fill(CGRect(x: rect.size.width, y: br.y-4, width: -markSize, height: 8))
    }

    func imageWithBorderPoints(image: UIImage, points: [CGPoint]) -> UIImage?
    {
        let size = CGSize(width: image.size.width, height: image.size.height)
        UIGraphicsBeginImageContext(size)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        image.draw(in: rect, blendMode: .normal, alpha: 1.0)

        let context = UIGraphicsGetCurrentContext()
        self.drawCornerPoints(context: context, rect: rect, points: points)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @IBAction func onResetScreenAR(_ sender: UIButton) {
//        DispatchQueue.main.async {
//            self.resetScreenAR()
//        }
    }
    
    func screenAR(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor {
            print("found imageAnchor!")
            if imageAnchor.name?.hasPrefix("screenar") == true {
                DispatchQueue.main.async {
                    print("adding rectanglenode for imageanchor")
                    let rectangleNode = RectangleNode(imageAnchor: imageAnchor, rootNode: node, view: self.webView!)
                    self.rectangleNodes[node] = rectangleNode
                }
            }
        }
    }
    
    // func resetScreenAR() {
    //     self.arView.session.pause()
    //     self.rectangleNodes.forEach({ $1.removeFromParentNode() })
    //     self.rectangleNodes.removeAll()
    //     self.arView.scene.rootNode.enumerateChildNodes { (node, stop) in
    //         node.removeFromParentNode()
    //     }
    //     self.arView.session.run(self.configuration, options: [.removeExistingAnchors, .resetTracking])
    // }
    
    func enableScreenAR() {
        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "ScreenAR Resources", bundle: Bundle.main) else {
            print("Missing expected asset catalog resources.")
            return
        }

        self.arView.session.pause()

        self.configuration.detectionObjects = []
        self.configuration.detectionImages = refImages

        self.arView.session.run(self.configuration, options: [.removeExistingAnchors, .resetTracking, .stopTrackedRaycasts])
    }

}
