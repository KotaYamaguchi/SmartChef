//
//  ShoppingAutoFillService.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation
import SwiftData

// MARK: - レシピ→買い物リスト自動補充サービス

enum ShoppingAutoFillService {

    // MARK: - データモデル

    /// 買い物リストへの追加候補
    struct ShoppingItemCandidate: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let ingredientAmount: String
        var isSelected: Bool = true
        let sourceMenuName: String  // "鶏の照り焼き（夕食）" などの表示用
        let category: Category
    }

    // MARK: - メイン処理

    /// レシピから不足食材を解析して候補リストを返す
    /// - Parameters:
    ///   - needsMerging: 食材をマージするかどうか（true: 自動, false: 手動）
    /// - Returns: 追加候補のリスト（在庫・既存リストとの重複を除外済み）
    static func analyzeMissingIngredients(
        recipes: [String: RecipeDetail],
        mealPlans: [MealPlan],
        stockItems: [StockItem],
        existingShoppingItems: [ShoppingItem],
        needsMerging: Bool = true
    ) async throws -> [ShoppingItemCandidate] {
        print(
            "[ShoppingFill][analyze] ▶️ 開始 recipes=\(recipes.keys) mealPlans=\(mealPlans.count) merging=\(needsMerging)"
        )

        // 1. 料理名 → 食事タイプのマッピング（表示用ラベル作成に使用）
        var dishToMealLabel: [String: String] = [:]
        for plan in mealPlans {
            let dishes = plan.menuName
                .components(separatedBy: "・")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            for dish in dishes {
                dishToMealLabel[dish] = plan.mealType.rawValue
            }
        }

        // 2. 全レシピから食材を収集
        var rawIngredients: [(name: String, amount: String, dish: String)] = []
        for (dishName, recipe) in recipes {
            for ingredient in recipe.ingredients {
                let trimmedName = ingredient.name.trimmingCharacters(in: .whitespaces)
                let trimmedAmount = ingredient.amount.trimmingCharacters(in: .whitespaces)
                guard !trimmedName.isEmpty else { continue }
                rawIngredients.append((name: trimmedName, amount: trimmedAmount, dish: dishName))
            }
        }
        guard !rawIngredients.isEmpty else { return [] }

        // 3. AI で類似食材を統合 or カテゴリ判定のみ
        let analyzedIngredients: [MergedShoppingIngredient]
        if needsMerging {
            analyzedIngredients = try await IntelligenceService.shared.mergeShoppingIngredients(
                rawIngredients)
        } else {
            analyzedIngredients = try await IntelligenceService.shared
                .categorizeShoppingIngredients(rawIngredients)
        }

        // 4. 在庫・既存買い物リストと照合して不足分だけ抽出
        let stockNames = Set(stockItems.map { $0.name.lowercased() })
        let shoppingNames = Set(existingShoppingItems.map { $0.name.lowercased() })

        var candidates: [ShoppingItemCandidate] = []

        for item in analyzedIngredients {
            let lower = item.name.lowercased()
            // マージしないモードでも、全く同じ名前があれば除外する
            if stockNames.contains(lower) || shoppingNames.contains(lower) {
                continue
            }

            // Category に変換
            let category = Category.allCases.first { $0.rawValue == item.category } ?? .other

            // sourceMenuName 作成
            let sourceLabel = item.sources.map { dish -> String in
                if let mealLabel = dishToMealLabel[dish] {
                    return "\(dish)（\(mealLabel)）"
                }
                return dish
            }.joined(separator: "、")

            // バリデーション済み分量 (combinedAmount or ingredientAmount)
            let validAmount: String = {
                let s = item.combinedAmount.trimmingCharacters(in: .whitespaces)
                return (!s.isEmpty && s.count <= 20) ? s : ""
            }()

            candidates.append(
                ShoppingItemCandidate(
                    name: item.name,
                    ingredientAmount: validAmount,
                    isSelected: true,
                    sourceMenuName: sourceLabel,
                    category: category
                )
            )
        }

        print("[ShoppingFill][analyze] 候補数=\(candidates.count)")
        return candidates
    }

    /// 候補リストを実際に買い物リストへ保存する
    static func addSelectedItems(
        _ candidates: [ShoppingItemCandidate],
        context: ModelContext
    ) throws -> Int {
        var count = 0
        for candidate in candidates where candidate.isSelected {
            let newItem = ShoppingItem(
                name: candidate.name,
                category: candidate.category,
                count: 1,
                isSelected: false,
                sourceMenuName: candidate.sourceMenuName.isEmpty ? nil : candidate.sourceMenuName,
                recipeAmount: candidate.ingredientAmount.isEmpty ? nil : candidate.ingredientAmount
            )
            context.insert(newItem)
            count += 1
        }
        try context.save()
        return count
    }

    /// レシピから不足食材を解析して買い物リストに追加する（従来互換）
    static func fillShoppingList(
        recipes: [String: RecipeDetail],
        mealPlans: [MealPlan],
        stockItems: [StockItem],
        existingShoppingItems: [ShoppingItem],
        context: ModelContext
    ) async throws -> Int {
        let candidates = try await analyzeMissingIngredients(
            recipes: recipes,
            mealPlans: mealPlans,
            stockItems: stockItems,
            existingShoppingItems: existingShoppingItems,
            needsMerging: false  // 自動追加時もマージしない
        )
        return try addSelectedItems(candidates, context: context)
    }

    // MARK: - 既存の自動追加アイテムを削除するユーティリティ

    /// 過去の自動追加分（sourceMenuName が設定されているもの）をすべて削除する
    static func clearAutoAddedItems(from items: [ShoppingItem], context: ModelContext) {
        for item in items where item.sourceMenuName != nil {
            context.delete(item)
        }
    }
}
