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
    
    class RoomResponse : Codable {
        let room_uuid: String
        let experts: Int?
        let customers: Int?
    }
    
    func makeApi(_ path:String) -> RestController? {
        let url = "\(String(store.ts.state.serverUrl))/api/\(path)"
        return RestController.make(urlString: url)
    }
        
    func createRoom(callback: @escaping (RoomResponse) -> ()) {
        guard let api = makeApi("createRoom") else { return }
        api.get(RoomResponse.self) { result, response in
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
    
    func getActiveRooms(callback: @escaping ([RoomResponse]) -> ()) {
        guard let api = makeApi("getActiveRooms") else { return }
        api.get([RoomResponse].self) { result, response in
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
