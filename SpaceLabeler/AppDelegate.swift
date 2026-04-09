import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let spaceManager = SpaceManager()
    private let configStore = ConfigStore()
    private var hudBanner: HUDBanner!
    private var mcOverlay: MCOverlay!
    private var mcPollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        hudBanner = HUDBanner()
        mcOverlay = MCOverlay()

        // Menu bar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateTitle()
        rebuildMenu()

        // Space change notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceChanged(_:)),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Poll for Mission Control at 4Hz
        mcPollTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.pollMC()
        }

        // Request Accessibility on first launch
        _ = AccessibilityHelper.checkAndRequestPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mcPollTimer?.invalidate()
    }

    // MARK: - Space Change

    @objc private func spaceChanged(_ notification: Notification) {
        updateTitle()
        rebuildMenu()

        let active = spaceManager.activeSpaceID()
        for space in spaceManager.allSpaces() {
            if space.managedSpaceID == active {
                let label = configStore.getLabel(forIndex: space.index, default: space.defaultLabel)
                hudBanner.show(text: label)
                return
            }
        }
    }

    // MARK: - Mission Control Polling

    private func pollMC() {
        mcOverlay.poll(spaces: spaceManager.allSpaces(), configStore: configStore)
    }

    // MARK: - Menu Bar

    private func updateTitle() {
        let active = spaceManager.activeSpaceID()
        for space in spaceManager.allSpaces() {
            if space.managedSpaceID == active {
                statusItem.button?.title = configStore.getLabel(forIndex: space.index, default: space.defaultLabel)
                return
            }
        }
        statusItem.button?.title = "?"
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let header = NSMenuItem(title: "Space Labeler", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        for space in spaceManager.allSpaces() {
            let label = configStore.getLabel(forIndex: space.index, default: space.defaultLabel)
            let prefix = space.type == .desktop ? "Space \(space.index)" : "FS \(space.index)"
            let item = NSMenuItem(title: "\(prefix): \(label)", action: #selector(renameSpace(_:)), keyEquivalent: "")
            item.tag = space.index
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Start at Login toggle
        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLoginItem(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func renameSpace(_ sender: NSMenuItem) {
        let spaceIndex = sender.tag
        var defaultLabel = "Space \(spaceIndex)"
        for space in spaceManager.allSpaces() {
            if space.index == spaceIndex {
                defaultLabel = space.defaultLabel
                break
            }
        }
        let current = configStore.getLabel(forIndex: spaceIndex, default: defaultLabel)

        let alert = NSAlert()
        alert.messageText = "Rename Space \(spaceIndex)"
        alert.informativeText = "Enter a label for this space:"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        field.stringValue = current
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        if alert.runModal() == .alertFirstButtonReturn {
            let newLabel = field.stringValue
            if !newLabel.isEmpty {
                configStore.setLabel(forIndex: spaceIndex, label: newLabel)
                rebuildMenu()
                updateTitle()
            }
        }
    }

    @objc private func toggleLoginItem(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Login Item Error"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        rebuildMenu()
    }
}
