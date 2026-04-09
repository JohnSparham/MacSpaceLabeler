import AppKit

final class HUDBanner {
    private let window: NSWindow
    private let label: NSTextField
    private var hideTimer: Timer?

    init() {
        let width: CGFloat = 400
        let height: CGFloat = 60
        let screen = NSScreen.main!
        let sx = screen.frame.width
        let sy = screen.frame.height
        let x = (sx - width) / 2
        let y = sy * 0.18

        window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let bg = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        bg.material = .hudWindow
        bg.blendingMode = .behindWindow
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 14
        bg.layer?.masksToBounds = true
        window.contentView?.addSubview(bg)

        label = NSTextField(frame: NSRect(x: 0, y: 0, width: width, height: height))
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = .center
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 28)
        window.contentView?.addSubview(label)
    }

    func show(text: String) {
        hideTimer?.invalidate()
        hideTimer = nil

        if let screen = NSScreen.main {
            let sx = screen.frame.width
            let sy = screen.frame.height
            let w = window.frame.width
            let h = window.frame.height
            window.setFrame(NSRect(x: (sx - w) / 2, y: sy * 0.18, width: w, height: h), display: false)
        }

        label.stringValue = text
        window.alphaValue = 1.0
        window.orderFrontRegardless()

        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.fadeOut()
        }
    }

    private func fadeOut() {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            window.animator().alphaValue = 0.0
        }
        hideTimer = nil
    }
}
