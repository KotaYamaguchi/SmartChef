//
//  RecipeView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import SwiftUI

// MARK: - レシピ一覧ビュー

struct RecipeView: View {
    let menuName: String

    /// 献立名を「・」で分割して1品ずつに変換
    private var dishes: [String] {
        menuName
            .components(separatedBy: "・")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// IntelligenceService を observe してキャッシュ・生成状態を反映する
    private var intelligence: IntelligenceService { IntelligenceService.shared }

    private var allGenerated: Bool {
        dishes.allSatisfy { intelligence.cachedRecipes[$0] != nil }
    }

    private var anyGenerating: Bool {
        dishes.contains { intelligence.generatingDishes.contains($0) }
    }

    var body: some View {
        List {
            ForEach(dishes, id: \.self) { dish in
                DishRecipeSection(
                    dishName:     dish,
                    recipe:       intelligence.cachedRecipes[dish],
                    isGenerating: intelligence.generatingDishes.contains(dish),
                    error:        intelligence.recipeErrors[dish],
                    onGenerate:   { intelligence.prefetchRecipes(for: [dish]) }
                )
            }
        }
        .navigationTitle("レシピ")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if anyGenerating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("すべて生成") {
                        let pending = dishes.filter { intelligence.cachedRecipes[$0] == nil }
                        intelligence.prefetchRecipes(for: pending)
                    }
                    .disabled(allGenerated)
                }
            }
        }
        .onAppear {
            // キャッシュにない品目だけ生成を開始（プリフェッチ済みの場合はスキップ）
            let pending = dishes.filter {
                intelligence.cachedRecipes[$0] == nil &&
                !intelligence.generatingDishes.contains($0)
            }
            if !pending.isEmpty {
                intelligence.prefetchRecipes(for: pending)
            }
        }
    }
}

// MARK: - 1品のレシピセクション

struct DishRecipeSection: View {
    let dishName:     String
    let recipe:       RecipeDetail?
    let isGenerating: Bool
    let error:        String?
    let onGenerate:   () -> Void

    var body: some View {
        Section {
            if isGenerating {
                generatingRow
            } else if let recipe {
                recipeContent(recipe)
            } else {
                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.vertical, 2)
                }
                generateButton
            }
        } header: {
            Text(dishName)
        }
    }

    // MARK: - ローディング行

    private var generatingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("レシピを生成中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - 生成ボタン

    private var generateButton: some View {
        Button(action: onGenerate) {
            Label("レシピを生成", systemImage: "sparkles")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - レシピ本文

    @ViewBuilder
    private func recipeContent(_ recipe: RecipeDetail) -> some View {
        // 調理時間
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            Text(recipe.cookingTime)
                .foregroundColor(.secondary)
        }
        .font(.caption)
        .padding(.vertical, 2)

        // 材料セクション
        ingredientsView(recipe.ingredients)

        // 作り方セクション
        stepsView(recipe.steps)
    }

    // MARK: - 材料リスト

    private func ingredientsView(_ ingredients: [Ingredient]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("材料（2人前）", systemImage: "cart")
                .font(.subheadline)
                .bold()
                .foregroundColor(.green)
                .padding(.top, 4)

            ForEach(ingredients, id: \.name) { ingredient in
                HStack {
                    Text(ingredient.name)
                        .font(.subheadline)
                    Spacer()
                    Text(ingredient.amount)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                .padding(.vertical, 1)
                Divider()
            }
        }
    }

    // MARK: - 調理手順

    private func stepsView(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("作り方", systemImage: "frying.pan")
                .font(.subheadline)
                .bold()
                .foregroundColor(.orange)
                .padding(.top, 4)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    // ステップ番号バッジ
                    Text("\(index + 1)")
                        .font(.caption2)
                        .bold()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .padding(.top, 1)

                    Text(step)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecipeView(menuName: "鶏もも肉の照り焼き・ほうれん草の胡麻和え・豆腐の味噌汁・白米")
    }
}
