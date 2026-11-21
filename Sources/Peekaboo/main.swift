import AppKit
import ServiceManagement

/// Hides part of the menu bar. Two items of our own: the arrow (← hidden, ↓ shown) and a thin line │ to its left.
/// Everything to the left of the line hides: the line grows to 10 000 points and pushes those icons off the screen.
/// Icons are moved with the macOS way: hold ⌘ and drag.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var toggle: NSStatusItem!
    private var separator: NSStatusItem!
    private var expanded = true
    private var autoHideTimer: Timer?

    private let hiddenLength: CGFloat = 10_000
    private let lineLength: CGFloat = 14

    /// Seconds after which the icons hide again by themselves; 0 — only by the arrow.
    private var autoHide: Int {
        get { UserDefaults.standard.integer(forKey: "autoHide") }
        set { UserDefaults.standard.set(newValue, forKey: "autoHide") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--unregister-login") {   // used by uninstall.sh
            try? SMAppService.mainApp.unregister()
            NSApp.terminate(nil)
            return
        }
        // The arrow first: a newer item appears to the left of older ones, so the line lands left of the arrow.
        toggle = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        toggle.autosaveName = "peekaboo.toggle"
        toggle.behavior = []   // ⌘-dragging it out of the bar must not remove it
        separator = NSStatusBar.system.statusItem(withLength: lineLength)
        separator.autosaveName = "peekaboo.separator"
        separator.behavior = []
        for item in [toggle!, separator!] {
            item.button?.target = self
            item.button?.action = #selector(clicked(_:))
            item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        toggle.button?.toolTip = "Peekaboo: щелчок — показать или скрыть значки, правый щелчок — меню"
        separator.button?.toolTip = "Значки левее этой черты прячутся. Перетаскивайте значки с зажатой ⌘"
        enableLoginItemOnce()
        render()
        if !UserDefaults.standard.bool(forKey: "introShown") {
            UserDefaults.standard.set(true, forKey: "introShown")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.showHelp() }   // stays open to arrange icons
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.setExpanded(false, quietly: true) }
        }
    }

    // MARK: showing and hiding

    @objc private func clicked(_ sender: NSStatusBarButton) {
        let e = NSApp.currentEvent
        if e?.type == .rightMouseUp || e?.modifierFlags.contains(.control) == true || e?.modifierFlags.contains(.option) == true
            || sender == separator.button {
            showMenu(from: sender == separator.button ? separator : toggle)
        } else {
            setExpanded(!expanded)
        }
    }

    private func setExpanded(_ show: Bool, quietly: Bool = false) {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        if !show && !lineIsLeftOfArrow {
            // Hiding now would push the arrow itself off the screen, and there'd be nothing to click to bring it back.
            if !quietly { warnOrder() }
            expanded = true
            render()
            return
        }
        expanded = show
        render()
        if show && autoHide > 0 { scheduleAutoHide(after: TimeInterval(autoHide)) }
    }

    private func scheduleAutoHide(after seconds: TimeInterval) {
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.expanded else { return }
                // The pointer is still up in the menu bar: wait a bit more.
                let p = NSEvent.mouseLocation
                if let screen = NSScreen.screens.first(where: { $0.frame.contains(p) }),
                   p.y > screen.frame.maxY - NSStatusBar.system.thickness - 4 {
                    self.scheduleAutoHide(after: 3)
                } else {
                    self.setExpanded(false, quietly: true)
                }
            }
        }
    }

    private var lineIsLeftOfArrow: Bool {
        guard expanded || separator.length < hiddenLength,
              let line = separator.button?.window?.frame, let arrow = toggle.button?.window?.frame else { return true }
        return line.midX < arrow.midX
    }

    private func render() {
        let arrow = NSImage(systemSymbolName: expanded ? "chevron.down" : "chevron.left",
                            accessibilityDescription: expanded ? "Скрыть значки" : "Показать значки")
        arrow?.isTemplate = true
        toggle.button?.image = arrow
        separator.length = expanded ? lineLength : hiddenLength
        separator.button?.image = expanded ? Self.line : nil
    }

    /// A thin vertical line, drawn in the menu bar's text color.
    private static let line: NSImage = {
        let img = NSImage(size: NSSize(width: 6, height: 16), flipped: false) { r in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: NSRect(x: r.midX - 0.75, y: 1, width: 1.5, height: r.height - 2), xRadius: 0.75, yRadius: 0.75).fill()
            return true
        }
        img.isTemplate = true
        return img
    }()

    // MARK: menu

    private func showMenu(from item: NSStatusItem) {
        let menu = NSMenu()
        let flip = NSMenuItem(title: expanded ? "Скрыть значки" : "Показать значки", action: #selector(flipFromMenu), keyEquivalent: "")
        flip.target = self
        menu.addItem(flip)
        let auto = NSMenuItem(title: "Скрывать само", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for (title, sec) in [("Нет, только стрелкой", 0), ("Через 10 секунд", 10), ("Через 30 секунд", 30), ("Через минуту", 60)] {
            let i = NSMenuItem(title: title, action: #selector(pickAutoHide(_:)), keyEquivalent: "")
            i.target = self
            i.tag = sec
            i.state = autoHide == sec ? .on : .off
            sub.addItem(i)
        }
        auto.submenu = sub
        menu.addItem(auto)
        menu.addItem(.separator())
        let help = NSMenuItem(title: "Как переставлять значки…", action: #selector(showHelp), keyEquivalent: "")
        help.target = self
        menu.addItem(help)
        let login = NSMenuItem(title: "Запускать при входе в систему", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(NSMenuItem(title: "Выйти", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        item.button?.performClick(nil)   // opens the menu under the item
        item.menu = nil                  // so that the next left click toggles again
    }

    @objc private func flipFromMenu() { setExpanded(!expanded) }

    @objc private func pickAutoHide(_ sender: NSMenuItem) {
        autoHide = sender.tag
        if expanded && autoHide > 0 { scheduleAutoHide(after: TimeInterval(autoHide)) }
    }

    @objc private func showHelp() {
        setExpanded(true)
        autoHideTimer?.invalidate()
        let a = NSAlert()
        a.messageText = "Как пользоваться Peekaboo"
        let text = NSTextField(wrappingLabelWithString: """
            В строке меню две метки Peekaboo: стрелка и тонкая черта │ слева от неё.

            • Значки левее черты прячутся. Значки между чертой и стрелкой видны всегда.

            • Чтобы переставить значок, зажмите ⌘ и перетащите его мышью. Так же двигаются сама черта и стрелка.

            • Стрелка ← — значки скрыты, щелчок их показывает. Стрелка ↓ — значки видны, щелчок прячет.

            • Правый щелчок по стрелке или щелчок по черте — меню: прятать само через время, запуск при входе.

            Сейчас все значки показаны: расставьте их, потом нажмите на стрелку.
            """)
        text.alignment = .left
        text.preferredMaxLayoutWidth = 360
        text.frame.size = text.fittingSize
        a.accessoryView = text
        NSApp.activate()
        a.runModal()
    }

    private func warnOrder() {
        let a = NSAlert()
        a.messageText = "Черта │ стоит правее стрелки"
        a.informativeText = "Если сейчас спрятать значки, спрячется и сама стрелка. Зажмите ⌘ и перетащите черту левее стрелки, потом нажмите на стрелку ещё раз."
        NSApp.activate()
        a.runModal()
    }

    @objc private func toggleLogin() {
        if SMAppService.mainApp.status == .enabled { try? SMAppService.mainApp.unregister() } else { try? SMAppService.mainApp.register() }
    }

    private func enableLoginItemOnce() {
        let path = Bundle.main.bundlePath
        guard path.hasPrefix("/Applications/") || path.hasPrefix(NSHomeDirectory() + "/Applications/"),
              !UserDefaults.standard.bool(forKey: "loginItemConfigured") else { return }
        if (try? SMAppService.mainApp.register()) != nil { UserDefaults.standard.set(true, forKey: "loginItemConfigured") }
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { app.run() }
}
