import Foundation

/// ipdata.co API 响应模型,字段名经 JSONDecoder 的 convertFromSnakeCase 映射。
struct IPDataResponse: Codable, Sendable {
    var ip: String
    var city: String?
    var region: String?
    var countryName: String?
    var countryCode: String?
    var emojiFlag: String?
    var latitude: Double?
    var longitude: Double?
    var asn: ASN?
    var threat: Threat?

    struct ASN: Codable, Sendable {
        var asn: String?
        var name: String?
        var domain: String?
        var type: String?
    }

    struct Threat: Codable, Sendable {
        var isTor: Bool?
        var isIcloudRelay: Bool?
        var isProxy: Bool?
        var isDatacenter: Bool?
        var isAnonymous: Bool?
        var isKnownAttacker: Bool?
        var isKnownAbuser: Bool?
        var isThreat: Bool?
        var isBogon: Bool?
        var scores: Scores?

        /// 命中的威胁标志,用于弹窗展示。
        var activeFlags: [String] {
            var flags: [String] = []
            if isThreat == true { flags.append("威胁 IP") }
            if isKnownAttacker == true { flags.append("已知攻击源") }
            if isKnownAbuser == true { flags.append("已知滥用源") }
            if isTor == true { flags.append("Tor 出口节点") }
            if isBogon == true { flags.append("Bogon 地址") }
            if isProxy == true { flags.append("代理") }
            if isDatacenter == true { flags.append("数据中心 IP") }
            if isAnonymous == true { flags.append("匿名网络") }
            if isIcloudRelay == true { flags.append("iCloud 私有中继") }
            return flags
        }
    }

    struct Scores: Codable, Sendable {
        var vpnScore: Double?
        var proxyScore: Double?
        var threatScore: Double?
        var trustScore: Double?
    }

    /// 位置摘要,如 "🇨🇳 Beijing, Beijing, China"。
    var locationText: String {
        let parts = [city, region, countryName].compactMap { $0 }.filter { !$0.isEmpty }
        let place = parts.isEmpty ? "未知位置" : parts.joined(separator: ", ")
        if let flag = emojiFlag, !flag.isEmpty {
            return "\(flag) \(place)"
        }
        return place
    }
}
