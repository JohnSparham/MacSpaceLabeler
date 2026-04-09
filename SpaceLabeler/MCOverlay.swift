import AppKit

final class MCOverlay {
    private var overlayWindows: [(NSWindow, NSTextField)] = []
    private var mcVisible = false

    func poll(spaces: [SpaceInfo], configStore: ConfigStore) {
        guard let buttons = AccessibilityHelper.getMCSpaceButtons() else {
            if mcVisible {
                mcVisible = false
                hideOverlays()
            }
            return
        }

        if !mcVisible {
            mcVisible = true
            showOverlays(buttons: buttons, spaces: spaces, configStore: configStore)
        } else {
            updatePositions(buttons: buttons)
        }
    }

    private func showOverlays(buttons: [CGRect], spaces: [SpaceInfo], configStore: ConfigStore) {
        hideOverlays()
        guard let screen = NSScreen.main else { return }
        let screenH = screen.frame.height

        for (i, btnRect) in buttons.enumerated() {
            guard i < spaces.count else { break }
            let space = spaces[i]
            let labelText = configStore.getLabel(forIndex: space.index, default: space.defaultLabel)

            let ow = btnRect.width
            let oh: CGFloat = 16
            let ox = btnRect.origin.x
            // AX coords are top-left origin; AppKit is bottom-left
            let oy = screenH - (btnRect.origin.y + btnRect.height + oh + 2)

            let win = NSWindow(
                contentRect: NSRect(x: ox, y: oy, width: ow, height: oh),
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
            win.isOpaque = false
            win.backgroundColor = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0.85)
            win.ignoresMouseEvents = true
            win.collectionBehavior = [.canJoinAllSpaces, .stationary]
            win.contentView?.wantsLayer = true
            win.contentView?.layer?.cornerRadius = 4
            win.contentView?.layer?.masksToBounds = true

            let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: ow, height: oh))
            tf.isBezeled = false
            tf.drawsBackground = false
            tf.isEditable = false
            tf.isSelectable = false
            tf.alignment = .center
            tf.textColor = .white
            tf.font = .boldSystemFont(ofSize: 10)
            tf.stringValue = labelText
            win.contentView?.addSubview(tf)

            win.orderFrontRegardless()
            overlayWindows.append((win, tf))
        }
    }

    private func updatePositions(buttons: [CGRect]) {
        guard let screen = NSScreen.main else { return }
        let screenH = screen.frame.height

        for (i, (win, _)) in overlayWindows.enumerated() {
            guard i < buttons.count else { break }
            let btn = buttons[i]
            let ow = btn.width
            let oh = win.frame.height
            let ox = btn.origin.x
            let oy = screenH - (btn.origin.y + btn.height + oh + 2)
            win.setFrame(NSRect(x: ox, y: oy, width: ow, height: oh), display: true)
        }
    }

    private func hideOverlays() {
        for (win, _) in overlayWindows {
            win.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}
