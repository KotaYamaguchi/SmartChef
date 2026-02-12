//
//  DashBordLogicTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/10.
//

import Foundation
import Testing

@testable import SmartChef

// MARK: - Dashboard ヘルパーロジックのテスト

struct DashBordLogicTests {

    /// urgentItems() 相当のロジックを再利用可能な形でテストする
    /// DashBordView.urgentItems() と同じロジック
    private func filterUrgentItems(_ items: [StockItem]) -> [StockItem] {
        let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return items.filter { item in
            guard let deadline = item.deadline else { return false }
            return deadline <= sevenDaysLater
        }
    }

    @Test("期限が7日以内の食材をフィルタリングできる")
    func filterWithin7Days() {
        let items = [
            StockItem(
                name: "鶏もも肉", category: .meat, deadline: Date().addingTimeInterval(86400 * 1),
                count: 2),
            StockItem(
                name: "牛乳", category: .dairy, deadline: Date().addingTimeInterval(86400 * 5),
                count: 1),
            StockItem(
                name: "チーズ", category: .dairy, deadline: Date().addingTimeInterval(86400 * 10),
                count: 1),
            StockItem(name: "米", category: .grain, deadline: nil, count: 3),
        ]

        let urgent = filterUrgentItems(items)

        // 鶏もも肉（1日後）と牛乳（5日後）は7日以内
        #expect(urgent.count == 2)
        #expect(urgent.contains { $0.name == "鶏もも肉" })
        #expect(urgent.contains { $0.name == "牛乳" })
    }

    @Test("期限なしの食材は urgentItems に含まれない")
    func filterNoDeadline() {
        let items = [
            StockItem(name: "米", category: .grain, deadline: nil, count: 3),
            StockItem(name: "醤油", category: .seasoning, deadline: nil, count: 1),
        ]

        let urgent = filterUrgentItems(items)
        #expect(urgent.isEmpty)
    }

    @Test("全て期限切れの場合も urgentItems に含まれる")
    func filterExpired() {
        let items = [
            StockItem(
                name: "期限切れ食材", category: .other, deadline: Date().addingTimeInterval(-86400),
                count: 1)
        ]

        let urgent = filterUrgentItems(items)
        #expect(urgent.count == 1)
    }

    @Test("空配列の場合は空の結果を返す")
    func filterEmpty() {
        let urgent = filterUrgentItems([])
        #expect(urgent.isEmpty)
    }

    @Test("ちょうど7日後の食材は urgentItems に含まれる")
    func filterExactly7Days() {
        let items = [
            StockItem(
                name: "ギリギリ食材", category: .other, deadline: Date().addingTimeInterval(86400 * 7),
                count: 1)
        ]

        let urgent = filterUrgentItems(items)
        #expect(urgent.count == 1)
    }
}

// MARK: - ExpiryItemRow ヘルパーロジックテスト

struct ExpiryItemRowLogicTests {

    /// daysLabel と同じロジック
    private func daysLabel(deadline: Date) -> String {
        let days =
            Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: Date()),
                to: Calendar.current.startOfDay(for: deadline)
            ).day ?? 0
        switch days {
        case ..<0: return "期限切れ"
        case 0: return "今日まで"
        case 1: return "あと1日"
        default: return "あと\(days)日"
        }
    }

    @Test("今日が期限の場合は「今日まで」を返す")
    func todayDeadline() {
        let label = daysLabel(deadline: Date())
        #expect(label == "今日まで")
    }

    @Test("明日が期限の場合は「あと1日」を返す")
    func tomorrowDeadline() {
        let tomorrow = Date().addingTimeInterval(86400)
        let label = daysLabel(deadline: tomorrow)
        #expect(label == "あと1日")
    }

    @Test("3日後が期限の場合は「あと3日」を返す")
    func threeDaysDeadline() {
        let threeDays = Date().addingTimeInterval(86400 * 3)
        let label = daysLabel(deadline: threeDays)
        #expect(label == "あと3日")
    }

    @Test("昨日が期限の場合は「期限切れ」を返す")
    func expiredDeadline() {
        let yesterday = Date().addingTimeInterval(-86400)
        let label = daysLabel(deadline: yesterday)
        #expect(label == "期限切れ")
    }
}
