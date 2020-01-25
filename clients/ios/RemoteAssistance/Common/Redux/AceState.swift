//
//  State.swift
//  E4TeamSense
//
//  Created by Yulius Tjahjadi on 6/19/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import Foundation
import ReSwift

struct AceState: StateType {
    //var serverUrl: String = UserDefaults.standard.string(forKey: "serverUrl") ?? "http://yulius.fxpal.net:3000"
    var serverUrl: String = UserDefaults.standard.string(forKey: "serverUrl") ?? "https://192.168.1.177:5443"

    var roomName: String = UserDefaults.standard.string(forKey: "roomName") ?? "fxpal"
    
    var userId: String = UserDefaults.standard.string(forKey: "userId") ?? "nobody"
}
