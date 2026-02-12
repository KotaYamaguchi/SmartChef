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

    // MARK: - メイン処理

    /// レシピから不足食材を解析して買い物リストに追加する
    /// - Parameters:
    ///   - recipes: dishName → RecipeDetail のマップ
    ///   - mealPlans: 対象の食事計画（dish の食事タイプ特定に使用）
    ///   - stockItems: 現在の在庫
    ///   - existingShoppingItems: 現在の買い物リスト（重複追加を防ぐ）
    ///   - context: SwiftData の ModelContext
    static func fillShoppingList(
        recipes: [String: RecipeDetail],
        mealPlans: [MealPlan],
        stockItems: [StockItem],
        existingShoppingItems: [ShoppingItem],
        context: ModelContext
    ) async throws -> Int {
        print(
            "[ShoppingFill][fillShoppingList] ▶️ 開始 recipes=\(recipes.keys) mealPlans=\(mealPlans.count) stock=\(stockItems.count) existingShopping=\(existingShoppingItems.count)"
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
        print("[ShoppingFill][fillShoppingList] dishToMealLabel=\(dishToMealLabel)")

        // 2. 全レシピから食材を収集（dish, name, amount）
        var rawIngredients: [(name: String, amount: String, dish: String)] = []
        for (dishName, recipe) in recipes {
            for ingredient in recipe.ingredients {
                let trimmedName = ingredient.name.trimmingCharacters(in: .whitespaces)
                let trimmedAmount = ingredient.amount.trimmingCharacters(in: .whitespaces)
                guard !trimmedName.isEmpty else { continue }
                rawIngredients.append((name: trimmedName, amount: trimmedAmount, dish: dishName))
            }
        }
        print("[ShoppingFill][fillShoppingList] 収集食材数=\(rawIngredients.count)")
        guard !rawIngredients.isEmpty else {
            print("[ShoppingFill][fillShoppingList] ⚠️ rawIngredients が空のため終了")
            return 0
        }

        // 3. AI で類似食材を統合
        print("[ShoppingFill][fillShoppingList] AI mergeShoppingIngredients 呼び出し中...")
        let merged = try await IntelligenceService.shared.mergeShoppingIngredients(rawIngredients)
        print("[ShoppingFill][fillShoppingList] マージ結果=\(merged.count)件: \(merged.map { $0.name })")

        // 4. 在庫・既存買い物リストと照合して不足分だけ追加
        let stockNames = Set(stockItems.map { $0.name.lowercased() })
        let shoppingNames = Set(existingShoppingItems.map { $0.name.lowercased() })
        print("[ShoppingFill][fillShoppingList] 在庫名=\(stockNames) | 既存買い物=\(shoppingNames)")

        var insertedCount = 0
        for item in merged {
            let lower = item.name.lowercased()
            if stockNames.contains(lower) {
                print("[ShoppingFill][fillShoppingList] スキップ（在庫あり）: \(item.name)")
                continue
            }
            if shoppingNames.contains(lower) {
                print("[ShoppingFill][fillShoppingList] スキップ（買い物リストに既存）: \(item.name)")
                continue
            }

            // Category に変換（マッチしなければ .other）
            let category = Category.allCases.first { $0.rawValue == item.category } ?? .other

            // sourceMenuName: "鶏の照り焼き（夕食）" のような形式で表示
            let sourceLabel = item.sources.map { dish -> String in
                if let mealLabel = dishToMealLabel[dish] {
                    return "\(dish)（\(mealLabel)）"
                }
                return dish
            }.joined(separator: "、")

            print(
                "[ShoppingFill][fillShoppingList] ➕ 追加: \(item.name) [\(item.category)] \(item.combinedAmount) source=\(sourceLabel)"
            )
            let newItem = ShoppingItem(
                name: item.name,
                category: category,
                count: 1,
                isSelected: false,
                sourceMenuName: sourceLabel.isEmpty ? nil : sourceLabel,
                recipeAmount: item.combinedAmount.isEmpty ? nil : item.combinedAmount
            )
            context.insert(newItem)
            insertedCount += 1
        }

        print("[ShoppingFill][fillShoppingList] context.save() 前 挿入予定数=\(insertedCount)")
        try context.save()
        print("[ShoppingFill][fillShoppingList] ✅ 保存完了")
        return insertedCount
    }

    // MARK: - 既存の自動追加アイテムを削除するユーティリティ

    /// 過去の自動追加分（sourceMenuName が設定されているもの）をすべて削除する
    /// ※ 再生成時に古い自動追加アイテムをクリアしてから再追加するために使用
    static func clearAutoAddedItems(from items: [ShoppingItem], context: ModelContext) {
        for item in items where item.sourceMenuName != nil {
            context.delete(item)
        }
    }
}
