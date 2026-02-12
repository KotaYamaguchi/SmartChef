//
//  MealPlanTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation
import SwiftData
import Testing

@testable import SmartChef

// MARK: - MealPlan Model Tests

struct MealPlanModelTests {

    @Test("MealPlan の初期化で全プロパティが正しく設定される")
    func initWithAllProperties() {
        let date = Date()
        let plan = MealPlan(date: date, mealType: .lunch, menuName: "親子丼", status: .completed)

        #expect(plan.date == date)
        #expect(plan.mealType == .lunch)
        #expect(plan.menuName == "親子丼")
        #expect(plan.status == .completed)
    }

    @Test("MealPlan のデフォルト status が .planned である")
    func defaultStatusIsPlanned() {
        let plan = MealPlan(date: Date(), mealType: .dinner, menuName: "カレーライス")
        #expect(plan.status == .planned)
    }

    @Test("MealPlan の status を .completed に変更できる")
    func changeStatusToCompleted() {
        let plan = MealPlan(date: Date(), mealType: .dinner, menuName: "ハンバーグ")
        plan.status = .completed
        #expect(plan.status == .completed)
    }

    @Test("MealPlan の status を .changed に変更できる")
    func changeStatusToChanged() {
        let plan = MealPlan(date: Date(), mealType: .dinner, menuName: "ハンバーグ")
        plan.status = .changed
        #expect(plan.status == .changed)
    }

    @Test("MealPlan の menuName を変更できる")
    func changeMenuName() {
        let plan = MealPlan(date: Date(), mealType: .lunch, menuName: "ラーメン")
        plan.menuName = "つけ麺"
        #expect(plan.menuName == "つけ麺")
    }

    @Test("MealPlan が一意の UUID を持つ")
    func uniqueIds() {
        let plan1 = MealPlan(date: Date(), mealType: .breakfast, menuName: "トースト")
        let plan2 = MealPlan(date: Date(), mealType: .breakfast, menuName: "トースト")
        #expect(plan1.id != plan2.id)
    }
}

// MARK: - MealPlanStatus Tests

struct MealPlanStatusTests {

    @Test("MealPlanStatus の全ケースが正しい rawValue を持つ")
    func rawValues() {
        #expect(MealPlanStatus.planned.rawValue == "予定")
        #expect(MealPlanStatus.completed.rawValue == "完了")
        #expect(MealPlanStatus.changed.rawValue == "変更済")
    }

    @Test("MealPlanStatus.allCases が3つの要素を持つ")
    func allCases() {
        #expect(MealPlanStatus.allCases.count == 3)
    }

    @Test("MealPlanStatus が Codable に準拠している")
    func codable() throws {
        let originalStatus = MealPlanStatus.completed
        let data = try JSONEncoder().encode(originalStatus)
        let decoded = try JSONDecoder().decode(MealPlanStatus.self, from: data)
        #expect(decoded == originalStatus)
    }
}

// MARK: - MealPlan with SwiftData Tests

struct MealPlanSwiftDataTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self,
            configurations: config
        )
    }

    @Test("MealPlan を SwiftData に保存して取得できる")
    func persistAndFetch() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let date = Date()
        let plan = MealPlan(date: date, mealType: .dinner, menuName: "すき焼き")
        context.insert(plan)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MealPlan>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.menuName == "すき焼き")
        #expect(fetched.first?.mealType == .dinner)
        #expect(fetched.first?.status == .planned)
    }

    @Test("MealPlan の更新が永続化される")
    func updatePersists() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let plan = MealPlan(date: Date(), mealType: .lunch, menuName: "ラーメン")
        context.insert(plan)
        try context.save()

        plan.menuName = "味噌ラーメン"
        plan.status = .changed
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MealPlan>())
        #expect(fetched.first?.menuName == "味噌ラーメン")
        #expect(fetched.first?.status == .changed)
    }

    @Test("MealPlan を削除できる")
    func deletePlan() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let plan = MealPlan(date: Date(), mealType: .breakfast, menuName: "トースト")
        context.insert(plan)
        try context.save()

        context.delete(plan)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MealPlan>())
        #expect(fetched.isEmpty)
    }

    @Test("MealType でフィルタして取得できる")
    func fetchByMealType() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(MealPlan(date: Date(), mealType: .breakfast, menuName: "トースト"))
        context.insert(MealPlan(date: Date(), mealType: .lunch, menuName: "ラーメン"))
        context.insert(MealPlan(date: Date(), mealType: .dinner, menuName: "カレー"))
        context.insert(MealPlan(date: Date(), mealType: .dinner, menuName: "すき焼き"))
        try context.save()

        let allPlans = try context.fetch(FetchDescriptor<MealPlan>())
        let dinnerPlans = allPlans.filter { $0.mealType == .dinner }
        #expect(dinnerPlans.count == 2)
    }
}
