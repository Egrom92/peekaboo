// Draws the two README pictures: the right part of a menu bar with the icons shown (↓) and hidden (‹).
// Usage: swift scripts/make-demo.swift docs
import AppKit

let dir = CommandLine.arguments[1]
let W: CGFloat = 760, H: CGFloat = 44, scale: CGFloat = 2

let hiddenIcons = ["cloud", "music.note", "gamecontroller", "cup.and.saucer", "paperplane", "tray.and.arrow.up", "camera.viewfinder"]
let alwaysIcons = ["keyboard", "speaker.wave.2", "battery.75percent", "wifi"]

func symbol(_ name: String, size: CGFloat = 15, color: NSColor = .white) -> NSImage {
    let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .regular).applying(.init(paletteColors: [color]))
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)!.withSymbolConfiguration(cfg)!
}

func draw(_ img: NSImage, centerX: CGFloat, midY: CGFloat) {
    let s = img.size
    img.draw(in: NSRect(x: centerX - s.width / 2, y: midY - s.height / 2, width: s.width, height: s.height))
}

func render(shown: Bool) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W * scale), pixelsHigh: Int(H * scale), bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: W, height: H)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let bar = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: W, height: H), xRadius: 12, yRadius: 12)
    NSGradient(starting: NSColor(white: 0.20, alpha: 1), ending: NSColor(white: 0.13, alpha: 1))!.draw(in: bar, angle: -90)
    let midY = H / 2

    var x = W - 40
    let clock = NSAttributedString(string: "10:30", attributes: [.font: NSFont.systemFont(ofSize: 14, weight: .medium),
                                                                 .foregroundColor: NSColor.white])
    clock.draw(at: NSPoint(x: x - clock.size().width / 2, y: midY - clock.size().height / 2))
    x -= 46
    for name in alwaysIcons.reversed() {
        draw(symbol(name), centerX: x, midY: midY)
        x -= 34
    }
    // Peekaboo: the arrow, then the line, then what hides.
    let violet = NSColor(srgbRed: 0.62, green: 0.55, blue: 1, alpha: 1)
    draw(symbol(shown ? "chevron.down" : "chevron.left", size: 14, color: violet), centerX: x, midY: midY)
    x -= 26
    if shown {
        violet.setFill()
        NSBezierPath(roundedRect: NSRect(x: x - 1, y: midY - 8, width: 2, height: 16), xRadius: 1, yRadius: 1).fill()
        x -= 26
        let width = CGFloat(hiddenIcons.count) * 34 + 6
        NSColor(srgbRed: 0.55, green: 0.45, blue: 1, alpha: 0.18).setFill()
        NSBezierPath(roundedRect: NSRect(x: x - width + 20, y: 6, width: width, height: H - 12), xRadius: 9, yRadius: 9).fill()
        for name in hiddenIcons.reversed() {
            draw(symbol(name), centerX: x, midY: midY)
            x -= 34
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

try! render(shown: true).write(to: URL(fileURLWithPath: "\(dir)/shown.png"))
try! render(shown: false).write(to: URL(fileURLWithPath: "\(dir)/hidden.png"))
