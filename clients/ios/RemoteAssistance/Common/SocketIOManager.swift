//
//  SocketIOManager.swift
//  teleskele
//
//  Created by Yulius Tjahjadi on 9/27/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import SocketIO
import ReSwift

class SocketIOManager {
    
    static let sharedInstance = SocketIOManager()
    
    var manager:SocketManager
    var rtcSocket:SocketIOClient
    var lmSocket:SocketIOClient
    var url:URL
    var enableLogging = false
    
    private init() {
        
        self.url = URL(string: store.ts.state.serverUrl)!
        self.manager = SocketManager(socketURL: self.url,
                                     config: [.log(enableLogging), .selfSigned(true),
                                              .forceNew(true), .forceWebsockets(true)])
        self.rtcSocket = self.manager.socket(forNamespace: "/room")
        self.lmSocket = self.manager.socket(forNamespace: "/")
        
        store.ts.subscribe(self)
    }
    
    func connect() {
        self.rtcSocket.connect()
        self.lmSocket.connect()
    }
}

extension SocketIOManager : StoreSubscriber {
    
    func newState(state: TSState) {
        if store.ts.state.serverUrl != self.url.absoluteString {
            self.manager.disconnect()
            
            self.manager = SocketManager(socketURL: self.url,
                                         config: [.log(enableLogging), .selfSigned(true),
                                                  .forceNew(true), .forceWebsockets(true)])

            self.rtcSocket = self.manager.socket(forNamespace: "/room")
            self.lmSocket = self.manager.socket(forNamespace: "/")
            
            self.connect()
        }
    }
}
