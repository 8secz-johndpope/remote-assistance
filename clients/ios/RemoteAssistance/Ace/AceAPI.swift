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
    
    var acceptSelfSignedCertificate = true
        
    init() {
    }
    
    // response types
    class UuidResponse : Codable {
        let uuid: String
    }

    class UserResponse : Codable {
        
        enum UserType : String, Codable {
            case customer
            case expert
        }

        let id: Int
        let type: UserType
        let photo: String?
        let uuid: String
        let password: String?
        let email: String?
        let name: String?
    }
    
    class RoomResponse : Codable {
        let id: Int
        let uuid: String
        let time_ping: Int?
        let time_request: Int?
        let time_created: Int?
        let experts: Int?
        let customers: Int?
    }
    
    class UserToRoomResponse : Codable {
        let user_uuid: String
        let room_uuid: String
    }
    
    class AnchorResponse : Codable {

        enum AnchorType : String, Codable {
            case image
            case object
        }

        let id: Int
        let uuid: String
        let data: String
        let type: AnchorType
        let name: String
    }
    
    class ClipResponse : Codable {
        let id: Int
        let uuid: String
        let name: String
        let user_uuid: String
        let room_uuid: String
        let thumbnailUrl: String?
        let webmUrl: String?
        let mp4Url: String?
    }
    
    class AssociateClipToAnchorResponse : Codable {
        let anchor_uuid: String
        let clip_uuid: String
    }
    
    
    // internal implementation
    private func makeApi(_ path:String) -> RestController? {
        let url = "\(String(store.ts.state.serverUrl))/api/\(path)"
        let api = RestController.make(urlString: url)
        api?.acceptSelfSignedCertificate = self.acceptSelfSignedCertificate
        return api
    }
    
    private func callApi<T:Decodable>(_ path:String, callback: @escaping (T?, Error?) -> ()) {
        guard let api = makeApi(path) else { return }
        api.get(T.self) { result, response in
            do {
                let response = try result.value() // response is of type HttpBinResponse
                DispatchQueue.main.async {
                    callback(response, nil)
                }
            } catch {
                print("Error performing GET: \(error)")
                DispatchQueue.main.async {
                    callback(nil, error)
                }
            }
        }

    }
    
    func createCustomer(callback: @escaping (UuidResponse?, Error?) -> ()) {
        callApi("createCustomer", callback: callback)
    }
    
    func createExpert(callback: @escaping (UuidResponse?, Error?) -> ()) {
        callApi("createExpert", callback: callback)
    }

    func deleteUser(_ userId:String, callback: @escaping (UuidResponse?, Error?) -> ()) {
        callApi("deleteUser/\(userId)", callback: callback)
    }

    func getUser(_ userId:String, callback: @escaping (UserResponse?, Error?) -> ()) {
        callApi("getUser/\(userId)", callback: callback)
    }
    
    func getAllUsers(callback: @escaping ([UserResponse]?, Error?) -> ()) {
        callApi("getAllUsers", callback: callback)
    }
        
    func createRoom(callback: @escaping (UuidResponse?, Error?) -> ()) {
        callApi("createRoom", callback: callback)
    }
    
    func deleteRoom(_ userId:String, callback: @escaping (UuidResponse?, Error?) -> ()) {
        callApi("deleteRoom/\(userId)", callback: callback)
    }

    func getRoom(_ roomName:String, callback: @escaping (RoomResponse?, Error?) -> ()) {
        callApi("getRoom/\(roomName)", callback: callback)
    }

    func getActiveRooms(callback: @escaping ([RoomResponse]?, Error?) -> ()) {
        callApi("getActiveRooms", callback: callback)
    }
    
    func getAllRooms(callback: @escaping ([RoomResponse]?, Error?) -> ()) {
        callApi("getAllRooms", callback: callback)
    }

    func addUser(_ userId:String, toRoom roomId:String, callback: @escaping (UserToRoomResponse?, Error?) -> ()) {
        print("url: /api/addUserToRoom/\(userId)/\(roomId)")
        callApi("addUserToRoom/\(userId)/\(roomId)", callback: callback)
    }

    func removeUser(_ userId:String, fromRoom roomId:String, callback: @escaping (UserToRoomResponse?, Error?) -> ()) {
        callApi("removeUserFromRoom/\(userId)/\(roomId)", callback: callback)
    }
    
    func getAnchor(_ anchorId:String, callback: @escaping (AnchorResponse?, Error?) -> ()) {
        callApi("getAnchor/\(anchorId)", callback: callback)
    }

    func getAllAnchors(_ text:String = "", callback: @escaping (AnchorResponse?, Error?) -> ()) {
        var path = "getAllAnchors"
        if text != "" {
            path = "getAllAnchors/\(text)"
        }
        callApi(path, callback: callback)
    }
    
    func createClip(callback: @escaping (UuidResponse?, Error?) -> ()) {
        callApi("createClip", callback: callback)
    }

    func deleteClip(_ clipId:String, callback: @escaping (UuidResponse?, Error?) -> ()) {
        callApi("deleteClip/\(clipId)", callback: callback)
    }

    func getClip(_ clipId:String, callback: @escaping (ClipResponse?, Error?) -> ()) {
        callApi("getClip/\(clipId)", callback: callback)
    }

    func getClips(forAnchor anchorId:String, andRoom roomId:String, callback: @escaping ([ClipResponse]?, Error?) -> ()) {
        callApi("getClipsForAnchor/\(anchorId)/\(roomId)", callback: callback)
    }

    func getAllClips(_ clipId:String, callback: @escaping ([ClipResponse]?, Error?) -> ()) {
        callApi("getAllClips", callback: callback)
    }

    func addClip(_ clipId:String, toAnchor anchorId:String, blobPos:Int, callback: @escaping (AssociateClipToAnchorResponse?, Error?) -> ()) {
        callApi("addClipToAnchor/\(anchorId)/\(clipId)/\(blobPos)", callback: callback)
    }
    
    func removeClip(_ clipId:String, fromAnchor anchorId:String, callback: @escaping (AssociateClipToAnchorResponse?, Error?) -> ()) {
        callApi("removeClipFromAnchor/\(clipId)/\(anchorId)", callback: callback)
    }
}
