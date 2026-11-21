// Draws the Peekaboo icon: a violet rounded square, two eyes peeking over a light menu bar
// with a few icons, the line │ and the arrow ‹. Usage: swift scripts/make-icon.swift <out.iconset> [preview.png]
import AppKit

let out = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high

    // Background: the macOS icon grid leaves ~10% around the rounded square.
    let inset = s * 0.1
    let box = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let w = box.width
    let bg = NSBezierPath(roundedRect: box, xRadius: w * 0.225, yRadius: w * 0.225)
    NSGradient(starting: NSColor(srgbRed: 0.49, green: 0.40, blue: 1.00, alpha: 1),
               ending: NSColor(srgbRed: 0.27, green: 0.18, blue: 0.78, alpha: 1))!.draw(in: bg, angle: -90)

    NSGraphicsContext.saveGraphicsState()
    bg.addClip()

    // The menu bar the eyes peek over.
    let bar = NSRect(x: box.minX + w * 0.1, y: box.minY + w * 0.24, width: w * 0.8, height: w * 0.3)

    // Eyes first, the bar covers their lower part.
    let eyeW = w * 0.23, eyeH = w * 0.29
    let eyeY = bar.maxY - eyeH * 0.42
    for cx in [box.minX + w * 0.365, box.minX + w * 0.635] {
        let eye = NSRect(x: cx - eyeW / 2, y: eyeY, width: eyeW, height: eyeH)
        NSColor.white.setFill()
        NSBezierPath(ovalIn: eye).fill()
        // Pupils look to the left, toward the hidden icons.
        let p = w * 0.095
        let pupil = NSRect(x: eye.minX + eyeW * 0.12, y: eye.midY - p * 0.15, width: p, height: p)
        NSColor(srgbRed: 0.12, green: 0.09, blue: 0.30, alpha: 1).setFill()
        NSBezierPath(ovalIn: pupil).fill()
        let g = p * 0.32
        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: pupil.minX + p * 0.18, y: pupil.maxY - g - p * 0.14, width: g, height: g)).fill()
    }

    // The bar with a soft shadow on the eyes.
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: 0.28)
    shadow.shadowBlurRadius = w * 0.03
    shadow.shadowOffset = NSSize(width: 0, height: -w * 0.012)
    shadow.set()
    let barPath = NSBezierPath(roundedRect: bar, xRadius: w * 0.07, yRadius: w * 0.07)
    NSGradient(starting: NSColor(white: 1, alpha: 1), ending: NSColor(srgbRed: 0.90, green: 0.89, blue: 0.97, alpha: 1))!
        .draw(in: barPath, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // On the bar: three icons, the line │ and the arrow ‹.
    let midY = bar.midY
    let grey = NSColor(srgbRed: 0.62, green: 0.60, blue: 0.74, alpha: 1)
    let d = w * 0.085
    for i in 0..<3 {
        let x = bar.minX + w * 0.075 + CGFloat(i) * w * 0.125
        grey.setFill()
        NSBezierPath(roundedRect: NSRect(x: x, y: midY - d / 2, width: d, height: d), xRadius: d * 0.3, yRadius: d * 0.3).fill()
    }
    let violet = NSColor(srgbRed: 0.36, green: 0.26, blue: 0.90, alpha: 1)
    let lineX = bar.minX + w * 0.48
    violet.setFill()
    NSBezierPath(roundedRect: NSRect(x: lineX, y: midY - w * 0.075, width: w * 0.022, height: w * 0.15),
                 xRadius: w * 0.011, yRadius: w * 0.011).fill()
    let chevron = NSBezierPath()
    let cx = bar.maxX - w * 0.13, ch = w * 0.075
    chevron.move(to: NSPoint(x: cx + ch * 0.55, y: midY + ch))
    chevron.line(to: NSPoint(x: cx - ch * 0.45, y: midY))
    chevron.line(to: NSPoint(x: cx + ch * 0.55, y: midY - ch))
    chevron.lineWidth = w * 0.045
    chevron.lineCapStyle = .round
    chevron.lineJoinStyle = .round
    violet.setStroke()
    chevron.stroke()

    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for (name, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128), ("128x128@2x", 256),
                   ("256x256", 256), ("256x256@2x", 512), ("512x512", 512), ("512x512@2x", 1024)] {
    try! render(px).write(to: URL(fileURLWithPath: "\(out)/icon_\(name).png"))
}
if CommandLine.arguments.count > 2 {
    try! render(512).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
}
