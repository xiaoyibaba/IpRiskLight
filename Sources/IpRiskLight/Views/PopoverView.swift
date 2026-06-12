import SwiftUI

struct PopoverView: View {
    @Bindable var monitor: RiskMonitor
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            if showSettings {
                SettingsView(monitor: monitor) { showSettings = false }
            } else if monitor.apiKey.isEmpty {
                OnboardingView(monitor: monitor)
            } else {
                InfoView(monitor: monitor)
            }
            Divider()
            footer
        }
        .frame(width: 320)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let date = monitor.lastUpdated {
                Text("更新于 \(date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if monitor.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button {
                    Task { await monitor.refresh(manual: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(monitor.apiKey.isEmpty)
                .help("立即刷新")
            }
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: showSettings ? "info.circle" : "gearshape")
            }
            .buttonStyle(.borderless)
            .help(showSettings ? "返回详情" : "设置")
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("退出")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// 未配置 API key 时的引导页。
private struct OnboardingView: View {
    @Bindable var monitor: RiskMonitor
    @State private var keyInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("欢迎使用 IpRiskLight", systemImage: "shield.lefthalf.filled")
                .font(.headline)
            Text("本应用通过 ipdata.co 检测当前出口 IP 的风险。请先注册免费账号获取 API key(每天 1500 次免费额度)。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Link("前往 ipdata.co 注册 →", destination: URL(string: "https://ipdata.co/sign-up.html")!)
                .font(.callout)
            TextField("粘贴 API key", text: $keyInput)
                .textFieldStyle(.roundedBorder)
                .onSubmit(save)
            Button("保存并检测", action: save)
                .buttonStyle(.borderedProminent)
                .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
    }

    private func save() {
        let key = keyInput.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        monitor.apiKey = key
        Task { await monitor.refresh(manual: true) }
    }
}

/// 检测结果详情页。
private struct InfoView: View {
    let monitor: RiskMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let message = monitor.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let result = monitor.result {
                detail(result)
            } else if monitor.errorMessage == nil {
                Text(monitor.isRefreshing ? "正在检测…" : "等待首次检测…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(monitor.riskLevel.color)
                .frame(width: 14, height: 14)
            Text(monitor.riskLevel.title)
                .font(.title3.bold())
            Spacer()
            if let ip = monitor.result?.ip {
                Text(ip)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }

    @ViewBuilder
    private func detail(_ result: IPDataResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            row(icon: "mappin.and.ellipse", text: result.locationText)
            if let asn = result.asn, let name = asn.name {
                row(icon: "network", text: [name, asn.asn].compactMap { $0 }.joined(separator: " · "))
            }
        }

        if let scores = result.threat?.scores {
            Divider()
            VStack(spacing: 6) {
                scoreRow("威胁分数", scores.threatScore, highIsBad: true)
                scoreRow("VPN 分数", scores.vpnScore, highIsBad: true)
                scoreRow("代理分数", scores.proxyScore, highIsBad: true)
                scoreRow("信任分数", scores.trustScore, highIsBad: false)
            }
        }

        if let threat = result.threat {
            Divider()
            let flags = threat.activeFlags
            if flags.isEmpty {
                Label("未发现风险标志", systemImage: "checkmark.shield")
                    .font(.callout)
                    .foregroundStyle(.green)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(flags, id: \.self) { flag in
                        Label(flag, systemImage: "exclamationmark.shield.fill")
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private func row(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(text)
                .font(.callout)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func scoreRow(_ title: String, _ score: Double?, highIsBad: Bool) -> some View {
        if let score {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)
                ProgressView(value: min(max(score, 0), 100), total: 100)
                    .tint(scoreColor(score, highIsBad: highIsBad))
                Text(String(format: "%.0f", score))
                    .font(.caption.monospacedDigit())
                    .frame(width: 28, alignment: .trailing)
            }
        }
    }

    private func scoreColor(_ score: Double, highIsBad: Bool) -> Color {
        let bad = highIsBad ? score : 100 - score
        switch bad {
        case ..<30: return .green
        case ..<60: return .yellow
        default: return .red
        }
    }
}
