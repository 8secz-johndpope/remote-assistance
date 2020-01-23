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
    var customerId:String = ""
    var expertId:String = ""

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let setServerURL = TSSetServerURL(serverUrl: "https://localhost:5443")
        store.ts.dispatch(setServerURL)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCreateCustomer() {
        let expectation = XCTestExpectation(description: "createCustomer API")
        api.createCustomer() { result, error in
            XCTAssert(result != nil, "createCustomer() result is nil")
            XCTAssert(error == nil, "createCustomer() returned error")
            self.customerId = result?.uuid ?? ""
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testCreateExpert() {
        let expectation = XCTestExpectation(description: "createExpert API")
        api.createCustomer() { result, error in
            XCTAssert(result != nil, "createExpert() result is nil")
            XCTAssert(error == nil, "createExpert() returned error")
            self.expertId = result?.uuid ?? ""
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetUser() {
        let expectation = XCTestExpectation(description: "getUser API")
        api.getUser("test5") { result, error in
            XCTAssert(result != nil, "getUser() result is nil")
            XCTAssert(error == nil, "getUser() returned error")
            XCTAssert(result?.id ?? 0 > 0, "getUser() id is invalid")
            expectation.fulfill()
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
    
    func testCreateRoom() {
        let expectation = XCTestExpectation(description: "createRoom API")
        api.createRoom() { result, error in
            XCTAssert(result != nil, "createRoom() result is nil")
            XCTAssert(error == nil, "createRoom() returned error")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetRoom() {
        let expectation = XCTestExpectation(description: "getRoom API")
        api.getRoom("test1") { result, error in
            XCTAssert(result != nil, "getRoom() result is nil")
            XCTAssert(error == nil, "getRoom() returned error")
            XCTAssert(result?.time_created ?? 0 > 0, "getRoom() time_created is 0")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetActiveRooms() {
        let expectation = XCTestExpectation(description: "getActiveRooms API")
        api.getActiveRooms() { result, error in
            XCTAssert(result != nil, "getActiveRooms() result is nil")
            XCTAssert(error == nil, "getActiveRooms() returned error")
            XCTAssert(result?.count ?? 0 > 0 , "getActiveRooms() count is 0")
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
    


}
