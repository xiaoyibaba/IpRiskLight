import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Bindable var monitor: RiskMonitor
    var onBack: () -> Void

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                Text("设置")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("ipdata.co API key", text: $monitor.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await monitor.refresh(manual: true) }
                    }
                Text("修改后回车立即重新检测")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Picker("检测间隔", selection: $monitor.intervalMinutes) {
                Text("5 分钟").tag(5)
                Text("10 分钟").tag(10)
                Text("30 分钟").tag(30)
                Text("60 分钟").tag(60)
            }
            .pickerStyle(.menu)

            Toggle("开机自启", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                        loginItemError = nil
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                        loginItemError = "设置失败:\(error.localizedDescription)"
                    }
                }
            if let loginItemError {
                Text(loginItemError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Text("免费额度 1500 次/天;10 分钟间隔约消耗 144 次/天。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
    }
}
