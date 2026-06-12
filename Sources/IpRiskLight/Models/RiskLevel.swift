import SwiftUI

enum RiskLevel: Sendable {
    case green
    case yellow
    case red
    case unknown

    /// 风险映射规则:
    /// - 红:威胁/攻击源/滥用源/Tor/Bogon,或 threat_score ≥ 70
    /// - 黄:代理/匿名/数据中心,或 vpn_score ≥ 60 / proxy_score ≥ 60
    /// - 绿:以上均未命中
    static func evaluate(_ threat: IPDataResponse.Threat?) -> RiskLevel {
        guard let threat else { return .unknown }
        let scores = threat.scores
        if threat.isThreat == true
            || threat.isKnownAttacker == true
            || threat.isKnownAbuser == true
            || threat.isTor == true
            || threat.isBogon == true
            || (scores?.threatScore ?? 0) >= 70 {
            return .red
        }
        if threat.isProxy == true
            || threat.isAnonymous == true
            || threat.isDatacenter == true
            || (scores?.vpnScore ?? 0) >= 60
            || (scores?.proxyScore ?? 0) >= 60 {
            return .yellow
        }
        return .green
    }

    var title: String {
        switch self {
        case .green: "安全"
        case .yellow: "注意"
        case .red: "危险"
        case .unknown: "未知"
        }
    }

    var color: Color {
        switch self {
        case .green: .green
        case .yellow: .yellow
        case .red: .red
        case .unknown: .gray
        }
    }

    var nsColor: NSColor {
        switch self {
        case .green: .systemGreen
        case .yellow: .systemYellow
        case .red: .systemRed
        case .unknown: .systemGray
        }
    }
}
