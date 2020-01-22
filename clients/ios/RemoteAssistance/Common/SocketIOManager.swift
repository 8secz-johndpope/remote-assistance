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
    var socket:SocketIOClient
    var roomName:String
    var url:URL
    var enableLogging = false
    
    var callbacks:[String:NormalCallback] = [String:NormalCallback]()
    
    private init() {
        self.roomName = store.ts.state.roomName
        self.url = URL(string: store.ts.state.serverUrl) ?? URL(string: "https://remote-assistance.paldeploy.com")!

        self.manager = SocketManager(socketURL: self.url,
                                     config: [.log(enableLogging), .selfSigned(true),
                                              .forceNew(true), .forceWebsockets(true)])
        self.socket = self.manager.socket(forNamespace: "/room")

        self.socket.on("connect") { data, ack in
            self.socket.emit("join", ["room": self.roomName])
        }
        
        store.ts.subscribe(self)
    }

    func connect() {
        if self.socket.status == .connected {
            self.socket.disconnect()
            self.socket.removeAllHandlers()
            self.socket = self.manager.socket(forNamespace: "/room")
            
            for (event, cb) in callbacks {
                self.socket.on(event, callback:cb)
            }

            self.socket.on("connect") { data, ack in
                self.socket.emit("join", ["room": self.roomName])
            }
            
            self.socket.connect()
        } else {
            self.socket.connect()
        }
    }

    func disconnect() {
        self.socket.disconnect()
        self.manager.disconnect()
    }

    func on(_ event: String, callback: @escaping NormalCallback) {
        self.callbacks[event] = callback
        self.socket.on(event, callback:callback)
    }

    func off(_ event: String) {
        self.callbacks.removeValue(forKey: event)
        self.socket.off(event)
    }

    func emit(_ event: String, _ items: SocketData..., completion: (() -> ())? = nil)  {
        self.socket.emit(event, with: items, completion:completion)
    }
}

extension SocketIOManager : StoreSubscriber {
    
    func newState(state: TSState) {
        if store.ts.state.serverUrl != self.url.absoluteString ||
            store.ts.state.roomName != self.roomName
           {
            self.roomName = store.ts.state.roomName
            self.url = URL(string: store.ts.state.serverUrl) ?? URL(string: "https://remote-assistance.paldeploy.com")!

            self.manager.disconnect()
            
            self.manager = SocketManager(socketURL: self.url,
                                         config: [.log(enableLogging), .selfSigned(true),
                                                  .forceNew(true), .forceWebsockets(true)])

            self.socket = self.manager.socket(forNamespace: "/room")
            
            self.socket.on("connect") { data, ack in
                self.socket.emit("join", ["room": self.roomName ])
            }

            for (event, cb) in callbacks {
                socket.on(event, callback:cb)
            }

            self.connect()
        }
    }
}
