import Foundation
import IOKit.pwr_mgt

/// Holds a display-idle prevention assertion so the Mac does not lock while Active.
final class DisplayAssertion {
    private var assertionID: IOPMAssertionID = 0

    var isHeld: Bool { assertionID != 0 }

    func hold(reason: String = L("system.display_assertion")) {
        guard assertionID == 0 else { return }
        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &id
        )
        if result == kIOReturnSuccess {
            assertionID = id
        }
    }

    func release() {
        guard assertionID != 0 else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
    }

    deinit {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
        }
    }
}
