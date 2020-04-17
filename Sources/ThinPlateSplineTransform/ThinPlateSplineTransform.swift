//
//  File.swift
//  
//
//  Created by Yu Ao on 2020/4/17.
//

import Foundation
import ThinPlateSplineTransformCore
import simd

public final class TPSTransform {
    private let t: ThinPlateSplineTransformRef
    
    deinit {
        ThinPlateSplineTransformRelease(t)
    }
    
    public init?(sourcePoints: [SIMD2<Float>], targetPoints: [SIMD2<Float>], regularizationParameter: Float = 0) {
        assert(sourcePoints.count == targetPoints.count)
        if let transform = ThinPlateSplineTransformCreate(sourcePoints, targetPoints, sourcePoints.count, regularizationParameter) {
            t = transform
        } else {
            return nil
        }
    }
    
    public func apply(to point: SIMD2<Float>) -> SIMD2<Float> {
        return ThinPlateSplineTransformApplyToPoint(t, point)
    }
}

extension TPSTransform {
    public func apply(to points: [SIMD2<Float>]) -> [SIMD2<Float>] {
        var output = points
        for (index, point) in points.enumerated() {
            output[index] = ThinPlateSplineTransformApplyToPoint(t, point)
        }
        return output
    }
}

#if canImport(CoreGraphics)
import CoreGraphics

extension TPSTransform {
    public func apply(to point: CGPoint) -> CGPoint {
        let r = ThinPlateSplineTransformApplyToPoint(t, SIMD2<Float>(Float(point.x), Float(point.y)))
        return CGPoint(x: CGFloat(r.x), y: CGFloat(r.y))
    }
    
    public func apply(to points: [CGPoint]) -> [CGPoint] {
        var output = points
        for (index, point) in points.enumerated() {
            let r = ThinPlateSplineTransformApplyToPoint(t, SIMD2<Float>(Float(point.x), Float(point.y)))
            output[index].x = CGFloat(r.x)
            output[index].y = CGFloat(r.y)
        }
        return output
    }
}

#endif
