//
//  DataMockServiceTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/10.
//

import Foundation
import SwiftData
import Testing

@testable import SmartChef

// MARK: - DataMockService Tests

struct DataMockServiceTests {
    /// テスト用の in-memory ModelContainer を生成するヘルパー
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self,
            configurations: config
        )
    }

    @Test("seedMockData が在庫データを正しく投入する（6〜12件のランダム件数）")
    func seedStockItems() throws {
        let container = try makeContainer()
        let context = container.mainContext
        DataMockService.seedMockData(context: context)

        let stockItems = try context.fetch(FetchDescriptor<StockItem>())
        #expect(stockItems.count >= 6)
        #expect(stockItems.count <= 12)

        // 名前の重複がないことを確認
        let names = stockItems.map { $0.name }
        #expect(Set(names).count == names.count)

        // 全てのアイテムにカテゴリが設定されていることを確認
        for item in stockItems {
            #expect(Category.allCases.contains(item.category))
            #expect(item.count >= 1)
        }
    }

    @Test("seedMockData が買い物リストデータを正しく投入する（2〜6件のランダム件数）")
    func seedShoppingItems() throws {
        let container = try makeContainer()
        let context = container.mainContext
        DataMockService.seedMockData(context: context)

        let shoppingItems = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(shoppingItems.count >= 2)
        #expect(shoppingItems.count <= 6)

        // 名前の重複がないことを確認
        let names = shoppingItems.map { $0.name }
        #expect(Set(names).count == names.count)
    }

    @Test("seedMockData が食事履歴データを正しく投入する")
    func seedMealHistory() throws {
        let container = try makeContainer()
        let context = container.mainContext
        DataMockService.seedMockData(context: context)

        let history = try context.fetch(FetchDescriptor<MealHistory>())
        // 7〜14日分、各日0〜3食なので最低でも数件は生成される
        #expect(history.count >= 5)

        // 複数の MealType が使われていることを確認
        let mealTypes = Set(history.map { $0.mealType })
        #expect(mealTypes.count >= 2)
    }

    @Test("seedMockData が食事計画データを正しく投入する（3日×3食 = 9件）")
    func seedMealPlans() throws {
        let container = try makeContainer()
        let context = container.mainContext
        DataMockService.seedMockData(context: context)

        let plans = try context.fetch(FetchDescriptor<MealPlan>())
        #expect(plans.count == 9)  // 今日〜2日後 × 朝昼晩 = 9件

        // 全ての MealType が含まれることを確認
        let mealTypes = Set(plans.map { $0.mealType })
        #expect(mealTypes.contains(.breakfast))
        #expect(mealTypes.contains(.lunch))
        #expect(mealTypes.contains(.dinner))

        // 全てのプランが planned 状態であることを確認
        for plan in plans {
            #expect(plan.status == .planned)
        }
    }

    @Test("seedMockData を複数回呼ぶとデータがリセットされる")
    func seedMultipleTimes() throws {
        let container = try makeContainer()
        let context = container.mainContext

        DataMockService.seedMockData(context: context)
        _ = try context.fetch(FetchDescriptor<StockItem>()).count

        DataMockService.seedMockData(context: context)
        let secondCount = try context.fetch(FetchDescriptor<StockItem>()).count

        // データがリセットされているので、2回目も6〜12件の範囲内
        #expect(secondCount >= 6)
        #expect(secondCount <= 12)
    }

    @Test("ランダム生成で毎回異なるデータが生成される可能性がある")
    func randomnessDiversity() {
        // 10回生成して、少なくとも2種類以上の異なる在庫セットが得られることを確認
        var nameSets: [Set<String>] = []
        for _ in 0..<10 {
            let items = DataMockService.generateRandomStockItems()
            nameSets.append(Set(items.map { $0.name }))
        }

        let uniqueSets = Set(nameSets.map { $0.sorted().joined(separator: ",") })
        // 10回中少なくとも2種類は異なるデータが生成されるはず
        #expect(uniqueSets.count >= 2)
    }

    @Test("generateRandomStockItems が期限付きと期限なしの両方を含む")
    func stockItemsHaveMixedDeadlines() {
        // 10回試行して、少なくとも1回は混在するケースが出ることを確認
        var foundMixed = false
        for _ in 0..<10 {
            let items = DataMockService.generateRandomStockItems()
            let hasDeadline = items.contains { $0.deadline != nil }
            let noDeadline = items.contains { $0.deadline == nil }
            if hasDeadline && noDeadline {
                foundMixed = true
                break
            }
        }
        #expect(foundMixed)
    }

    @Test("generateRandomMealHistories が複数日にわたるデータを生成する")
    func mealHistoriesSpanMultipleDays() {
        let histories = DataMockService.generateRandomMealHistories()

        // 少なくとも複数日分のデータが含まれることを確認
        let uniqueDays = Set(histories.map { Calendar.current.startOfDay(for: $0.date) })
        #expect(uniqueDays.count >= 3)
    }

    @Test("generateRandomMealPlans が未来の日付のみを含む")
    func mealPlansAreFutureDated() {
        let plans = DataMockService.generateRandomMealPlans()
        let startOfToday = Calendar.current.startOfDay(for: Date())

        for plan in plans {
            let planDay = Calendar.current.startOfDay(for: plan.date)
            #expect(planDay >= startOfToday)
        }
    }
}
