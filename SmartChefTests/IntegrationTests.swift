//
//  IntegrationTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation
import SwiftData
import Testing

@testable import SmartChef

// MARK: - 統合テスト: データ間の連携動作

struct IntegrationTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self,
            configurations: config
        )
    }

    // MARK: - 完了報告ワークフロー

    @Test("完了報告: MealPlan を完了にすると MealHistory に記録できる")
    func completeMealPlanCreatesHistory() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // 食事計画を作成
        let plan = MealPlan(date: Date(), mealType: .dinner, menuName: "カレーライス")
        context.insert(plan)
        try context.save()

        // 完了報告シミュレーション
        plan.status = .completed

        let history = MealHistory(
            date: plan.date,
            menuName: plan.menuName,
            mealType: plan.mealType
        )
        context.insert(history)
        try context.save()

        // 確認
        let plans = try context.fetch(FetchDescriptor<MealPlan>())
        let histories = try context.fetch(FetchDescriptor<MealHistory>())

        #expect(plans.first?.status == .completed)
        #expect(histories.count == 1)
        #expect(histories.first?.menuName == "カレーライス")
        #expect(histories.first?.mealType == .dinner)
    }

    @Test("完了報告: 在庫を減算する")
    func completeMealPlanReducesStock() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // 在庫を作成
        let chicken = StockItem(name: "鶏もも肉", category: .meat, count: 3)
        let rice = StockItem(name: "米", category: .grain, count: 5)
        context.insert(chicken)
        context.insert(rice)
        try context.save()

        // 料理に使用する在庫を減算（鶏もも肉 2個使用、米 1個使用）
        chicken.count -= 2
        rice.count -= 1
        try context.save()

        let stocks = try context.fetch(FetchDescriptor<StockItem>())
        let chickenStock = stocks.first { $0.name == "鶏もも肉" }
        let riceStock = stocks.first { $0.name == "米" }

        #expect(chickenStock?.count == 1)
        #expect(riceStock?.count == 4)
    }

    // MARK: - 献立変更ワークフロー

    @Test("内容変更報告: MealPlan の名前を変更して status を changed にする")
    func changeMealPlan() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let plan = MealPlan(date: Date(), mealType: .lunch, menuName: "ラーメン")
        context.insert(plan)
        try context.save()

        // 内容変更
        plan.menuName = "味噌ラーメン"
        plan.status = .changed
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MealPlan>())
        #expect(fetched.first?.menuName == "味噌ラーメン")
        #expect(fetched.first?.status == .changed)
    }

    // MARK: - モックデータ投入後の状態テスト

    @Test("モックデータ投入後に全データ種別が正しく取得できる")
    func mockDataAllTypes() throws {
        let container = try makeContainer()
        let context = container.mainContext

        DataMockService.seedMockData(context: context)

        let stocks = try context.fetch(FetchDescriptor<StockItem>())
        let shopping = try context.fetch(FetchDescriptor<ShoppingItem>())
        let history = try context.fetch(FetchDescriptor<MealHistory>())
        let plans = try context.fetch(FetchDescriptor<MealPlan>())

        #expect(!stocks.isEmpty)
        #expect(!shopping.isEmpty)
        #expect(!history.isEmpty)
        #expect(!plans.isEmpty)
    }

    @Test("モックデータ投入後にデータを全削除できる")
    func clearAllDataAfterMock() throws {
        let container = try makeContainer()
        let context = container.mainContext

        DataMockService.seedMockData(context: context)

        // 全データ削除
        try context.delete(model: StockItem.self)
        try context.delete(model: ShoppingItem.self)
        try context.delete(model: MealHistory.self)
        try context.delete(model: MealPlan.self)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<StockItem>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<ShoppingItem>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<MealHistory>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<MealPlan>()).isEmpty)
    }

    // MARK: - 買い物リスト → 在庫変換ワークフロー

    @Test("買い物リストのアイテムから StockItem を作成できる")
    func convertShoppingToStock() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // 買い物リストにアイテムを追加
        let shoppingItem = ShoppingItem(name: "玉ねぎ", category: .vegetables, count: 3)
        context.insert(shoppingItem)
        try context.save()

        // 購入完了後、在庫に変換
        let stockItem = StockItem(
            name: shoppingItem.name,
            category: shoppingItem.category,
            deadline: Date().addingTimeInterval(86400 * 7),
            count: shoppingItem.count
        )
        context.insert(stockItem)

        // 買い物リストから削除
        context.delete(shoppingItem)
        try context.save()

        let remainingShopping = try context.fetch(FetchDescriptor<ShoppingItem>())
        let newStock = try context.fetch(FetchDescriptor<StockItem>())

        #expect(remainingShopping.isEmpty)
        #expect(newStock.count == 1)
        #expect(newStock.first?.name == "玉ねぎ")
        #expect(newStock.first?.count == 3)
    }

    // MARK: - ダッシュボード表示ロジック

    @Test("当日の食事計画のみをフィルタできる")
    func filterTodayMealPlans() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let today = Date()
        let tomorrow = today.addingTimeInterval(86400)
        let yesterday = today.addingTimeInterval(-86400)

        context.insert(MealPlan(date: yesterday, mealType: .dinner, menuName: "昨日の夕食"))
        context.insert(MealPlan(date: today, mealType: .breakfast, menuName: "今日の朝食"))
        context.insert(MealPlan(date: today, mealType: .lunch, menuName: "今日の昼食"))
        context.insert(MealPlan(date: today, mealType: .dinner, menuName: "今日の夕食"))
        context.insert(MealPlan(date: tomorrow, mealType: .breakfast, menuName: "明日の朝食"))
        try context.save()

        let allPlans = try context.fetch(FetchDescriptor<MealPlan>())

        let startOfToday = Calendar.current.startOfDay(for: today)
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!

        let todayPlans = allPlans.filter { plan in
            plan.date >= startOfToday && plan.date < endOfToday
        }

        #expect(todayPlans.count == 3)
    }

    @Test("期限が近い食材を urgentItems としてフィルタできる")
    func urgentStockItems() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // さまざまな期限の食材を追加
        context.insert(
            StockItem(
                name: "期限切れ", category: .meat,
                deadline: Date().addingTimeInterval(-86400), count: 1))
        context.insert(
            StockItem(
                name: "あと2日", category: .dairy,
                deadline: Date().addingTimeInterval(86400 * 2), count: 1))
        context.insert(
            StockItem(
                name: "あと5日", category: .vegetables,
                deadline: Date().addingTimeInterval(86400 * 5), count: 1))
        context.insert(
            StockItem(
                name: "あと10日", category: .seafood,
                deadline: Date().addingTimeInterval(86400 * 10), count: 1))
        context.insert(StockItem(name: "期限なし", category: .grain, deadline: nil, count: 1))
        try context.save()

        let allItems = try context.fetch(FetchDescriptor<StockItem>())
        let warningDays = 7
        let threshold = Calendar.current.date(byAdding: .day, value: warningDays, to: Date())!

        let urgentItems = allItems.filter { item in
            guard let deadline = item.deadline else { return false }
            return deadline <= threshold
        }

        // 期限切れ, あと2日, あと5日 の3件
        #expect(urgentItems.count == 3)
        #expect(urgentItems.contains { $0.name == "期限切れ" })
        #expect(urgentItems.contains { $0.name == "あと2日" })
        #expect(urgentItems.contains { $0.name == "あと5日" })
    }
}
