//
//  NutritionView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/10.
//

import FoundationModels
import SwiftData
import SwiftUI

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MealHistory.date, order: .reverse) private var history: [MealHistory]
    @Query private var stockItems: [StockItem]

    @State private var analysis: NutritionAnalysis?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isAnalyzing {
                        analyzingView
                    } else if let analysis {
                        analysisResultView(analysis)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("栄養分析")
            .toolbar {
                if analysis != nil && !isAnalyzing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: runAnalysis) {
                            Label("再分析", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }

    // MARK: - 分析中ビュー

    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .padding(.top, 60)
            Text("AIが食事記録を分析中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("直近\(min(history.count, 42))食分のデータを処理しています")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 未分析の初期状態

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 64))
                .foregroundColor(.blue.opacity(0.7))

            VStack(spacing: 8) {
                Text("栄養バランスを分析します")
                    .font(.title3)
                    .bold()
                Text("食事記録をもとにAIが栄養バランスを評価し、\n不足している栄養素と\nおすすめ食材を提案します")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: runAnalysis) {
                Label("分析を開始", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            if history.isEmpty {
                Text("食事の記録が少ないと精度が下がります。\nまずは「食事履歴」に食事を記録しましょう。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 分析結果ビュー

    @ViewBuilder
    private func analysisResultView(_ analysis: NutritionAnalysis) -> some View {
        // 総評カード
        VStack(alignment: .leading, spacing: 10) {
            Label("AIによる評価", systemImage: "sparkles")
                .font(.headline)
                .foregroundColor(.blue)
            Text(analysis.summary)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.07))
        .cornerRadius(12)

        // 不足栄養素
        if !analysis.missingNutrients.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("不足している栄養素", systemImage: "exclamationmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                NutrientTagsView(tags: analysis.missingNutrients, color: .orange)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.orange.opacity(0.07))
            .cornerRadius(12)
        }

        // おすすめ食材
        if !analysis.recommendedFoods.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("おすすめ食材", systemImage: "leaf.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                NutrientTagsView(tags: analysis.recommendedFoods, color: .green)

                Button(action: { addRecommendedToShoppingList(analysis.recommendedFoods) }) {
                    Label("買い物リストに追加", systemImage: "cart.badge.plus")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.green.opacity(0.07))
            .cornerRadius(12)
        }

        // アドバイス
        VStack(alignment: .leading, spacing: 10) {
            Label("改善アドバイス", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.yellow)
            Text(analysis.advice)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.yellow.opacity(0.07))
        .cornerRadius(12)

        // 分析対象件数
        Text("直近\(min(history.count, 42))食分のデータをもとにAIが推定した結果です")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.bottom)
    }

    // MARK: - アクション

    private func runAnalysis() {
        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                analysis = try await IntelligenceService.shared.analyzeMealHistory(history)
            } catch {
                errorMessage = error.localizedDescription
            }
            isAnalyzing = false
        }
    }

    /// おすすめ食材を冷蔵庫にない分だけ買い物リストに追加
    private func addRecommendedToShoppingList(_ foods: [String]) {
        let stockNames = Set(stockItems.map { $0.name })
        for food in foods {
            if !stockNames.contains(food) {
                let item = ShoppingItem(name: food, category: .other)
                modelContext.insert(item)
            }
        }
    }
}

// MARK: - 栄養素タグ表示

struct TagLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if currentX + subviewSize.width > containerWidth && currentX != 0 {
                currentX = 0
                currentY += lineHeight + 6 // 行間のスペーシング
                totalHeight += lineHeight + 6
                lineHeight = 0
            }

            lineHeight = max(lineHeight, subviewSize.height)
            currentX += subviewSize.width + 6 // タグ間のスペーシング
        }
        totalHeight += lineHeight

        return CGSize(width: containerWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let containerWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if currentX + subviewSize.width > containerWidth && currentX != bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + 6 // 行間のスペーシング
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, subviewSize.height)
            currentX += subviewSize.width + 6 // タグ間のスペーシング
        }
    }
}

struct NutrientTagsView: View {
    let tags: [String]
    let color: Color

    var body: some View {
        TagLayout {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: StockItem.self, ShoppingItem.self, MealHistory.self,
        configurations: config)
    DataMockService.seedMockData(context: container.mainContext)

    return NutritionView()
        .modelContainer(container)
}
