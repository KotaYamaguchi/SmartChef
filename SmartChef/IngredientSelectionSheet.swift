//
//  IngredientSelectionSheet.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/13.
//

import SwiftData
import SwiftUI

struct IngredientSelectionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mealPlans: [MealPlan]

    // 状態管理
    @State private var candidates: [ShoppingAutoFillService.ShoppingItemCandidate] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    // クエリ
    @Query private var stockItems: [StockItem]
    @Query private var shoppingItems: [ShoppingItem]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("食材を解析中...")
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("エラーが発生しました", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("再試行") {
                            Task { await analyze() }
                        }
                    }
                } else if candidates.isEmpty {
                    ContentUnavailableView {
                        Label("追加する食材はありません", systemImage: "basket")
                    } description: {
                        Text("不足している食材は見つかりませんでした。\n在庫また買い物リストに既に存在するか、レシピが生成されていません。")
                    }
                } else {
                    List {
                        Section {
                            ForEach($candidates) { $item in
                                HStack {
                                    Image(
                                        systemName: item.isSelected
                                            ? "checkmark.circle.fill" : "circle"
                                    )
                                    .foregroundColor(item.isSelected ? .green : .secondary)
                                    .font(.title3)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.body)
                                        if !item.ingredientAmount.isEmpty {
                                            Text(item.ingredientAmount)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        if !item.sourceMenuName.isEmpty {
                                            Text(item.sourceMenuName)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    HStack(spacing: 4) {
                                        if let iconName = item.category.iconName {
                                            Image(iconName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 14, height: 14)
                                        }
                                        Text(item.category.rawValue)
                                    }
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    item.isSelected.toggle()
                                }
                            }
                        } header: {
                            Text("追加する食材を選択")
                        } footer: {
                            Text("チェックを入れた食材が買い物リストに追加されます。")
                        }
                    }
                }
            }
            .navigationTitle("食材の追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addItems()
                    }
                    .disabled(candidates.filter { $0.isSelected }.isEmpty)
                }
            }
            .task {
                await analyze()
            }
        }
    }

    private func analyze() async {
        isLoading = true
        errorMessage = nil

        do {
            // 対象のDishを抽出
            let dishes = mealPlans.flatMap { plan in
                plan.menuName.components(separatedBy: "・")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }

            // レシピを取得（永続化済みのものだけ）
            let allRecipes = mealPlans.flatMap { $0.recipes ?? [] }
            let recipes: [String: RecipeDetail] = dishes.reduce(into: [:]) { dict, dish in
                if let recipe = allRecipes.first(where: { $0.dishName == dish }) {
                    dict[dish] = recipe.toDetail
                }
            }

            guard !recipes.isEmpty else {
                candidates = []
                isLoading = false
                return
            }

            // 解析実行
            candidates = try await ShoppingAutoFillService.analyzeMissingIngredients(
                recipes: recipes,
                mealPlans: mealPlans,
                stockItems: stockItems,
                existingShoppingItems: shoppingItems,
                needsMerging: false
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func addItems() {
        do {
            let count = try ShoppingAutoFillService.addSelectedItems(
                candidates, context: modelContext)
            // 必要ならNotificationServiceで通知するが、手動操作なのでトースト等でも良い
            // ここではシンプルに閉じる
            print("手動追加完了: \(count)件")
            dismiss()
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
        }
    }
}
