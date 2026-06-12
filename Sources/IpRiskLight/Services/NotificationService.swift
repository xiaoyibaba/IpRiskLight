import Foundation
import UserNotifications

/// 根据前后两次检测结果决定要发哪些通知。纯函数,便于单测。
enum NotificationPlanner {
    struct Notice: Equatable {
        var title: String
        var body: String
    }

    static func plan(previous: IPDataResponse?, new: IPDataResponse) -> [Notice] {
        var notices: [Notice] = []
        let newLevel = RiskLevel.evaluate(new.threat)

        // IP 变化:首次检测(无 previous)不算变化
        if let previousIP = previous?.ip, previousIP != new.ip {
            notices.append(Notice(
                title: "IP 已变化",
                body: "\(previousIP) → \(new.ip)\n\(new.locationText) · 风险:\(newLevel.title)"
            ))
        }

        // 进入高风险:仅在从非红变红时提醒一次,避免每次轮询重复打扰
        let previousLevel = previous.map { RiskLevel.evaluate($0.threat) }
        if newLevel == .red, previousLevel != .red {
            let flags = new.threat?.activeFlags ?? []
            let detail = flags.isEmpty ? "威胁分数过高" : flags.joined(separator: "、")
            notices.append(Notice(
                title: "⚠️ 当前 IP 为高风险",
                body: "\(new.ip)\n命中:\(detail)"
            ))
        }

        return notices
    }
}

/// 系统通知发送,封装 UNUserNotificationCenter。
/// 该 API 依赖 app bundle,swift run 裸跑(无 bundle)时静默跳过。
@MainActor
struct NotificationService {
    private var available: Bool { Bundle.main.bundleIdentifier != nil }

    func requestAuthorization() {
        guard available else { return }
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func send(_ notice: NotificationPlanner.Notice) {
        guard available else { return }
        let content = UNMutableNotificationContent()
        content.title = notice.title
        content.body = notice.body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
