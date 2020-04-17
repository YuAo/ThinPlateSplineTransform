import XCTest
import simd
@testable import ThinPlateSplineTransform

final class ThinPlateSplineTransformTests: XCTestCase {
    func testTPSInit() {
        let transform1 = TPSTransform(sourcePoints: [SIMD2<Float>(1,1)], targetPoints: [SIMD2<Float>(1,1)])
        XCTAssertNil(transform1)
        
        let transform2 = TPSTransform(sourcePoints: [SIMD2<Float>(1,1)], targetPoints: [SIMD2<Float>(2,2)])
        XCTAssertNil(transform2)
        
        let transform3 = TPSTransform(sourcePoints: [SIMD2<Float>(1,1), SIMD2<Float>(2,2)], targetPoints: [SIMD2<Float>(2,2), SIMD2<Float>(3,3)])
        XCTAssertNil(transform3)
        
        let transform4 = TPSTransform(sourcePoints: [SIMD2<Float>(1,1), SIMD2<Float>(2,2), SIMD2<Float>(3,3)], targetPoints: [SIMD2<Float>(2,2), SIMD2<Float>(3,3), SIMD2<Float>(4,3.5)])
        XCTAssertNil(transform4)
        
        let transform5 = TPSTransform(sourcePoints: [SIMD2<Float>(100,0), SIMD2<Float>(0,100), SIMD2<Float>(100,100), SIMD2<Float>(0,0)], targetPoints: [SIMD2<Float>(100,0), SIMD2<Float>(0,100), SIMD2<Float>(100,100), SIMD2<Float>(0,50)])
        XCTAssertNotNil(transform5)
    }
    
    func testTPS() {
        guard let transform = TPSTransform(sourcePoints: [
            SIMD2<Float>(100,0),
            SIMD2<Float>(0,100),
            SIMD2<Float>(100,100),
            SIMD2<Float>(0,0)
        ], targetPoints: [
            SIMD2<Float>(100,0),
            SIMD2<Float>(0,100),
            SIMD2<Float>(100,100),
            SIMD2<Float>(0,50)
        ]) else {
            XCTFail()
            return
        }
        do {
            let input =  SIMD2<Float>(100,100)
            let result = transform.apply(to: input)
            XCTAssert(distance(result, input) < 1)
        }
        do {
            let input =  SIMD2<Float>(0,100)
            let result = transform.apply(to: input)
            XCTAssert(distance(result, input) < 1)
        }
        do {
            let input =  SIMD2<Float>(100,0)
            let result = transform.apply(to: input)
            XCTAssert(distance(result, input) < 1)
        }
        do {
            let input =  SIMD2<Float>(0,0)
            let result = transform.apply(to: input)
            XCTAssert(distance(result, SIMD2<Float>(0, 50)) < 1)
        }
    }
}
