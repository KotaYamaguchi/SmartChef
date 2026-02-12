//
//  ShoppingItemTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation
import SwiftData
import Testing

@testable import SmartChef

// MARK: - ShoppingItem Extended Tests

struct ShoppingItemExtendedTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self,
            configurations: config
        )
    }

    @Test("ShoppingItem のオプショナルプロパティがデフォルトで nil")
    func optionalPropertiesDefault() {
        let item = ShoppingItem(name: "テスト", category: .other)
        #expect(item.sourceMenuName == nil)
        #expect(item.recipeAmount == nil)
    }

    @Test("ShoppingItem のオプショナルプロパティを設定できる")
    func optionalPropertiesSet() {
        let item = ShoppingItem(
            name: "鶏もも肉",
            category: .meat,
            count: 1,
            isSelected: false,
            sourceMenuName: "チキンソテー（夕食）",
            recipeAmount: "300g"
        )
        #expect(item.sourceMenuName == "チキンソテー（夕食）")
        #expect(item.recipeAmount == "300g")
    }

    @Test("ShoppingItem を SwiftData に保存して取得できる")
    func persistAndFetch() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let item = ShoppingItem(name: "玉ねぎ", category: .vegetables, count: 3)
        context.insert(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "玉ねぎ")
        #expect(fetched.first?.category == .vegetables)
        #expect(fetched.first?.count == 3)
        #expect(fetched.first?.isSelected == false)
    }

    @Test("ShoppingItem の isSelected を更新できる")
    func toggleSelection() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let item = ShoppingItem(name: "牛乳", category: .dairy)
        context.insert(item)
        try context.save()

        item.isSelected = true
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(fetched.first?.isSelected == true)
    }

    @Test("ShoppingItem を削除できる")
    func deleteItem() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let item = ShoppingItem(name: "卵", category: .egg, count: 6)
        context.insert(item)
        try context.save()

        context.delete(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(fetched.isEmpty)
    }

    @Test("sourceMenuName が設定されたアイテムをフィルタできる")
    func filterAutoAdded() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(ShoppingItem(name: "手動追加1", category: .vegetables, count: 1))
        context.insert(
            ShoppingItem(
                name: "自動追加1", category: .meat, count: 1,
                sourceMenuName: "カレーライス（夕食）"
            ))
        context.insert(ShoppingItem(name: "手動追加2", category: .dairy, count: 1))
        context.insert(
            ShoppingItem(
                name: "自動追加2", category: .seasoning, count: 1,
                sourceMenuName: "味噌汁（朝食）"
            ))
        try context.save()

        let allItems = try context.fetch(FetchDescriptor<ShoppingItem>())
        let autoAdded = allItems.filter { $0.sourceMenuName != nil }
        let manualAdded = allItems.filter { $0.sourceMenuName == nil }

        #expect(autoAdded.count == 2)
        #expect(manualAdded.count == 2)
    }
}

// MARK: - ShoppingAutoFillService 部分テスト

struct ShoppingAutoFillServiceTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self,
            configurations: config
        )
    }

    @Test("clearAutoAddedItems が sourceMenuName 付きのアイテムのみ削除する")
    func clearAutoAdded() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let manualItem = ShoppingItem(name: "手動追加", category: .vegetables, count: 1)
        let autoItem1 = ShoppingItem(
            name: "自動追加1", category: .meat, count: 1,
            sourceMenuName: "カレーライス（夕食）"
        )
        let autoItem2 = ShoppingItem(
            name: "自動追加2", category: .seasoning, count: 1,
            sourceMenuName: "味噌汁（朝食）"
        )

        context.insert(manualItem)
        context.insert(autoItem1)
        context.insert(autoItem2)
        try context.save()

        let allItems = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(allItems.count == 3)

        ShoppingAutoFillService.clearAutoAddedItems(from: allItems, context: context)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "手動追加")
    }

    @Test("clearAutoAddedItems が空リストに対してクラッシュしない")
    func clearEmptyList() throws {
        let container = try makeContainer()
        let context = container.mainContext

        ShoppingAutoFillService.clearAutoAddedItems(from: [], context: context)
        // クラッシュしなければ成功
    }

    @Test("clearAutoAddedItems が sourceMenuName = nil のアイテムだけの場合何も削除しない")
    func clearOnlyManualItems() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let item1 = ShoppingItem(name: "玉ねぎ", category: .vegetables, count: 2)
        let item2 = ShoppingItem(name: "豚バラ肉", category: .meat, count: 1)
        context.insert(item1)
        context.insert(item2)
        try context.save()

        let allItems = try context.fetch(FetchDescriptor<ShoppingItem>())
        ShoppingAutoFillService.clearAutoAddedItems(from: allItems, context: context)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(remaining.count == 2)
    }
}
