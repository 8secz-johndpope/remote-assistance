//
//  Reducer.swift
//  E4TeamSense
//
//  Created by Yulius Tjahjadi on 6/19/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import Foundation
import ReSwift

// the reducer is responsible for evolving the application state based
// on the actions it receives
func Reducer(action: Action, state: AceState?) -> AceState {
    // if no state has been provided, create the default state
    var state = state ?? AceState()
    
    switch action {
    case let action as AceAction.SetServerURL:
        state.serverUrl = action.serverUrl
        UserDefaults.standard.set(state.serverUrl, forKey: "serverUrl")
    case let action as AceAction.SetRoomName:
        state.roomName = action.roomName
        UserDefaults.standard.set(state.roomName, forKey: "roomName")
    default:
        break
    }
    
    return state
}
