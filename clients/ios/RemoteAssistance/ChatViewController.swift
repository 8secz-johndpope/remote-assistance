//
//  ChatViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 12/12/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import UIKit
import WebKit

class ChatViewController: UIViewController {
   
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var progressBar: UIProgressView!
    
    // There appears to be a bug where ARView w/ animations cannot be cleaned up properly
    // We keep the view controller around to reuse
    var rcProjectView:AceRCProjectViewController = AceRCProjectViewController.instantiate(fromAppStoryboard: .Ace)

    override func viewDidLoad() {
        let url = "\(store.ace.state.serverUrl)/chat"
        let chatUrl = URL(string:url)
        let request = URLRequest(url: chatUrl!)

        // clear the cache
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        
        // disable scrolling
        webView.scrollView.isScrollEnabled = false;
        webView.scrollView.panGestureRecognizer.isEnabled = false;
        webView.scrollView.bounces = false;
        
        // add progress observer
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        progressBar.progress = 0
        progressBar.transform = CGAffineTransform(scaleX: 1, y: 4)

        webView.configuration.userContentController.add(self, name: "launchRA")
        webView.configuration.userContentController.add(self, name: "launchQRScanner")
        webView.configuration.userContentController.add(self, name: "launchOCRScanner")
        webView.configuration.userContentController.add(self, name: "launchAR3D")
        webView.configuration.userContentController.add(self, name: "launchARVideo")

        webView.load(request)
        webView.navigationDelegate = self
        
        // add start over button
        let barButton = UIBarButtonItem(title: "Start Over", style: .done, target: self, action: #selector(onStartOver))
        self.navigationItem.rightBarButtonItem = barButton;
        
        let c = #colorLiteral(red: 0, green: 0.1762945354, blue: 0.3224477768, alpha: 1)
        navigationController?.navigationBar.tintColor = c
        navigationController?.navigationBar.barTintColor = c
        
        self.navigationItem.hidesBackButton = true
        let myBackButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = myBackButton
    }
    
    @objc func back (sender: UIBarButtonItem) {
        if (webView.canGoBack) {
            webView.goBack()
        } else {
            self.navigationController?.popViewController(animated:true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    func uicolorFromHex(rgbValue:UInt32)->UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0

        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
    
    func generateRandomId(_ length:Int = 9) -> String {
        let letters = "0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }

    func launchRA(dict: NSDictionary) {
        var roomId = "fxpal"
        
        if let archive = dict["archive"] as? [String:Any] {
            // save conversation archive to user defaults
            UserDefaults.standard.set(archive, forKey: "conversation_archive")

            // create room name based on printer
            if let printerName = archive["printerName"] as? String {
                roomId = "\(printerName.replacingOccurrences(of:" ", with: "-"))-\(generateRandomId())"
            }
        }
        
        // Launch remote assist view controller with room uuid: roomId
        let action = AceAction.SetRoomName(roomName: roomId)
        store.ace.dispatch(action)

        let vc = AceViewController.instantiate(fromAppStoryboard: .Ace)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func launchQRScanner(dict: NSDictionary) {

        let nvc = QRCodeSCanner()
        nvc.delegate = self
        self.navigationController?.pushViewController(nvc, animated: true)
    }
    
    func launchAR3D(dict: NSDictionary) {
        let nvc = rcProjectView
        nvc.sceneName = "Copier"
        nvc.title = "Install New Toner"
//        nvc.showDebug = true
        self.navigationController?.pushViewController(nvc, animated: true)
    }

    func launchARVideo(dict: NSDictionary) {
        let nvc = ARSceneViewController.instantiate(fromAppStoryboard: .Main)
        nvc.delegate = self
        self.navigationController?.pushViewController(nvc, animated: true)
    }

    func launchOCRScanner(dict: NSDictionary) {
        var options = [String]()
        if let arr1 = dict["options"] as? [String:Any] {
            if let arr2 = arr1["data"] as? [Any] {
                for object in arr2 {
                    if let item = object as? [String: Any] {
                        if let itemName = item["name"] as? String {
                            options.append(itemName)
                        } else if let itemCode = item["code"] as? String {
                            options.append(itemCode)
                        }

                    }
                }
            }
        }
        let nvc = OCRScanner(options: options)
        nvc.delegate = self
        self.navigationController?.pushViewController(nvc, animated: true)
    }
    
    @objc
    func onStartOver() {
        webView.reload()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress" {
            progressBar.progress = Float(webView.estimatedProgress)
            if webView.estimatedProgress == 1.0 {
                UIView.animate(withDuration: 1.5, animations: {
                    self.progressBar.alpha = 0
                })
                
            } else {
                progressBar.alpha = 1.0
            }
        }
    }
    
}

extension ChatViewController : QRCodeScannerDelegate {
    func qrCodeScannerResponse(code: String) {
        webView.evaluateJavaScript("onQRCodeScanned('\(code)')", completionHandler: nil)
    }
}

extension ChatViewController : OCRDelegate {
        func ocrResponse(text: String) {
            self.webView.evaluateJavaScript("onOCRScanned('\(text)')", completionHandler: nil)
            //self.navigationController?.popViewController(animated: true)
    }
}

extension ChatViewController : AceAnimatorDelegate {
        func aceAnimatorResponse(text: String) {
            self.webView.evaluateJavaScript("onAR3DResponse('\(text)')", completionHandler: nil)
            //self.navigationController?.popViewController(animated: true)
    }
}

extension ChatViewController : ARSceneViewControllerDelegate {
        func arSceneViewControllerResponse(text: String) {
            self.webView.evaluateJavaScript("onARVideoResponse('\(text)')", completionHandler: nil)
            //self.navigationController?.popViewController(animated: true)
    }
}

extension ChatViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if webView != self.webView {
            decisionHandler(.allow)
            return
        }

        let app = UIApplication.shared
        if let url = navigationAction.request.url {
            // Handle target="_blank"
            if navigationAction.targetFrame == nil {
                if app.canOpenURL(url) {
                    app.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            // Handle phone and email links
            if url.scheme == "tel" || url.scheme == "mailto" {
                if app.canOpenURL(url) {
                    app.open(url)
                }

                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("error: \(error)")
    }
        
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // allow any ssl cert
        let cred = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
}

extension ChatViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "launchRA", let dict = message.body as? NSDictionary {
            launchRA(dict: dict)
        } else if message.name == "launchQRScanner", let dict = message.body as? NSDictionary {
            launchQRScanner(dict: dict)
        } else if message.name == "launchOCRScanner", let dict = message.body as? NSDictionary {
            launchOCRScanner(dict: dict)
        } else if message.name == "launchAR3D", let dict = message.body as? NSDictionary {
            launchAR3D(dict: dict)
        } else if message.name == "launchARVideo", let dict = message.body as? NSDictionary {
            launchARVideo(dict: dict)
        }
    }
}
