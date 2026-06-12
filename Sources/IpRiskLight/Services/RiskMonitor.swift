import Foundation
import Network
import Observation

/// 核心状态机:持有最近一次检测结果,按设置间隔轮询,网络变化时立即触发。
@MainActor
@Observable
final class RiskMonitor {
    private static let apiKeyKey = "apiKey"
    private static let intervalKey = "intervalMinutes"

    private(set) var result: IPDataResponse?
    private(set) var errorMessage: String?
    private(set) var lastUpdated: Date?
    private(set) var isRefreshing = false
    /// 状态栏圆点闪烁相位:false 为短暂的"暗"相位。
    /// 由 monitor 驱动而非图标视图自身,因为 MenuBarExtra 的 label 不触发 .task/.onAppear。
    private(set) var dotLit = true

    var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: Self.apiKeyKey) }
    }

    var intervalMinutes: Int {
        didSet {
            UserDefaults.standard.set(intervalMinutes, forKey: Self.intervalKey)
            restartTimer()
        }
    }

    var riskLevel: RiskLevel {
        if errorMessage != nil || result == nil { return .unknown }
        return RiskLevel.evaluate(result?.threat)
    }

    private let service = IPDataService()
    private let notifications = NotificationService()
    private var timer: Timer?
    private let pathMonitor = NWPathMonitor()
    private var lastNetworkSignature: String?
    private var debounceTask: Task<Void, Never>?
    private var blinkTask: Task<Void, Never>?
    private var quotaExhaustedDate: Date?
    private var started = false

    init() {
        apiKey = UserDefaults.standard.string(forKey: Self.apiKeyKey) ?? ""
        let stored = UserDefaults.standard.integer(forKey: Self.intervalKey)
        intervalMinutes = stored > 0 ? stored : 10
    }

    func start() {
        guard !started else { return }
        started = true
        restartTimer()
        startPathMonitor()
        startBlinking()
        notifications.requestAuthorization()
        Task { await refresh() }
    }

    /// 每 3 秒闪烁一次:暗 0.35 秒后恢复。
    private func startBlinking() {
        blinkTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.65))
                guard let self else { break }
                self.dotLit = false
                try? await Task.sleep(for: .milliseconds(350))
                self.dotLit = true
            }
        }
    }

    /// manual = true 表示用户点击"立即刷新",不受当日超额熔断限制。
    func refresh(manual: Bool = false) async {
        guard !isRefreshing, !apiKey.isEmpty else { return }
        if !manual, let date = quotaExhaustedDate, Calendar.current.isDateInToday(date) {
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let response = try await service.fetch(apiKey: apiKey)
            for notice in NotificationPlanner.plan(previous: result, new: response) {
                notifications.send(notice)
            }
            result = response
            lastUpdated = Date()
            errorMessage = nil
            quotaExhaustedDate = nil
        } catch let error as IPDataService.ServiceError {
            if case .quotaExceeded = error {
                quotaExhaustedDate = Date()
            }
            errorMessage = error.errorDescription
        } catch let error as URLError {
            errorMessage = "网络错误:\(error.localizedDescription)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        let interval = TimeInterval(intervalMinutes * 60)
        let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
        // .common 模式保证弹窗打开时定时器照常触发
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func startPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let signature = path.status == .satisfied
                ? "up:" + path.availableInterfaces.map(\.name).joined(separator: ",")
                : "down"
            Task { @MainActor in self?.handleNetworkChange(signature: signature) }
        }
        pathMonitor.start(queue: DispatchQueue(label: "IpRiskLight.pathMonitor"))
    }

    private func handleNetworkChange(signature: String) {
        guard signature != lastNetworkSignature else { return }
        let isInitial = lastNetworkSignature == nil
        lastNetworkSignature = signature
        // 启动时的首个回调不触发(start() 已主动刷新);断网状态不请求
        guard !isInitial, signature.hasPrefix("up") else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }
}
