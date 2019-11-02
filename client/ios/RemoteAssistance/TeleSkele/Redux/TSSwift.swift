//
//  State.swift
//  E4TeamSense
//
//  Created by Yulius Tjahjadi on 6/19/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import Foundation
import ReSwift

struct TSState: StateType {
    var serverUrl: String = UserDefaults.standard.string(forKey: "serverUrl") ?? "http://yulius.fxpal.net:3000"
}
