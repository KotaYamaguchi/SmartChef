//
//  StockItemSwiftDataTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation
import SwiftData
import Testing

@testable import SmartChef

// MARK: - StockItem SwiftData Tests

struct StockItemSwiftDataTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self,
            configurations: config
        )
    }

    @Test("StockItem を SwiftData に保存して取得できる")
    func persistAndFetch() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let deadline = Date().addingTimeInterval(86400 * 3)
        let item = StockItem(name: "鶏もも肉", category: .meat, deadline: deadline, count: 2)
        context.insert(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StockItem>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "鶏もも肉")
        #expect(fetched.first?.category == .meat)
        #expect(fetched.first?.count == 2)
        #expect(fetched.first?.deadline != nil)
    }

    @Test("StockItem の count を更新できる")
    func updateCount() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let item = StockItem(name: "卵", category: .egg, count: 6)
        context.insert(item)
        try context.save()

        item.count = 3
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StockItem>())
        #expect(fetched.first?.count == 3)
    }

    @Test("StockItem を削除できる")
    func deleteItem() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let item = StockItem(name: "牛乳", category: .dairy, count: 1)
        context.insert(item)
        try context.save()

        context.delete(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StockItem>())
        #expect(fetched.isEmpty)
    }

    @Test("カテゴリ別にフィルタして取得できる")
    func fetchByCategory() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(StockItem(name: "キャベツ", category: .vegetables, count: 1))
        context.insert(StockItem(name: "にんじん", category: .vegetables, count: 2))
        context.insert(StockItem(name: "鶏もも肉", category: .meat, count: 1))
        context.insert(StockItem(name: "牛乳", category: .dairy, count: 1))
        try context.save()

        let allItems = try context.fetch(FetchDescriptor<StockItem>())
        let vegetables = allItems.filter { $0.category == .vegetables }
        #expect(vegetables.count == 2)
    }

    @Test("期限切れの StockItem をフィルタできる")
    func filterExpired() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let expiredItem = StockItem(
            name: "期限切れ食材", category: .other,
            deadline: Date().addingTimeInterval(-86400), count: 1)
        let freshItem = StockItem(
            name: "新鮮食材", category: .other,
            deadline: Date().addingTimeInterval(86400 * 5), count: 1)
        let noDeadline = StockItem(
            name: "期限なし食材", category: .other,
            deadline: nil, count: 1)

        context.insert(expiredItem)
        context.insert(freshItem)
        context.insert(noDeadline)
        try context.save()

        let allItems = try context.fetch(FetchDescriptor<StockItem>())
        let expired = allItems.filter { item in
            guard let deadline = item.deadline else { return false }
            return deadline < Date()
        }
        #expect(expired.count == 1)
        #expect(expired.first?.name == "期限切れ食材")
    }

    @Test("count が0以下になった場合も保存できる")
    func zeroCount() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let item = StockItem(name: "テスト食材", category: .other, count: 1)
        context.insert(item)
        try context.save()

        item.count = 0
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StockItem>())
        #expect(fetched.first?.count == 0)
    }

    @Test("複数の StockItem を一括削除できる")
    func bulkDelete() throws {
        let container = try makeContainer()
        let context = container.mainContext

        for i in 0..<10 {
            context.insert(StockItem(name: "食材\(i)", category: .other, count: 1))
        }
        try context.save()

        let beforeCount = try context.fetch(FetchDescriptor<StockItem>()).count
        #expect(beforeCount == 10)

        try context.delete(model: StockItem.self)
        try context.save()

        let afterCount = try context.fetch(FetchDescriptor<StockItem>()).count
        #expect(afterCount == 0)
    }
}

// MARK: - MealHistory SwiftData Tests

struct MealHistorySwiftDataTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self,
            configurations: config
        )
    }

    @Test("MealHistory を SwiftData に保存して取得できる")
    func persistAndFetch() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let date = Date()
        let history = MealHistory(date: date, menuName: "カレーライス", mealType: .dinner)
        context.insert(history)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MealHistory>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.menuName == "カレーライス")
        #expect(fetched.first?.mealType == .dinner)
    }

    @Test("MealHistory を日付順に取得できる")
    func fetchSorted() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let today = Date()
        let yesterday = today.addingTimeInterval(-86400)
        let twoDaysAgo = today.addingTimeInterval(-86400 * 2)

        context.insert(MealHistory(date: twoDaysAgo, menuName: "2日前のメニュー", mealType: .dinner))
        context.insert(MealHistory(date: today, menuName: "今日のメニュー", mealType: .lunch))
        context.insert(MealHistory(date: yesterday, menuName: "昨日のメニュー", mealType: .breakfast))
        try context.save()

        let descriptor = FetchDescriptor<MealHistory>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let sorted = try context.fetch(descriptor)

        #expect(sorted.count == 3)
        #expect(sorted[0].menuName == "今日のメニュー")
        #expect(sorted[1].menuName == "昨日のメニュー")
        #expect(sorted[2].menuName == "2日前のメニュー")
    }

    @Test("MealHistory を MealType でフィルタできる")
    func filterByMealType() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(MealHistory(date: Date(), menuName: "トースト", mealType: .breakfast))
        context.insert(MealHistory(date: Date(), menuName: "ラーメン", mealType: .lunch))
        context.insert(MealHistory(date: Date(), menuName: "カレー", mealType: .dinner))
        context.insert(MealHistory(date: Date(), menuName: "パスタ", mealType: .dinner))
        try context.save()

        let allHistories = try context.fetch(FetchDescriptor<MealHistory>())
        let dinnerOnly = allHistories.filter { $0.mealType == .dinner }
        #expect(dinnerOnly.count == 2)
    }

    @Test("MealHistory を一括削除できる")
    func bulkDelete() throws {
        let container = try makeContainer()
        let context = container.mainContext

        for i in 0..<5 {
            context.insert(
                MealHistory(
                    date: Date().addingTimeInterval(Double(-i) * 86400),
                    menuName: "メニュー\(i)",
                    mealType: .dinner
                ))
        }
        try context.save()

        try context.delete(model: MealHistory.self)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<MealHistory>())
        #expect(remaining.isEmpty)
    }
}
