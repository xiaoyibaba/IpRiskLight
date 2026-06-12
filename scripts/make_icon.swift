#!/usr/bin/env swift
// 生成 AppIcon:macOS 风格圆角方块 + 盾牌 + 风险圆点。
// 用法: swift scripts/make_icon.swift  → 产出 Resources/AppIcon.icns
import AppKit

func drawIcon(canvas: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: canvas, height: canvas), flipped: false) { _ in
        // macOS 图标规范:内容区约占画布 80%,四周留透明边距
        let inset = canvas * 0.1
        let rect = NSRect(x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)
        let radius = rect.width * 0.2237

        let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        NSGradient(
            starting: NSColor(calibratedRed: 0.20, green: 0.45, blue: 0.95, alpha: 1),
            ending: NSColor(calibratedRed: 0.10, green: 0.22, blue: 0.55, alpha: 1)
        )!.draw(in: squircle, angle: -90)

        // 白色盾牌
        let config = NSImage.SymbolConfiguration(pointSize: rect.width * 0.52, weight: .medium)
        if let shield = NSImage(systemSymbolName: "shield.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) {
            let tinted = NSImage(size: shield.size, flipped: false) { r in
                shield.draw(in: r)
                NSColor.white.set()
                r.fill(using: .sourceAtop)
                return true
            }
            let origin = NSPoint(
                x: rect.midX - tinted.size.width / 2,
                y: rect.midY - tinted.size.height / 2
            )
            tinted.draw(in: NSRect(origin: origin, size: tinted.size))
        }

        // 右下角绿色状态圆点(白描边)
        let dotDiameter = rect.width * 0.30
        let dotRect = NSRect(
            x: rect.maxX - dotDiameter * 0.92,
            y: rect.minY - dotDiameter * 0.08,
            width: dotDiameter,
            height: dotDiameter
        )
        let dot = NSBezierPath(ovalIn: dotRect)
        NSColor(calibratedRed: 0.22, green: 0.78, blue: 0.35, alpha: 1).setFill()
        dot.fill()
        NSColor.white.setStroke()
        dot.lineWidth = dotDiameter * 0.09
        dot.stroke()
        return true
    }
}

func writePNG(_ image: NSImage, pixels: Int, to url: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconset = root.appendingPathComponent("Resources/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    writePNG(drawIcon(canvas: CGFloat(base)), pixels: base,
             to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    writePNG(drawIcon(canvas: CGFloat(base * 2)), pixels: base * 2,
             to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o",
                  root.appendingPathComponent("Resources/AppIcon.icns").path]
try! task.run()
task.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
print(task.terminationStatus == 0 ? "✅ Resources/AppIcon.icns 已生成" : "❌ iconutil 失败")
