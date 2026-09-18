import AppKit

let size = 1024
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("error: bitmap rep\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
    fputs("error: context\n", stderr)
    exit(1)
}
NSGraphicsContext.current = context

let sizeF = CGFloat(size)
let rect = CGRect(x: 0, y: 0, width: sizeF, height: sizeF)

let radius = sizeF * 0.225
let background = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
background.addClip()

let top = NSColor(calibratedRed: 1.00, green: 0.72, blue: 0.42, alpha: 1.0)
let bottom = NSColor(calibratedRed: 0.97, green: 0.44, blue: 0.60, alpha: 1.0)
NSGradient(starting: top, ending: bottom)?.draw(in: background, angle: -65)

let pointConfig = NSImage.SymbolConfiguration(pointSize: sizeF * 0.52, weight: .semibold)
let colorConfig = NSImage.SymbolConfiguration(hierarchicalColor: .white)
if let symbol = NSImage(systemSymbolName: "figure.cooldown", accessibilityDescription: nil)?
    .withSymbolConfiguration(pointConfig.applying(colorConfig)) {
    let s = symbol.size
    symbol.draw(
        at: NSPoint(x: (sizeF - s.width) / 2, y: (sizeF - s.height) / 2),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )
}

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fputs("error: png\n", stderr)
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: "work/icon-master.png"))
print("saved work/icon-master.png")
