//
//  AceAPI.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 1/22/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import Foundation
import RestEssentials
import ReSwift

class AceAPI {
    
    static let sharedInstance = AceAPI()
        
    init() {
    }
    
    class CreateRoomResponse : Codable {
        let room_uuid: String
    }
    
    func createRoom(callback: @escaping (CreateRoomResponse) -> ()) {
        let url = "\(String(store.ts.state.serverUrl))/api/createRoom"
        guard let api = RestController.make(urlString: url) else { return }
        api.get(CreateRoomResponse.self) { result, response in
            do {
                let response = try result.value() // response is of type HttpBinResponse
                DispatchQueue.main.async {
                    callback(response)
                }
            } catch {
                print("Error performing GET: \(error)")
            }
        }
    }
}
