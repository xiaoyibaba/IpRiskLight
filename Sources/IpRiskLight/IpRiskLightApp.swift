import SwiftUI

@main
struct IpRiskLightApp: App {
    @State private var monitor: RiskMonitor

    init() {
        // swift run 等无 bundle 场景下也不显示 Dock 图标(.app 内由 LSUIElement 保证)
        NSApplication.shared.setActivationPolicy(.accessory)
        let monitor = RiskMonitor()
        monitor.start()
        _monitor = State(initialValue: monitor)
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(monitor: monitor)
        } label: {
            StatusIconView(level: monitor.riskLevel, dotLit: monitor.dotLit)
        }
        .menuBarExtraStyle(.window)
    }
}
