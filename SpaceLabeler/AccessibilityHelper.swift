import AppKit
import ApplicationServices

final class AccessibilityHelper {

    static func checkAndRequestPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    /// Returns the bounding rects of each space button in the Mission Control Spaces Bar,
    /// or nil if Mission Control is not open or Accessibility is not granted.
    static func getMCSpaceButtons() -> [CGRect]? {
        guard isAccessibilityGranted() else { return nil }

        guard let dockPID = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.processIdentifier else {
            return nil
        }

        let dockApp = AXUIElementCreateApplication(dockPID)
        guard let dockChildren = getChildren(of: dockApp) else { return nil }

        for child in dockChildren {
            guard getStringAttribute(child, name: kAXTitleAttribute) == "Mission Control" else { continue }
            guard let mcChildren = getChildren(of: child) else { continue }
            for sub in mcChildren {
                guard let sub2Children = getChildren(of: sub) else { continue }
                for sub2 in sub2Children {
                    guard getStringAttribute(sub2, name: kAXTitleAttribute) == "Spaces Bar" else { continue }
                    guard let listChildren = getChildren(of: sub2) else { continue }
                    for list in listChildren {
                        guard let buttons = getChildren(of: list) else { continue }
                        var rects: [CGRect] = []
                        for btn in buttons {
                            guard let pos = getPointAttribute(btn, name: kAXPositionAttribute),
                                  let size = getSizeAttribute(btn, name: kAXSizeAttribute) else { continue }
                            rects.append(CGRect(origin: pos, size: size))
                        }
                        if !rects.isEmpty { return rects }
                    }
                }
            }
        }
        return nil
    }

    // MARK: - AX Helpers

    private static func getChildren(of element: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value)
        guard err == .success, let children = value as? [AXUIElement] else { return nil }
        return children
    }

    private static func getStringAttribute(_ element: AXUIElement, name: String) -> String? {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard err == .success, let str = value as? String else { return nil }
        return str
    }

    private static func getPointAttribute(_ element: AXUIElement, name: String) -> CGPoint? {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard err == .success, let axValue = value, CFGetTypeID(axValue) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        AXValueGetValue(axValue as! AXValue, .cgPoint, &point)
        return point
    }

    private static func getSizeAttribute(_ element: AXUIElement, name: String) -> CGSize? {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard err == .success, let axValue = value, CFGetTypeID(axValue) == AXValueGetTypeID() else { return nil }
        var size = CGSize.zero
        AXValueGetValue(axValue as! AXValue, .cgSize, &size)
        return size
    }
}
