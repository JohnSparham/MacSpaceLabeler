import AppKit

enum SpaceType {
    case desktop
    case fullscreen
}

struct SpaceInfo {
    let index: Int
    let managedSpaceID: UInt64
    let type: SpaceType
    let defaultLabel: String
}

final class SpaceManager {
    private let conn: Int32

    init() {
        conn = _CGSDefaultConnection()
    }

    func activeSpaceID() -> UInt64 {
        CGSGetActiveSpace(conn)
    }

    func allSpaces() -> [SpaceInfo] {
        guard let cfArray = CGSCopyManagedDisplaySpaces(conn) else { return [] }
        guard let displays = cfArray as? [[String: Any]] else { return [] }

        var raw: [(UInt64, SpaceType, String?)] = []
        for display in displays {
            guard let spaces = display["Spaces"] as? [[String: Any]] else { continue }
            for space in spaces {
                guard let sid = space["ManagedSpaceID"] as? UInt64,
                      let type = space["type"] as? Int else { continue }
                if type == 0 {
                    raw.append((sid, .desktop, nil))
                } else if type == 4 {
                    let pid = space["pid"] as? pid_t ?? 0
                    let appName = pid > 0 ? appNameForPID(pid) : "Fullscreen"
                    raw.append((sid, .fullscreen, appName))
                }
            }
        }

        var result: [SpaceInfo] = []
        var appCounts: [String: Int] = [:]
        for (i, (sid, stype, appName)) in raw.enumerated() {
            let idx = i + 1
            let defaultLabel: String
            if stype == .desktop {
                defaultLabel = "Space \(idx)"
            } else {
                let name = appName ?? "Fullscreen"
                appCounts[name, default: 0] += 1
                defaultLabel = "\(name) \(appCounts[name]!)"
            }
            result.append(SpaceInfo(index: idx, managedSpaceID: sid, type: stype, defaultLabel: defaultLabel))
        }
        return result
    }

    func currentSpaceIndex() -> Int? {
        let active = activeSpaceID()
        for space in allSpaces() {
            if space.managedSpaceID == active {
                return space.index
            }
        }
        return nil
    }

    private func appNameForPID(_ pid: pid_t) -> String {
        for app in NSWorkspace.shared.runningApplications {
            if app.processIdentifier == pid {
                return app.localizedName ?? "Fullscreen"
            }
        }
        return "Fullscreen"
    }
}
