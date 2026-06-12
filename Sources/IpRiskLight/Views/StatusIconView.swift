import AppKit
import SwiftUI

/// 状态栏图标:盾牌 + 右下角风险色圆点,圆点每 3 秒闪烁一次。
/// 圆点需要真实颜色,所以整张图 isTemplate = false,
/// 盾牌颜色根据菜单栏明暗(colorScheme)手动适配。
struct StatusIconView: View {
    @Environment(\.colorScheme) private var colorScheme
    let level: RiskLevel
    let dotLit: Bool

    var body: some View {
        Image(nsImage: Self.render(level: level, dark: colorScheme == .dark, dotLit: dotLit))
    }

    static func render(level: RiskLevel, dark: Bool, dotLit: Bool) -> NSImage {
        let size = NSSize(width: 20, height: 18)
        let dotColor = level.nsColor
        let shieldColor: NSColor = dark ? .white : .black
        let image = NSImage(size: size, flipped: false) { rect in
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            if let shield = NSImage(systemSymbolName: "shield.fill", accessibilityDescription: "IP 风险")?
                .withSymbolConfiguration(config) {
                let tinted = shield.tinted(with: shieldColor.withAlphaComponent(0.85))
                let origin = NSPoint(
                    x: (rect.width - tinted.size.width) / 2 - 2,
                    y: (rect.height - tinted.size.height) / 2
                )
                tinted.draw(in: NSRect(origin: origin, size: tinted.size))
            }
            let dotDiameter: CGFloat = 7.5
            let dotRect = NSRect(
                x: rect.maxX - dotDiameter - 0.5,
                y: 0.5,
                width: dotDiameter,
                height: dotDiameter
            )
            // 闪烁的"暗"相位:圆点降为低透明度,看起来是规律的明灭而非消失
            dotColor.withAlphaComponent(dotLit ? 1.0 : 0.2).setFill()
            NSBezierPath(ovalIn: dotRect).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            self.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}
