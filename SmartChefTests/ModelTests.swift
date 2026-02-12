//
//  ModelTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/10.
//

import Foundation
import Testing

@testable import SmartChef

// MARK: - StockItem Tests

struct StockItemTests {
    @Test("StockItem の初期化で全プロパティが正しく設定される")
    func initWithAllProperties() {
        let deadline = Date().addingTimeInterval(86400 * 3)
        let item = StockItem(name: "鶏もも肉", category: .meat, deadline: deadline, count: 2)

        #expect(item.name == "鶏もも肉")
        #expect(item.category == .meat)
        #expect(item.deadline == deadline)
        #expect(item.count == 2)
        #expect(item.id != UUID())  // UUID が生成されていること
    }

    @Test("StockItem の deadline がオプショナルで nil にできる")
    func initWithoutDeadline() {
        let item = StockItem(name: "米", category: .grain)

        #expect(item.name == "米")
        #expect(item.deadline == nil)
        #expect(item.count == 1)  // デフォルト値
    }

    @Test("StockItem のカウントがデフォルトで1になる")
    func defaultCount() {
        let item = StockItem(name: "卵", category: .egg)
        #expect(item.count == 1)
    }
}

// MARK: - ShoppingItem Tests

struct ShoppingItemTests {
    @Test("ShoppingItem の初期化が正しく動作する")
    func initDefault() {
        let item = ShoppingItem(name: "玉ねぎ", category: .vegetables, count: 3)

        #expect(item.name == "玉ねぎ")
        #expect(item.category == .vegetables)
        #expect(item.count == 3)
        #expect(item.isSelected == false)  // デフォルトは未選択
    }

    @Test("ShoppingItem の isSelected がデフォルトで false")
    func defaultIsSelected() {
        let item = ShoppingItem(name: "豚バラ肉", category: .meat)
        #expect(item.isSelected == false)
        #expect(item.count == 1)
    }

    @Test("ShoppingItem の isSelected を true で初期化できる")
    func initWithSelected() {
        let item = ShoppingItem(name: "ビール", category: .drink, count: 6, isSelected: true)
        #expect(item.isSelected == true)
        #expect(item.count == 6)
    }
}

// MARK: - MealHistory Tests

struct MealHistoryTests {
    @Test("MealHistory の初期化が正しく動作する")
    func initDefault() {
        let date = Date()
        let entry = MealHistory(date: date, menuName: "カレーライス", mealType: .dinner)

        #expect(entry.menuName == "カレーライス")
        #expect(entry.mealType == .dinner)
        #expect(entry.date == date)
    }

    @Test("全ての MealType が正しい rawValue を持つ")
    func mealTypeRawValues() {
        #expect(MealType.breakfast.rawValue == "朝食")
        #expect(MealType.lunch.rawValue == "昼食")
        #expect(MealType.dinner.rawValue == "夕食")
    }

    @Test("MealType.allCases が3つの要素を持つ")
    func mealTypeAllCases() {
        #expect(MealType.allCases.count == 3)
    }
}

// MARK: - Category Tests

struct CategoryTests {
    @Test("Category の全ケースが正しい rawValue を持つ")
    func categoryRawValues() {
        #expect(Category.vegetables.rawValue == "野菜")
        #expect(Category.meat.rawValue == "肉類")
        #expect(Category.seafood.rawValue == "魚介類")
        #expect(Category.dairy.rawValue == "乳製品")
        #expect(Category.egg.rawValue == "卵・日配品")
        #expect(Category.fruits.rawValue == "果物")
        #expect(Category.seasoning.rawValue == "調味料")
        #expect(Category.grain.rawValue == "米・麺類")
        #expect(Category.drink.rawValue == "飲料")
        #expect(Category.other.rawValue == "その他")
    }

    @Test("Category.allCases が10個の要素を持つ")
    func categoryAllCases() {
        #expect(Category.allCases.count == 10)
    }
}
