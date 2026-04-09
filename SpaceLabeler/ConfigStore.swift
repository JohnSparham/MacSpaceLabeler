import Foundation

final class ConfigStore {
    private let configURL: URL
    private var labels: [String: String] = [:]

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("SpaceLabeler")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        configURL = dir.appendingPathComponent("config.json")
        migrateIfNeeded()
        load()
    }

    func getLabel(forIndex index: Int, default defaultLabel: String) -> String {
        labels[String(index)] ?? defaultLabel
    }

    func setLabel(forIndex index: Int, label: String) {
        labels[String(index)] = label
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: configURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stored = json["labels"] as? [String: String] else {
            labels = [:]
            return
        }
        labels = stored
    }

    private func save() {
        let json: [String: Any] = ["labels": labels]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else { return }
        try? data.write(to: configURL, options: .atomic)
    }

    private func migrateIfNeeded() {
        guard !FileManager.default.fileExists(atPath: configURL.path) else { return }
        // Try to migrate from Python prototype location
        let oldPath = NSHomeDirectory() + "/windowLabeler/config.json"
        if FileManager.default.fileExists(atPath: oldPath) {
            try? FileManager.default.copyItem(atPath: oldPath, toPath: configURL.path)
        }
    }
}
