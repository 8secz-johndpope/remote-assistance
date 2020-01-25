//
//  ChatViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 12/12/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import UIKit
import WebKit

class ChatViewController: UIViewController,QRCodeScannerDelegate {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        let url = "\(store.ace.state.serverUrl)/chat"
        let chatUrl = URL(string:url)
        let request = URLRequest(url: chatUrl!)
        webView.configuration.userContentController.add(self, name: "launchRA")
        webView.configuration.userContentController.add(self, name: "launchQRScanner")
        webView.load(request)
        webView.navigationDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func launchRA(dict: NSDictionary) {
//         let user_uuid = dict["user_uuid"] as? String ?? ""
        let room_uuid = dict["room_uuid"] as? String ?? ""
        // let printer_name = (dict["archive"] as [String:Any])["printerName"]!
//        let printerName = dict["printerName"]

        // TODO: Launch remote assist view controller with room uuid: room_uuid
        let action = AceAction.SetRoomName(roomName: room_uuid)
        store.ace.dispatch(action)

        let vc = AceViewController.instantiate(fromAppStoryboard: .Ace)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func launchQRScanner(dict: NSDictionary) {
        let nvc = QRCodeSCanner()
        nvc.delegate = self
        self.navigationController?.pushViewController(nvc, animated: true)
    }

    func qrCodeScannerResponse(code: String) {
        webView.evaluateJavaScript("onQRCodeScanned('\(code)')", completionHandler: nil)
    }

}

extension ChatViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("error: \(error)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("provisional nav error: \(error)")
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
        }
    }
}
