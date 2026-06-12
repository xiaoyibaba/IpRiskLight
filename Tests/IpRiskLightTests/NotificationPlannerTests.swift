import Foundation
import Testing

@testable import IpRiskLight

@Suite("通知判定")
struct NotificationPlannerTests {
    private func response(ip: String, threat: IPDataResponse.Threat? = .init()) -> IPDataResponse {
        IPDataResponse(ip: ip, city: "Beijing", countryName: "China", threat: threat)
    }

    @Test func firstFetchSendsNothingWhenClean() {
        let notices = NotificationPlanner.plan(previous: nil, new: response(ip: "1.1.1.1"))
        #expect(notices.isEmpty)
    }

    @Test func ipChangeSendsNotice() {
        let notices = NotificationPlanner.plan(
            previous: response(ip: "1.1.1.1"),
            new: response(ip: "2.2.2.2")
        )
        #expect(notices.count == 1)
        #expect(notices[0].title == "IP 已变化")
        #expect(notices[0].body.contains("1.1.1.1 → 2.2.2.2"))
    }

    @Test func sameIPSendsNothing() {
        let notices = NotificationPlanner.plan(
            previous: response(ip: "1.1.1.1"),
            new: response(ip: "1.1.1.1")
        )
        #expect(notices.isEmpty)
    }

    @Test func becomingRedSendsHighRiskNotice() {
        let notices = NotificationPlanner.plan(
            previous: response(ip: "1.1.1.1"),
            new: response(ip: "1.1.1.1", threat: .init(isTor: true))
        )
        #expect(notices.count == 1)
        #expect(notices[0].title.contains("高风险"))
        #expect(notices[0].body.contains("Tor 出口节点"))
    }

    @Test func firstFetchRedSendsHighRiskNotice() {
        let notices = NotificationPlanner.plan(
            previous: nil,
            new: response(ip: "1.1.1.1", threat: .init(isKnownAttacker: true))
        )
        #expect(notices.count == 1)
        #expect(notices[0].title.contains("高风险"))
    }

    @Test func stayingRedDoesNotRepeat() {
        let notices = NotificationPlanner.plan(
            previous: response(ip: "1.1.1.1", threat: .init(isTor: true)),
            new: response(ip: "1.1.1.1", threat: .init(isTor: true))
        )
        #expect(notices.isEmpty)
    }

    @Test func ipChangeToRedSendsBothNotices() {
        let notices = NotificationPlanner.plan(
            previous: response(ip: "1.1.1.1"),
            new: response(ip: "2.2.2.2", threat: .init(isThreat: true))
        )
        #expect(notices.count == 2)
        #expect(notices[0].title == "IP 已变化")
        #expect(notices[1].title.contains("高风险"))
    }

    @Test func yellowDoesNotSendHighRiskNotice() {
        let notices = NotificationPlanner.plan(
            previous: response(ip: "1.1.1.1"),
            new: response(ip: "1.1.1.1", threat: .init(isProxy: true))
        )
        #expect(notices.isEmpty)
    }
}
