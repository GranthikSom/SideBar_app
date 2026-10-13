import Cocoa
import FlutterMacOS
import XCTest

class RunnerTests: XCTestCase {

  func testDefaultConfiguration() {
    let guardInstance = MouseGuard.shared
    XCTAssertEqual(guardInstance.inset, 1.0)
    XCTAssertTrue(guardInstance.guardTop)
    XCTAssertTrue(guardInstance.guardBottom)
    XCTAssertTrue(guardInstance.guardLeft)
    XCTAssertTrue(guardInstance.guardRight)
    XCTAssertFalse(guardInstance.guardInterDisplayBorders)
  }

  func testSingleDisplayEdgeClamping() {
    let guardInstance = MouseGuard.shared
    guardInstance.inset = 1.0
    guardInstance.guardTop = true
    guardInstance.guardBottom = true
    guardInstance.guardLeft = true
    guardInstance.guardRight = true

    let singleDisplay = [CGRect(x: 0, y: 0, width: 1920, height: 1080)]

    // Normal interior movement is unchanged
    let interior = guardInstance.clamp(point: CGPoint(x: 500, y: 500), displays: singleDisplay)
    XCTAssertEqual(interior, CGPoint(x: 500, y: 500))

    // Left edge (x = 0) is clamped to minX + 1.0 = 1.0
    let leftClamped = guardInstance.clamp(point: CGPoint(x: 0, y: 500), displays: singleDisplay)
    XCTAssertEqual(leftClamped, CGPoint(x: 1, y: 500))

    // Overshot left edge (x = -50) clamped to 1.0
    let leftOvershot = guardInstance.clamp(point: CGPoint(x: -50, y: 500), displays: singleDisplay)
    XCTAssertEqual(leftOvershot, CGPoint(x: 1, y: 500))

    // Right edge (x = 1920) is clamped to maxX - 1.0 = 1919.0
    let rightClamped = guardInstance.clamp(point: CGPoint(x: 1920, y: 500), displays: singleDisplay)
    XCTAssertEqual(rightClamped, CGPoint(x: 1919, y: 500))

    // Top edge (y = 0 in Core Graphics) clamped to minY + 1.0 = 1.0
    let topClamped = guardInstance.clamp(point: CGPoint(x: 500, y: 0), displays: singleDisplay)
    XCTAssertEqual(topClamped, CGPoint(x: 500, y: 1))

    // Bottom edge (y = 1080) clamped to maxY - 1.0 = 1079.0
    let bottomClamped = guardInstance.clamp(point: CGPoint(x: 500, y: 1080), displays: singleDisplay)
    XCTAssertEqual(bottomClamped, CGPoint(x: 500, y: 1079))
  }

  func testCustomInsetAndEdgeToggles() {
    let guardInstance = MouseGuard.shared
    let singleDisplay = [CGRect(x: 0, y: 0, width: 1920, height: 1080)]

    // Custom inset = 5.0
    guardInstance.inset = 5.0
    guardInstance.guardLeft = true
    let customInsetLeft = guardInstance.clamp(point: CGPoint(x: 0, y: 500), displays: singleDisplay)
    XCTAssertEqual(customInsetLeft, CGPoint(x: 5, y: 500))

    // Disable left guard -> edge not constrained
    guardInstance.guardLeft = false
    let unconstrainedLeft = guardInstance.clamp(point: CGPoint(x: 0, y: 500), displays: singleDisplay)
    XCTAssertEqual(unconstrainedLeft, CGPoint(x: 0, y: 500))

    // Restore defaults
    guardInstance.inset = 1.0
    guardInstance.guardLeft = true
  }

  func testMultiDisplayCrossingAndNegativeCoordinates() {
    let guardInstance = MouseGuard.shared
    guardInstance.inset = 1.0
    guardInstance.guardTop = true
    guardInstance.guardBottom = true
    guardInstance.guardLeft = true
    guardInstance.guardRight = true
    guardInstance.guardInterDisplayBorders = false

    // Two displays: Display 1 at (0, 0, 1440, 900), Display 2 at (1440, -106, 1920, 1080)
    let displays = [
      CGRect(x: 0, y: 0, width: 1440, height: 900),
      CGRect(x: 1440, y: -106, width: 1920, height: 1080)
    ]

    // 1. Exterior left of Display 1 is guarded
    let d1Left = guardInstance.clamp(point: CGPoint(x: 0, y: 400), displays: displays)
    XCTAssertEqual(d1Left, CGPoint(x: 1, y: 400))

    // 2. Interior crossing between Display 1 and Display 2 (x = 1440) is NOT blocked
    let crossingToD2 = guardInstance.clamp(point: CGPoint(x: 1440, y: 400), displays: displays)
    XCTAssertEqual(crossingToD2, CGPoint(x: 1440, y: 400))

    let insideD2 = guardInstance.clamp(point: CGPoint(x: 1445, y: 400), displays: displays)
    XCTAssertEqual(insideD2, CGPoint(x: 1445, y: 400))

    // 3. Exterior right of Display 2 (maxX = 1440 + 1920 = 3360) is guarded
    let d2Right = guardInstance.clamp(point: CGPoint(x: 3360, y: 400), displays: displays)
    XCTAssertEqual(d2Right, CGPoint(x: 3359, y: 400))

    // 4. Top of Display 2 has negative origin (minY = -106), clamped to -105.0
    let d2Top = guardInstance.clamp(point: CGPoint(x: 2000, y: -106), displays: displays)
    XCTAssertEqual(d2Top, CGPoint(x: 2000, y: -105))

    // 5. Bottom of Display 2 (maxY = -106 + 1080 = 974), clamped to 973.0
    let d2Bottom = guardInstance.clamp(point: CGPoint(x: 2000, y: 974), displays: displays)
    XCTAssertEqual(d2Bottom, CGPoint(x: 2000, y: 973))

    // 6. When guardInterDisplayBorders is true, seam between displays is also guarded
    guardInstance.guardInterDisplayBorders = true
    let seamGuarded = guardInstance.clamp(point: CGPoint(x: 1440, y: 400), displays: displays)
    XCTAssertEqual(seamGuarded, CGPoint(x: 1441, y: 400))

    // Reset
    guardInstance.guardInterDisplayBorders = false
  }

}
