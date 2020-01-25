//
//  Actions.swift
//  E4TeamSense
//
//  Created by Yulius Tjahjadi on 6/19/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import Foundation
import ReSwift

struct AceAction {

    // all of the actions that can be applied to the state
    struct SetServerURL: Action {
        let serverUrl:String
    }

    struct SetRoomName: Action {
        let roomName:String
    }

}
