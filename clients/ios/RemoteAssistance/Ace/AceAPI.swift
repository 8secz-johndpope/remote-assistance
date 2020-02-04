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

    struct User : Codable {
        
        enum UserType : String, Codable {
            case none
            case customer
            case expert
        }
        
        let id: Int
        let uuid: String
        let type: UserType
        let name: String?
        let email: String?
        let password: String?
        let photo_url: String?
    }
    
    struct Room : Codable {
        let id: Int
        let uuid: String
        let time_created: Int
        let time_ping: Int?
        let time_request: Int?
        let experts: Int?
        let customers: Int?
    }
    
    struct UserRoom : Codable {
        let id: Int?
        let uuid: String?
        let user_uuid: String
        let room_uuid: String
        let time_ping: Int?
        let state: Int?
    }
    
    struct Anchor : Codable {

        enum AnchorType : String, Codable {
            case none
            case image
            case object
        }

        let id: Int
        let uuid: String
        let url: String
        let type: AnchorType
        let name: String
    }
    
    struct Clip : Codable {
        let id: Int
        let uuid: String
        let name: String
        let user_uuid: String
        let room_uuid: String
        let thumbnail_url: String?
        let webm_url: String?
        let mp4_url: String?
    }
    
    struct AssociateClipToAnchorResponse : Codable {
        let anchor_uuid: String
        let clip_uuid: String
    }
    
    
    // internal implementation
    private func makeApi(_ path:String) -> RestController? {
        let url = "\(String(store.ace.state.serverUrl))/api/\(path)"
        let api = RestController.make(urlString: url)
        api?.acceptSelfSignedCertificate = self.acceptSelfSignedCertificate
        return api
    }
    
    private func restCallback<T:Codable>(_ method:String, _ path:String, _ callback: @escaping (T?, Error?) -> ()) -> (Result<T>, HTTPURLResponse?) -> () {
        return { result, response in
            do {
                let value = try result.value() // response is of type HttpBinResponse
                DispatchQueue.main.async {
                    callback(value, nil)
                }
            } catch NetworkingError.malformedResponse(let data, let error?) {
                let dataStr = String(data: data, encoding: .utf8)!
                print("JSON parse error \(method): \(path) error: \(error) data: \(dataStr)")
                DispatchQueue.main.async {
                    callback(nil, NetworkingError.malformedResponse(data, error))
                }

            } catch {
                print("Error performing \(method): \(path) error: \(error)")
                DispatchQueue.main.async {
                    callback(nil, error)
                }
            }

        }
    }
    
    private func get<T:Codable>(_ path:String, callback: @escaping (T?, Error?) -> ()) {
        guard let api = makeApi(path) else { return }
        api.get(T.self, callback: self.restCallback("GET", path, callback))
    }
    
    private func post<T:Codable>(_ path:String, _ data:T, callback: @escaping (T?, Error?) -> ()) {
        guard let api = makeApi(path) else { return }
        api.post(data, responseType: T.self, callback: self.restCallback("POST", path, callback))
    }
    
    private func put<T:Codable>(_ path:String, _ data:T, callback: @escaping (T?, Error?) -> ()) {
        guard let api = makeApi(path) else { return }
        api.put(data, responseType: T.self, callback: self.restCallback("PUT", path, callback))
    }
    
    private func patch<T:Codable>(_ path:String, _ data:T, callback: @escaping (T?, Error?) -> ()) {
        guard let api = makeApi(path) else { return }
        api.patch(data, responseType: T.self, callback: self.restCallback("PATCH", path, callback))
    }
    
    private func delete<T:Codable>(_ path:String, callback: @escaping (T?, Error?) -> ()) {
        guard let api = makeApi(path) else { return }
        let decodableDeserializer = DecodableDeserializer<T>()
        api.delete(JSON(), withDeserializer: decodableDeserializer, callback: self.restCallback("DELETE", path, callback))
    }
        
    func createUser(_ user:User, callback: @escaping (User?, Error?) -> ()) {
        post("user", user, callback: callback)
    }

    func updateUser(_ user:User, callback: @escaping (User?, Error?) -> ()) {
        put("user", user, callback: callback)
    }

    func deleteUser(_ uuid:String, callback: @escaping (UuidResponse?, Error?) -> ()) {
        delete("user/\(uuid)", callback: callback)
    }

    func getUser(_ uuid:String, callback: @escaping (User?, Error?) -> ()) {
        get("user/\(uuid)", callback: callback)
    }
    
    func getAllUsers(callback: @escaping ([User]?, Error?) -> ()) {
        get("user", callback: callback)
    }

    func createRoom(callback: @escaping (Room?, Error?) -> ()) {
        let room = Room(id:0, uuid:"", time_created: 0, time_ping: nil, time_request: nil, experts: nil, customers: nil)
        post("room", room, callback: callback)
    }
    
    func updateRoom(_ room:Room, callback: @escaping (Room?, Error?) -> ()) {
        put("room", room, callback: callback)
    }

    func deleteRoom(_ uuid:String, callback: @escaping (UuidResponse?, Error?) -> ()) {
        delete("room/\(uuid)", callback: callback)
    }

    func getRoom(_ uuid:String, callback: @escaping (Room?, Error?) -> ()) {
        get("room/\(uuid)", callback: callback)
    }

    func getActiveRooms(callback: @escaping ([Room]?, Error?) -> ()) {
        get("room?active=1", callback: callback)
    }

    func getAllRooms(callback: @escaping ([Room]?, Error?) -> ()) {
        get("room", callback: callback)
    }

    func addUser(_ userId:String, toRoom roomId:String, callback: @escaping (UserRoom?, Error?) -> ()) {
        let userRoom = UserRoom(id: 0, uuid: "", user_uuid: userId, room_uuid: roomId, time_ping: nil, state: nil)
        post("userRoom", userRoom, callback: callback)
    }

    func removeUser(_ userId:String, fromRoom roomId:String, callback: @escaping (UserRoom?, Error?) -> ()) {
        delete("userRoom/\(userId)/\(roomId)", callback: callback)
    }
    
