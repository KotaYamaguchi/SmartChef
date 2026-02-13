//
//  Models.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/05.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - レシピ詳細モデル (Codable)

struct Ingredient: Codable {
    var name: String
    var amount: String
}

struct RecipeDetail: Codable {
    var dishName: String
    var ingredients: [Ingredient]
    var steps: [String]
    var cookingTime: String
}

// MARK: - スキャン一時モデル（非永続・確認画面用ステージング）

struct ScannedItem: Identifiable {
    var id = UUID()
    var name: String
    var category: FoodCategory
    var count: Int
    var deadline: Date?
    var hasDeadline: Bool

    init(
        name: String,
        category: FoodCategory = .other,
        count: Int = 1,
        deadline: Date? = nil,
        hasDeadline: Bool = false
    ) {
        self.name = name
        self.category = category
        self.count = count
        self.deadline = deadline
        self.hasDeadline = hasDeadline
    }
}

// MARK: - バーコードキャッシュ（UserDefaults ベースのローカル学習）

struct BarcodeCacheEntry: Codable {
    var name: String
    var category: FoodCategory
}

final class BarcodeCache {
    static let shared = BarcodeCache()
    private let userDefaultsKey = "smartchef_barcode_cache"

    private init() {}

    private var cache: [String: BarcodeCacheEntry] {
        get {
            guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
                let decoded = try? JSONDecoder().decode(
                    [String: BarcodeCacheEntry].self, from: data)
            else { return [:] }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            }
        }
    }

    func get(_ barcode: String) -> BarcodeCacheEntry? {
        cache[barcode]
    }

    func set(_ barcode: String, name: String, category: FoodCategory) {
        var current = cache
        current[barcode] = BarcodeCacheEntry(name: name, category: category)
        cache = current
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - 献立自動生成モード

enum MealPlanGenerationMode: String, CaseIterable {
    /// 午前5時: 今日の朝食・昼食・夕食を生成
    case morning = "morning"
    /// 午後5時: 今夜の夕食 + 明日の朝食・昼食を生成
    case evening = "evening"

    var displayName: String {
        switch self {
        case .morning: return "朝5時モード"
        case .evening: return "夕5時モード"
        }
    }

    var description: String {
        switch self {
        case .morning: return "毎朝5時に今日の朝食・昼食・夕食を生成します"
        case .evening: return "毎夕17時に今夜の夕食と明日の朝食・昼食を生成します"
        }
    }

    /// スケジュール実行時刻（時）
    var scheduledHour: Int {
        switch self {
        case .morning: return 5
        case .evening: return 17
        }
    }
}

// カテゴリはそのままEnumでOK
enum FoodCategory: String, Codable, CaseIterable {
    case vegetables = "野菜"
    case meat = "肉類"
    case seafood = "魚介類"
    case dairy = "乳製品"
    case egg = "卵"
    case fruits = "果物"
    case seasoning = "調味料"
    case grain = "主食"
    case drink = "飲料"
    case other = "その他"

    var iconName: String? {
        switch self {
        case .vegetables: return "food_category_icon_vegetable"
        case .meat: return "food_category_icon_meat"
        case .seafood: return "food_category_icon_fish"
        case .dairy: return "food_category_icon_milk"
        case .egg: return "food_category_icon_egg"
        case .fruits: return "food_category_icon_fruits"
        case .seasoning: return "food_category_icon_seasoning"
        case .grain: return "food_category_icon_bread"
        case .drink: return "food_category_icon_drink"
        default: return nil
        }
    }
}

// MARK: - カテゴリカラー拡張

extension FoodCategory {
    var color: Color {
        switch self {
        case .vegetables: return .green
        case .meat: return .red
        case .seafood: return .blue
        case .dairy: return .yellow
        case .egg: return .orange
        case .fruits: return .pink
        case .seasoning: return .brown
        case .grain: return .indigo
        case .drink: return .cyan
        case .other: return .gray
        }
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "朝食"
    case lunch = "昼食"
    case dinner = "夕食"
}

@Model
final class StockItem {
    var id: UUID
    var name: String
    var category: FoodCategory
    var deadline: Date?
    var count: Int

    init(name: String, category: FoodCategory, deadline: Date? = nil, count: Int = 1) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.deadline = deadline
        self.count = count
    }
}

@Model
final class ShoppingItem {
    var id: UUID
    var name: String
    var category: FoodCategory
    var count: Int
    var isSelected: Bool

    /// どの料理に使う食材か（自動追加時のみ）例: "鶏の照り焼き（夕食）"
    var sourceMenuName: String?
    /// レシピ上の分量表記（自動追加時のみ）例: "300g"、"大さじ2"
    var recipeAmount: String?

    init(
        name: String,
        category: FoodCategory,
        count: Int = 1,
        isSelected: Bool = false,
        sourceMenuName: String? = nil,
        recipeAmount: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.count = count
        self.isSelected = isSelected
        self.sourceMenuName = sourceMenuName
        self.recipeAmount = recipeAmount
    }
}

@Model
final class MealHistory {
    var id: UUID
    var date: Date
    var menuName: String
    var mealType: MealType

    init(date: Date, menuName: String, mealType: MealType) {
        self.id = UUID()
        self.date = date
        self.menuName = menuName
        self.mealType = mealType
    }
}

// MARK: - 食事計画ステータス

enum MealPlanStatus: String, Codable, CaseIterable {
    case planned = "予定"
    case completed = "完了"
    case changed = "変更済"
}

// MARK: - 食事計画モデル

@Model
final class MealPlan {
    var id: UUID
    var date: Date
    var mealType: MealType
    var menuName: String
    var status: MealPlanStatus

    init(date: Date, mealType: MealType, menuName: String, status: MealPlanStatus = .planned) {
        self.id = UUID()
        self.date = date
        self.mealType = mealType
        self.menuName = menuName
        self.status = status
    }

    @Relationship(deleteRule: .cascade) var recipes: [PersistentRecipe]? = []
}

// MARK: - 永続化レシピモデル

@Model
final class PersistentRecipe {
    var id: UUID
    var dishName: String
    var steps: [String]
    var cookingTime: String

    @Relationship(deleteRule: .cascade) var ingredients: [PersistentIngredient]

    init(
        dishName: String, steps: [String], cookingTime: String,
        ingredients: [PersistentIngredient] = []
    ) {
        self.id = UUID()
        self.dishName = dishName
        self.steps = steps
        self.cookingTime = cookingTime
        self.ingredients = ingredients
    }

    /// RecipeDetail (Codable struct) へ変換（既存ロジックとの互換性のため）
    var toDetail: RecipeDetail {
        RecipeDetail(
            dishName: dishName,
            ingredients: ingredients.map { Ingredient(name: $0.name, amount: $0.amount) },
            steps: steps,
            cookingTime: cookingTime
        )
    }
}

@Model
final class PersistentIngredient {
    var id: UUID
    var name: String
    var amount: String

    init(name: String, amount: String) {
        self.id = UUID()
        self.name = name
        self.amount = amount
    }
}
