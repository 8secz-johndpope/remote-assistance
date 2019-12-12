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
    
    override func viewDidLoad() {
        let url = "\(store.ts.state.serverUrl)/chat"
        let chatUrl = URL(string:url)
        let request = URLRequest(url: chatUrl!)
        webView.load(request)
    }

}