//    func getUsers(inRoom roomId:String, callback: @escaping (UserRoom?, Error?) -> ()) {
//        get("userRoom/\(userId)/\(roomId)", callback: callback)
//    }

    
    func createAnchor(_ anchor:Anchor, callback: @escaping (Anchor?, Error?) -> ()) {
        post("anchor", anchor, callback: callback)
    }

    func updateAnchor(_ anchor:Anchor, callback: @escaping (Anchor?, Error?) -> ()) {
        put("anchor", anchor, callback: callback)
    }

    func deleteAnchor(_ uuid:String, callback: @escaping (UuidResponse?, Error?) -> ()) {
        delete("anchor/\(uuid)", callback: callback)
    }
        
    func getAnchor(_ uuid:String, callback: @escaping (Anchor?, Error?) -> ()) {
        get("anchor/\(uuid)", callback: callback)
    }


    func getAllAnchors(_ text:String = "", callback: @escaping ([Anchor]?, Error?) -> ()) {
        var path = "anchor"
        if text != "" {
            let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            path = "anchor?text=\(encodedText ?? "")"
        }
        get(path, callback: callback)
    }

    func createClip(_ clip:Clip, callback: @escaping (Clip?, Error?) -> ()) {
        post("clip", clip, callback: callback)
    }

    func updateClip(_ clip:Clip, callback: @escaping (Clip?, Error?) -> ()) {
        put("clip", clip, callback: callback)
    }

    func deleteClip(_ uuid:String, callback: @escaping (UuidResponse?, Error?) -> ()) {
        delete("clip/\(uuid)", callback: callback)
    }
    
    func getClip(_ uuid:String, callback: @escaping (Clip?, Error?) -> ()) {
        get("clip/\(uuid)", callback: callback)
    }

    func getClips(forAnchor anchorId:String, callback: @escaping ([Clip]?, Error?) -> ()) {
        get("clip?anchor_uuid=\(anchorId)", callback: callback)
    }

    func getAllClips(callback: @escaping ([Clip]?, Error?) -> ()) {
        get("clip", callback: callback)
    }

//    func addClip(_ clipId:String, toAnchor anchorId:String, blobPos:String, callback: @escaping (AssociateClipToAnchorResponse?, Error?) -> ()) {
//        callApi("addClipToAnchor/\(anchorId)/\(clipId)/\(blobPos)", callback: callback)
//    }
//
//    func removeClip(_ clipId:String, fromAnchor anchorId:String, callback: @escaping (AssociateClipToAnchorResponse?, Error?) -> ()) {
//        callApi("removeClipFromAnchor/\(clipId)/\(anchorId)", callback: callback)
//    }
}
