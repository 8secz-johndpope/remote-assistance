//
//  MathExtension.swift
//  teleskele
//
//  Created by Yulius Tjahjadi on 10/25/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import SceneKit
import SwifterSwift

extension SCNVector3 {
    init(_ v:[Float]) {
        self.init(x:v[0], y:v[1], z:v[2])
    }
    
    /// Vector in the same direction as this vector with a magnitude of 1
    var normalized:SCNVector3 {
        get {
            let localMagnitude = self.length
            let localX = x / localMagnitude
            let localY = y / localMagnitude
            let localZ = z / localMagnitude
            
            return SCNVector3(localX, localY, localZ)
        }
    }
    
    func dot(_ vectorB:SCNVector3) -> SCNFloat {
        return (x * vectorB.x) + (y * vectorB.y) + (z * vectorB.z)
    }
    
    func cross(_ vectorB:SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vectorB.z - z * vectorB.y, z * vectorB.x - x * vectorB.z, x * vectorB.y - y * vectorB.x)
    }
    
    var length2: SceneKitFloat {
        return pow(x, 2) + pow(y, 2) + pow(z, 2)
    }
}

extension SCNMatrix4 {
    
    mutating func lookAt(eye:SCNVector3, target:SCNVector3, up:SCNVector3) {
        var z = eye - target
        if z.length2 == 0 {
            z.z = 1
        }
        
        z = z.normalized
        var x = up.cross(z)
        if x.length2 == 0 {
            if (abs(up.z) == 1) {
                z.x += 0.0001
            } else {
                z.z += 0.0001
            }
            z = z.normalized
            x = up.cross(z)
        }
        
        x = x.normalized
        let y = z.cross(x)
       
        self.m11 = x.x
        self.m12 = x.y
        self.m13 = x.z

        self.m21 = y.x
        self.m22 = y.y
        self.m23 = y.z

        self.m31 = z.x
        self.m32 = z.y
        self.m33 = z.z
    }
}


extension SCNQuaternion {
    init(_ v:[Float]) {
        self.init(x:v[0], y:v[1], z:v[2], w:v[3])
    }

    mutating func setFromRotationMatrix(_ mat:SCNMatrix4) {
        let trace = mat.m11 + mat.m22 + mat.m33
        if trace > 0 {
            let s = 0.5/sqrt(trace + 1.0)
            self.w = 0.25 / s
            self.x = (mat.m23 - mat.m32) * s
            self.y = (mat.m31 - mat.m13) * s
            self.z = (mat.m12 - mat.m21) * s
        } else if mat.m11 > mat.m22 && mat.m11 > mat.m33 {
            let s = 2.0 * sqrt(1.0 + mat.m11 - mat.m22 - mat.m33)
            self.w = (mat.m23 - mat.m32) / s
            self.x = 0.25 * s
            self.y = (mat.m21 + mat.m12) / s
            self.z = (mat.m31 + mat.m13) / s
        } else if mat.m22 > mat.m33 {
            let s = 2.0 * sqrt(1.0 + mat.m22 - mat.m11 - mat.m33)
            self.w = (mat.m31 - mat.m13) / s
            self.x = (mat.m21 + mat.m12) / s
            self.y = 0.25 * s
            self.z = (mat.m32 + mat.m23) / s
        } else {
            let s = 2.0 * sqrt(1.0 + mat.m33 - mat.m11 - mat.m22)
            self.w = (mat.m12 - mat.m21) / s
            self.x = (mat.m31 + mat.m13) / s
            self.y = (mat.m32 + mat.m23) / s
            self.z = 0.25 * s
        }
    }
    
    func inverse() -> SCNQuaternion {
        return SCNQuaternion(
            self.x * -1,
            self.y * -1,
            self.z * -1,
            self.w)
    }
    
    func multiplyQuaternions(_ a:SCNQuaternion, _ b:SCNQuaternion) -> SCNQuaternion {

        // from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm

        let qax = a.x, qay = a.y, qaz = a.z, qaw = a.w
        let qbx = b.x, qby = b.y, qbz = b.z, qbw = b.w

        return SCNQuaternion(
            qax * qbw + qaw * qbx + qay * qbz - qaz * qby,
            qay * qbw + qaw * qby + qaz * qbx - qax * qbz,
            qaz * qbw + qaw * qbz + qax * qby - qay * qbx,
            qaw * qbw - qax * qbx - qay * qby - qaz * qbz)
    }
    
    func multiply(_ a:SCNQuaternion) -> SCNQuaternion {
        return self.multiplyQuaternions(self, a)
    }
}
