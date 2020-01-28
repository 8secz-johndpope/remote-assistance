//
//  AceAPITests.swift
//  RemoteAssistanceTests
//
//  Created by Yulius Tjahjadi on 1/22/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import XCTest
@testable import RemoteAssistance

class AceAPITests: XCTestCase {
    
    let api = AceAPI.sharedInstance
    var user:AceAPI.User?
    var room:AceAPI.Room?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
//        let setServerURL = AceAction.SetServerURL(serverUrl: "https://localhost:5443")
        let setServerURL = AceAction.SetServerURL(serverUrl: "https://yulius.fxpal.net:5443")
        store.ace.dispatch(setServerURL)
        
//        let expectation = XCTestExpectation(description: "Setup")
//
//        let user = AceAPI.User(id:0, uuid:"", type: .customer, name: "testUser", email: "test@fxpal.com", password: nil, photo_url:nil)
//        self.api.createUser(user) { result, error in
//            XCTAssert(result != nil, "createCustomer() result is nil")
//            self.user = result
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 10.0)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
//        let expectation = XCTestExpectation(description: "Setup")
//
//        self.api.deleteUser(self.user!.uuid) { result, error in
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 10.0)

    }
        
    func testCreateDeleteUser() {
        let expectation = XCTestExpectation(description: "createCustomer API")
        let user = AceAPI.User(id:0, uuid:"", type: .customer, name: "testUser", email: "test@fxpal.com", password: nil, photo_url:nil)
        api.createUser(user) { result, error in
            XCTAssert(result != nil, "createCustomer() result is nil")
            XCTAssert(error == nil, "createCustomer() returned error")
            self.api.deleteUser(result!.uuid) { result, error in
                XCTAssert(result != nil, "deleteUser() result is nil")
                XCTAssert(error == nil, "deleteUser() returned error")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetUser() {
        let expectation = XCTestExpectation(description: "getUser API")
        self.api.getAllUsers() { result, error in
            XCTAssert(result != nil, "getUser() result is nil")
            XCTAssert(error == nil, "getUser() returned error")
            self.api.getUser(result!.first!.uuid) { result, error in
                XCTAssert(result != nil, "getUser() result is nil")
                XCTAssert(error == nil, "getUser() returned error")
                XCTAssert(result?.id ?? 0 > 0, "getUser() id is invalid")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetAllUsers() {
        let expectation = XCTestExpectation(description: "getAllUsers API")
        api.getAllUsers() { result, error in
            XCTAssert(result != nil, "getAllUsers() result is nil")
            XCTAssert(error == nil, "getAllUsers() returned error")
            XCTAssert(result?.count ?? 0 > 0, "getAllUsers() returned 0")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)

    }

    func testCreateDeleteRoom() {
        let expectation = XCTestExpectation(description: "createRoom API")
        api.createRoom() { result, error in
            XCTAssert(result != nil, "createRoom() result is nil")
            XCTAssert(error == nil, "createRoom() returned error")
            self.api.deleteUser(result!.uuid) { result, error in
                XCTAssert(result != nil, "deleteRoom() result is nil")
                XCTAssert(error == nil, "deleteRoom() returned error")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testGetRoom() {
        let expectation = XCTestExpectation(description: "getRoom API")
        api.createRoom() { result, error in
            XCTAssert(result != nil, "createRoom() result is nil")
            XCTAssert(error == nil, "createRoom() returned error")

            let uuid = result!.uuid
            self.api.getRoom(uuid) { result, error in
                XCTAssert(result != nil, "getRoom() result is nil")
                XCTAssert(error == nil, "getRoom() returned error")
                XCTAssert(result?.time_created ?? 0 > 0, "getRoom() time_created is 0")

                self.api.deleteRoom(uuid) { result, error in
                    XCTAssert(result != nil, "createRoom() result is nil")
                    XCTAssert(error == nil, "createRoom() returned error")
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testGetActiveRooms() {
        let expectation = XCTestExpectation(description: "getActiveRooms API")
        api.getActiveRooms() { result, error in
            XCTAssert(result != nil, "getActiveRooms() result is nil")
            XCTAssert(error == nil, "getActiveRooms() returned error")
            XCTAssert(result?.count ?? 0 > 0 , "getActiveRooms() count is 0")
            for room in result! {
                let count = (room.experts ?? 0) + (room.customers ?? 0)
                XCTAssert(count > 0 , "getActiveRooms() user count is 0")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testGetAllRooms() {
        let expectation = XCTestExpectation(description: "getAllRooms API")
        api.getAllRooms() { result, error in
            XCTAssert(result != nil, "getAllRooms() result is nil")
            XCTAssert(error == nil, "getAllRooms() returned error")
            XCTAssert(result?.count ?? 0 > 0 , "getAllRooms() count is 0")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

//    func testAddUserToRoom() {
//        let expectation = XCTestExpectation(description: "addUserToRoom API")
//        let userId = self.customerId
//
//        api.createRoom() { result, error in
//            XCTAssert(result != nil, "createRoom() result is nil")
//            XCTAssert(error == nil, "createRoom() returned error")
//            let roomId = result!.uuid
//            self.api.addUser(userId, toRoom: roomId) { result, error in
//                XCTAssert(result != nil, "addUserToRoom() result is nil")
//                XCTAssert(error == nil, "addUserToRoom() returned error")
//                self.api.deleteRoom(roomId) { result, error in
//                    XCTAssert(result != nil, "createRoom() result is nil")
//                    XCTAssert(error == nil, "createRoom() returned error")
//                    expectation.fulfill()
//                }
//            }
//        }
//        wait(for: [expectation], timeout: 10.0)
//    }
//
//    func testRemoveUserFromRoom() {
//        let expectation = XCTestExpectation(description: "removeUserFromRoom API")
//        let userId = self.customerId
//        let roomId = self.roomId
//
//        self.api.addUser(userId, toRoom: roomId) { result, error in
//            XCTAssert(result != nil, "addUserToRoom() result is nil")
//            XCTAssert(error == nil, "addUserToRoom() returned error")
//
//            print("/api/removeUserFromRoom/\(userId)/\(roomId)")
//            self.api.removeUser(userId, fromRoom: roomId) { result, error in
//                XCTAssert(result != nil, "removeUserFromRoom() result is nil")
//                XCTAssert(error == nil, "removeUserFromRoom() returned error")
//                expectation.fulfill()
//            }
//        }
//
//        wait(for: [expectation], timeout: 10.0)
//    }
//
    
    func testCreateDeleteAnchor() {
        let expectation = XCTestExpectation(description: "createAnchor API")
        let anchor = AceAPI.Anchor(id: 0, uuid:"", url:"test.png", type:.image, name:"testImage")
        api.createAnchor(anchor) { result, error in
            XCTAssert(result != nil, "createAnchor() result is nil")
            XCTAssert(error == nil, "createAnchor() returned error")
            self.api.deleteAnchor(result!.uuid) { result, error in
                XCTAssert(result != nil, "deleteAnchor() result is nil")
                XCTAssert(error == nil, "deleteAnchor() returned error")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10.0)

    }
    
    func testGetAnchor() {
        let expectation = XCTestExpectation(description: "getAnchor API")
        self.api.getAnchor("demo_image_1") { result, error in
            XCTAssert(result != nil, "getAnchor() result is nil")
            XCTAssert(error == nil, "getAnchor() returned error")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testGetAllAnchors() {
        let expectation = XCTestExpectation(description: "getAllAnchors API")
        self.api.getAllAnchors() { result, error in
            XCTAssert(result != nil, "getAllAnchors() result is nil")
            XCTAssert(error == nil, "getAllAnchors() returned error")
            XCTAssert(result?.count ?? 0 > 0, "getAllAnchors() returned 0")
            expectation.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "getAllAnchors/:text API")
        self.api.getAllAnchors("dell") { result, error in
            XCTAssert(result != nil, "getAllAnchors() result is nil")
            XCTAssert(error == nil, "getAllAnchors() returned error")
            XCTAssert(result?.count ?? 0 == 1, "getAllAnchors() return not 1")
            expectation2.fulfill()
        }


        wait(for: [expectation, expectation2], timeout: 10.0)
    }

    func testCreateDeleteClip() {
        let expectation0 = XCTestExpectation(description: "createRoom API")
        var room:AceAPI.Room?
        var user:AceAPI.User?
        
        let newUser = AceAPI.User(id:0, uuid:"", type: .customer, name: "testUser", email: "test@fxpal.com", password: nil, photo_url:nil)
        self.api.createUser(newUser) { result, error in
            XCTAssert(result != nil, "createCustomer() result is nil")
            XCTAssert(error == nil, "createCustomer() returned error")
            user = result
            self.api.createRoom() { result, error in
                XCTAssert(result != nil, "createRoom() result is nil")
                XCTAssert(error == nil, "createRoom() returned error")
                room = result
                expectation0.fulfill()
            }
        }
        wait(for: [expectation0], timeout: 10.0)
                
        let expectation = XCTestExpectation(description: "createClip API")
        let clip = AceAPI.Clip(id: 0, uuid: "", name: "clip1", user_uuid: user!.uuid, room_uuid: room!.uuid, thumbnail_url: "thumb", webm_url: "web", mp4_url: "mp4")
        self.api.createClip(clip) { result, error in
            XCTAssert(result != nil, "createClip() result is nil")
            XCTAssert(error == nil, "createClip() returned error")
            let clipId = result!.uuid

            self.api.deleteClip(clipId) { result, error in
                XCTAssert(result != nil, "deleteClip() result is nil")
                XCTAssert(error == nil, "deleteClip() returned error")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
        
        // remove room and user
        self.api.deleteUser(user!.uuid) { result, error in }
        self.api.deleteRoom(room!.uuid) { result, error in }
        
    }

    func testGetClip() {
        let expectation = XCTestExpectation(description: "getClip API")
        self.api.getClip("549742011") { result, error in
            XCTAssert(result != nil, "getClip() result is nil")
            XCTAssert(error == nil, "getClip() returned error")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testGetClipForAnchor() {
        let expectation = XCTestExpectation(description: "getClipForAnchor API")
        self.api.getClips(forAnchor:"748691568") { result, error in
            XCTAssert(result != nil, "getClipForAnchor() result is nil")
            XCTAssert(error == nil, "getClipForAnchor() returned error")
            XCTAssert(result?.count ?? 0 > 0, "getClipForAnchor() return 0")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testGetAllClips() {
        let expectation = XCTestExpectation(description: "getAllClips API")
        self.api.getAllClips() { result, error in
            XCTAssert(result != nil, "getAllClips() result is nil")
            XCTAssert(error == nil, "getAllClips() returned error")
            XCTAssert(result?.count ?? 0 > 0, "getAllClips() return 0")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
//
//    func testAddRemoveClipToAnchor() {
//        let expectation = XCTestExpectation(description: "addClipToAnchor API")
//        let clipId = ""
//        let anchorId = ""
//        let blobPos = "{x:100,y:200,z:200}"
//
//        self.api.addClip(clipId, toAnchor:anchorId, blobPos:blobPos) { result, error in
//            XCTAssert(result != nil, "addClipToAnchor() result is nil")
//            XCTAssert(error == nil, "addClipToAnchor() returned error")
//
//            self.api.removeClip(clipId, fromAnchor:anchorId) { result, error in
//                XCTAssert(result != nil, "removeClipFromAnchor() result is nil")
//                XCTAssert(error == nil, "addClipToAnchor() returned error")
//                expectation.fulfill()
//            }
//        }
//
//        wait(for: [expectation], timeout: 10.0)
//    }

}
