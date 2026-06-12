import Foundation
import Testing

@testable import IpRiskLight

@Suite("风险等级映射")
struct RiskLevelTests {
    @Test func torIsRed() {
        #expect(RiskLevel.evaluate(.init(isTor: true)) == .red)
    }

    @Test func knownAttackerIsRed() {
        #expect(RiskLevel.evaluate(.init(isKnownAttacker: true)) == .red)
    }

    @Test func highThreatScoreIsRed() {
        #expect(RiskLevel.evaluate(.init(scores: .init(threatScore: 85))) == .red)
    }

    @Test func datacenterIsYellow() {
        #expect(RiskLevel.evaluate(.init(isDatacenter: true)) == .yellow)
    }

    @Test func proxyIsYellow() {
        #expect(RiskLevel.evaluate(.init(isProxy: true)) == .yellow)
    }

    @Test func highVpnScoreIsYellow() {
        #expect(RiskLevel.evaluate(.init(scores: .init(vpnScore: 75))) == .yellow)
    }

    @Test func redBeatsYellow() {
        #expect(RiskLevel.evaluate(.init(isTor: true, isProxy: true)) == .red)
    }

    @Test func cleanIsGreen() {
        let threat = IPDataResponse.Threat(
            isTor: false, isProxy: false, isDatacenter: false,
            scores: .init(vpnScore: 0, proxyScore: 0, threatScore: 0, trustScore: 100)
        )
        #expect(RiskLevel.evaluate(threat) == .green)
    }

    @Test func missingThreatIsUnknown() {
        #expect(RiskLevel.evaluate(nil) == .unknown)
    }
}

@Suite("响应解码")
struct DecodingTests {
    @Test func decodesSnakeCaseResponse() throws {
        let json = """
        {
          "ip": "1.2.3.4",
          "city": "Sydney",
          "region": "New South Wales",
          "country_name": "Australia",
          "country_code": "AU",
          "emoji_flag": "🇦🇺",
          "latitude": -33.86,
          "longitude": 151.2,
          "asn": {"asn": "AS13335", "name": "Cloudflare, Inc.", "domain": "cloudflare.com", "type": "hosting"},
          "threat": {
            "is_tor": false,
            "is_icloud_relay": false,
            "is_proxy": false,
            "is_datacenter": true,
            "is_anonymous": false,
            "is_known_attacker": false,
            "is_known_abuser": false,
            "is_threat": false,
            "is_bogon": false,
            "scores": {"vpn_score": 1, "proxy_score": 2, "threat_score": 3, "trust_score": 97}
          }
        }
        """.data(using: .utf8)!

        let response = try IPDataService.decode(json)
        #expect(response.ip == "1.2.3.4")
        #expect(response.countryName == "Australia")
        #expect(response.threat?.isDatacenter == true)
        #expect(response.threat?.scores?.trustScore == 97)
        #expect(RiskLevel.evaluate(response.threat) == .yellow)
        #expect(response.locationText == "🇦🇺 Sydney, New South Wales, Australia")
    }
}
