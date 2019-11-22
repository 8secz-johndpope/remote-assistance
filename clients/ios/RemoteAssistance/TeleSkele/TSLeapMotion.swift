//
//  TSLeapMotion.swift
//  teleskele
//
//  Created by Yulius Tjahjadi on 10/25/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import Foundation



// See LeapMotion JSON Documentation for details
// https://developer-archive.leapmotion.com/documentation/javascript/supplements/Leap_JSON.html#version-6
struct LMGesture : Codable {

    enum GestureState : String, Codable {
        case start
        case update
        case stop
    }
    
    enum GestureType : String, Codable {
        case circle
        case swipe
        case keyTap
        case screenTap
    }

    let center: [Float]?
    let direction: [Float]?
    let duration: Int
    let handIds: [Int]
    let id: Int
    let normal: [Float]?
    let pointableIds: [Int]
    let position: [Float]?
    let progress: Float?
    let radius: Float?
    let speed: Float?
    let startPosition: [Float]?
    let state: GestureState
    let type: GestureType
}

struct LMPointable : Codable {
    
    enum PointableTouchZone : String, Codable {
        case none
        case hovering
        case touching
    }
    
    let bases: [[[Float]]]
    let btipPosition: [Float]
    let carpPosition: [Float]
    let dipPosition: [Float]
    let direction: [Float]
    let extended: Bool
    let handId: Int
    let id: Int
    let length: Float
    let mcpPosition: [Float]
    let pipPosition: [Float]
    let stabilizedTipPosition: [Float]
    let timeVisible: Float
    let tipPosition: [Float]
    let tipVelocity: [Float]
    let tool: Bool
    let touchDistance: Float
    let touchZone: PointableTouchZone
    let type: Int
    let width: Float
}

struct LMHand : Codable {
    
    enum HandType : String, Codable {
        case left
        case right
    }
    
    let armBasis: [[Float]]
    let armWidth: Float
    let confidence: Float
    let direction: [Float]
    let elbow: [Float]
    let grabStrength: Float
    let id: Int
    let palmNormal: [Float]
    let palmPosition: [Float]
    let palmVelocity: [Float]
    let pinchStrength: Float
    let r: [[Float]]
    let s: Float
    let sphereCenter: [Float]
    let sphereRadius: Float
    let stabilizedPalmPosition: [Float]
    let t: [Float]
    let timeVisible: Float
    let type: HandType
    let wrist: [Float]
}

struct LMBox : Codable {
    let center: [Float]
    let size: [Float]
}

struct LMFrame : Codable {
    let currentFrameRate: Float
    let id: Float
    let r: [[Float]]
    let s: Float
    let t: [Float]
    let timestamp: Float
    let gestures: [LMGesture]
    let hands: [LMHand]
    let interactionBox: LMBox
    let pointables: [LMPointable]
}

