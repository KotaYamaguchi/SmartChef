//
//  DashBordView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/05.
//

import SwiftData
import SwiftUI

struct DashBordView: View {
    @Environment(\.modelContext) private var modelContext

    /// 在庫（賞味期限でソート）
    @Query(sort: \StockItem.deadline) private var stockItems: [StockItem]

    /// 食事履歴（新着順）
    @Query(sort: \MealHistory.date, order: .reverse) private var history: [MealHistory]

    /// 食事計画（日付・時間順）
    @Query(sort: \MealPlan.date) private var mealPlans: [MealPlan]

    /// 買い物リスト（自動補充の重複チェックに使用）
    @Query private var shoppingItems: [ShoppingItem]

    @State private var isGeneratingMealPlan = false
    @State private var mealPlanError: String?
    @State private var generatedPlanReason: String?

    /// 設定（@Observable で変更時に自動再描画）
    private let settings = AppSettings.shared

    /// レシピ生成が完了したバッチの料理名セット（空 = 未セット）
    @State private var pendingShoppingDishes: Set<String> = []
    /// 買い物リスト自動補充の進行状態
    @State private var isFillingShoppingList = false
    /// レシピ生成完了バナーの表示フラグ
    @State private var showRecipeReadyBanner = false
    /// 前回の generatingDishes が空でなかったかどうか（非空→空の遷移を検知するため）
    @State private var wasGeneratingRecipes = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 1日の食事計画
                dailyMealPlanSection

                // MARK: - 今日使うべき食材（期限が近い順）
                expirySection

                // MARK: - 最近の食事
                recentMealsSection
            }
            .navigationTitle("ダッシュボード")
        }
        .overlay(alignment: .top) {
            if showRecipeReadyBanner {
                recipeReadyBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: IntelligenceService.shared.generatingDishes) { _, generating in
            let intelligence = IntelligenceService.shared
            print(
                "[ShoppingFill][onChange] generatingDishes=\(generating) | pending=\(pendingShoppingDishes) | isFilling=\(isFillingShoppingList)"
            )

            // レシピ生成完了バナー表示: 非空→空の遷移を検知
            if wasGeneratingRecipes && generating.isEmpty {
                withAnimation(.spring(duration: 0.4)) {
                    showRecipeReadyBanner = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(3.0))
                    withAnimation(.easeOut(duration: 0.3)) {
                        showRecipeReadyBanner = false
                    }
                }
            }
            wasGeneratingRecipes = !generating.isEmpty

            guard !pendingShoppingDishes.isEmpty, !isFillingShoppingList else {
                print("[ShoppingFill][onChange] → スキップ（pending空 or 補充中）")
                return
            }

            // まだ生成中の皿がなく、かつ全皿が「永続化済み or エラー済み」になったら発火
            let mode = settings.generationMode
            let relevantPlans = mode == .morning ? todayMealPlans() : eveningBatchPlans()
            // 全レシピを収集
            let allRecipies = relevantPlans.flatMap { $0.recipes ?? [] }

            let allSettled = pendingShoppingDishes.allSatisfy { dish in
                let persisted = allRecipies.contains { $0.dishName == dish }
                let errored = intelligence.recipeErrors[dish] != nil
                print(
                    "[ShoppingFill][onChange]   dish=\(dish) persisted=\(persisted) errored=\(errored)"
                )
                return persisted || errored
            }

            print("[ShoppingFill][onChange] allSettled=\(allSettled)")
            guard allSettled else { return }

            let batchDishes = pendingShoppingDishes
            pendingShoppingDishes = []
            print("[ShoppingFill][onChange] → autoFillShoppingList 開始 dishes=\(batchDishes)")

            Task {
                await autoFillShoppingList(for: batchDishes)
            }
        }
        .task {
            // アプリ起動・フォアグラウンド復帰時のフォールバック:
            // 設定モードの実行時刻以降かつ対象献立がなければ自動生成する
            let hour = Calendar.current.component(.hour, from: Date())
            let mode = settings.generationMode
            let needsGeneration: Bool
            switch mode {
            case .morning:
                needsGeneration = hour >= mode.scheduledHour && todayMealPlans().isEmpty
            case .evening:
                needsGeneration = hour >= mode.scheduledHour && eveningBatchPlans().isEmpty
            }
            guard needsGeneration, !isGeneratingMealPlan else { return }
            generateTodayMealPlan()
        }
    }

    // MARK: - 1日の食事計画セクション

    private var dailyMealPlanSection: some View {
        let mode = settings.generationMode
        let plans = mode == .morning ? todayMealPlans() : eveningBatchPlans()

        let sectionTitle: String = mode == .morning ? "今日の献立" : "今夜・明日の献立"
        let emptyLabel: String = mode == .morning ? "今日の食事計画がありません" : "今夜・明日の食事計画がありません"
        let generateLabel: String = mode == .morning ? "AIで今日の献立を生成" : "AIで今夜・明日の献立を生成"
        let footerHint: String =
            mode == .morning
            ? "AIが冷蔵庫の在庫と食事履歴をもとに今日の献立を提案します"
            : "AIが冷蔵庫の在庫と食事履歴をもとに今夜の夕食と明日の朝食・昼食を提案します"

        return Section {
            if isGeneratingMealPlan {
                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AIが献立を考え中...")
                            .font(.subheadline)
                        Text("在庫と食事履歴をもとに提案しています")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } else if plans.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.blue)
                    Text(emptyLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let error = mealPlanError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.vertical, 2)
                }
                Button {
                    generateTodayMealPlan()
                } label: {
                    Label(generateLabel, systemImage: "sparkles")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            } else {
                // レシピ生成中の全体インジケーター
                if !IntelligenceService.shared.generatingDishes.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        let generatingCount = IntelligenceService.shared.generatingDishes.count
                        Text("\(generatingCount)品のレシピを生成中...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                }
                ForEach(plans) { plan in
                    NavigationLink(destination: MealPlanDetailView(plan: plan)) {
                        MealPlanCard(plan: plan)
                    }
                }
                if let error = mealPlanError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.vertical, 2)
                }
            }
        } header: {
            HStack {
                Label(sectionTitle, systemImage: "list.bullet")
                    .foregroundColor(.blue)
                Spacer()
                if !isGeneratingMealPlan && !plans.isEmpty {
                    Button {
                        generateTodayMealPlan()
                    } label: {
                        Label("AI再生成", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        } footer: {
            if isGeneratingMealPlan || plans.isEmpty {
                Text(footerHint)
                    .font(.caption)
            } else if let reason = generatedPlanReason {
                Text("AI提案: \(reason)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("タップして完了・変更・在庫連動などの操作ができます")
            }
        }
    }

    // MARK: - 期限が近い食材セクション

    private var expirySection: some View {
        let urgent = urgentItems()
        return Section {
            if urgent.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("期限が迫っている食材はありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(urgent) { item in
                    ExpiryItemRow(item: item)
                }
            }
        } header: {
            Label("今日使うべき食材", systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        } footer: {
            if !urgent.isEmpty {
                Text("これらの食材を優先的に使った料理を選びましょう")
                    .font(.caption)
            }
        }
    }

    // MARK: - 最近の食事セクション

    private var recentMealsSection: some View {
        Section {
            if history.isEmpty {
                Text("食事の記録がありません")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(history.prefix(5)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.menuName)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        MealTypeBadge(mealType: item.mealType)
                    }
                }
            }
        } header: {
            Label("最近の食事", systemImage: "fork.knife")
        }
    }

    // MARK: - Helpers

    /// 今日の食事計画を時間順に返す
    private func todayMealPlans() -> [MealPlan] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        return
            mealPlans
            .filter { $0.date >= today && $0.date < tomorrow }
            .sorted { $0.date < $1.date }
    }

    /// 夕5時モードで生成対象の計画（今夜の夕食 + 明日の朝食・昼食）
    private func eveningBatchPlans() -> [MealPlan] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today)!

        let todayDinner = mealPlans.filter {
            $0.date >= today && $0.date < tomorrow && $0.mealType == .dinner
        }
        let tomorrowBL = mealPlans.filter {
            $0.date >= tomorrow && $0.date < dayAfterTomorrow
                && ($0.mealType == .breakfast || $0.mealType == .lunch)
        }
        return (todayDinner + tomorrowBL).sorted { $0.date < $1.date }
    }

    /// 期限警告日数以内に期限が切れる食材（期限が早い順）
    private func urgentItems() -> [StockItem] {
        let threshold =
            Calendar.current.date(
                byAdding: .day,
                value: settings.expiryWarningDays,
                to: Date()
            ) ?? Date()
        return stockItems.filter { item in
            guard let deadline = item.deadline else { return false }
            return deadline <= threshold
        }
    }

    /// 現在の生成モードに合わせて献立を生成し、食事計画として保存する
    private func generateTodayMealPlan() {
        isGeneratingMealPlan = true
        mealPlanError = nil
        generatedPlanReason = nil

        Task {
            do {
                let mode = settings.generationMode
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

                func todayAt(_ h: Int) -> Date {
                    calendar.date(byAdding: .hour, value: h, to: today)!
                }
                func tomorrowAt(_ h: Int) -> Date {
                    calendar.date(byAdding: .hour, value: h, to: tomorrow)!
                }

                switch mode {

                // MARK: 朝5時モード: 今日の朝食・昼食・夕食
                case .morning:
                    for plan in todayMealPlans() { modelContext.delete(plan) }
                    let s = try await IntelligenceService.shared.generateDailyMealPlan(
                        stockItems: Array(stockItems),
                        recentHistory: Array(history)
                    )
                    let newPlans: [MealPlan] = [
                        MealPlan(date: todayAt(8), mealType: .breakfast, menuName: s.breakfast),
                        MealPlan(date: todayAt(12), mealType: .lunch, menuName: s.lunch),
                        MealPlan(date: todayAt(19), mealType: .dinner, menuName: s.dinner),
                    ]
                    for plan in newPlans { modelContext.insert(plan) }
                    try? modelContext.save()
                    generatedPlanReason = s.reason
                    prefetchDishes(from: newPlans)

                // MARK: 夕5時モード: 今夜の夕食 + 明日の朝食・昼食
                case .evening:
                    for plan in eveningBatchPlans() { modelContext.delete(plan) }
                    let s = try await IntelligenceService.shared.generateEveningMealPlan(
                        stockItems: Array(stockItems),
                        recentHistory: Array(history)
                    )
                    let newPlans: [MealPlan] = [
                        MealPlan(date: todayAt(19), mealType: .dinner, menuName: s.dinner),
                        MealPlan(date: tomorrowAt(8), mealType: .breakfast, menuName: s.breakfast),
                        MealPlan(date: tomorrowAt(12), mealType: .lunch, menuName: s.lunch),
                    ]
                    for plan in newPlans { modelContext.insert(plan) }
                    try? modelContext.save()
                    generatedPlanReason = s.reason
                    prefetchDishes(from: newPlans)
                }
            } catch {
                mealPlanError = error.localizedDescription
            }
            isGeneratingMealPlan = false
        }
    }

    /// 献立の各品目レシピを生成・永続化し、完了後の買い物リスト更新に備える
    private func prefetchDishes(from plans: [MealPlan]) {
        let allDishes = plans.flatMap { plan in
            plan.menuName
                .components(separatedBy: "・")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        print("[ShoppingFill][prefetchDishes] dishes=\(allDishes)")
        // 古い自動追加アイテムをクリアしてバッチを登録
        let cleared = shoppingItems.filter { $0.sourceMenuName != nil }
        print("[ShoppingFill][prefetchDishes] 自動追加アイテム削除数=\(cleared.count)")
        ShoppingAutoFillService.clearAutoAddedItems(
            from: Array(shoppingItems), context: modelContext)
        pendingShoppingDishes = Set(allDishes)
        print(
            "[ShoppingFill][prefetchDishes] pendingShoppingDishes セット完了: \(pendingShoppingDishes)")

        // 各プランの各料理についてレシピ生成を開始
        for plan in plans {
            let dishes = plan.menuName
                .components(separatedBy: "・")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            for dish in dishes {
                Task {
                    await IntelligenceService.shared.generateAndPersistRecipe(
                        for: dish, plan: plan, context: modelContext)
                }
            }
        }
    }

    /// レシピ生成完了後に不足食材を買い物リストへ自動追加する
    private func autoFillShoppingList(for dishes: Set<String>) async {
        print("[ShoppingFill][autoFill] 開始 dishes=\(dishes)")

        // 設定を確認: 自動追加がオフならスキップ
        guard settings.autoFillShoppingList else {
            print("[ShoppingFill][autoFill] ⚠️ 自動追加設定がOFFのためスキップ")
            // 通知だけは送る（レシピ生成完了として）
            NotificationService.sendMealPlanReadyNotification(
                dishCount: dishes.count,
                shoppingItemCount: 0
            )
            return
        }

        isFillingShoppingList = true
        defer { isFillingShoppingList = false }

        let mode = settings.generationMode
        let plans = mode == .morning ? todayMealPlans() : eveningBatchPlans()
        print("[ShoppingFill][autoFill] 対象MealPlan数=\(plans.count) mode=\(mode.rawValue)")

        // 永続化されたレシピから辞書を作成
        let allRecipes = plans.flatMap { $0.recipes ?? [] }
        let recipes = dishes.compactMap { dish -> (String, RecipeDetail)? in
            guard let recipe = allRecipes.first(where: { $0.dishName == dish }) else {
                print("[ShoppingFill][autoFill] ⚠️ レシピなし（エラーまたは未生成）: \(dish)")
                return nil
            }
            return (dish, recipe.toDetail)
        }
        let recipesDict = Dictionary(uniqueKeysWithValues: recipes)
        print(
            "[ShoppingFill][autoFill] 有効レシピ数=\(recipesDict.count)/\(dishes.count): \(Array(recipesDict.keys))"
        )
        guard !recipesDict.isEmpty else {
            print("[ShoppingFill][autoFill] ⚠️ 有効レシピ0件のため終了")
            return
        }

        do {
            let addedCount = try await ShoppingAutoFillService.fillShoppingList(
                recipes: recipesDict,
                mealPlans: plans,
                stockItems: Array(stockItems),
                existingShoppingItems: Array(shoppingItems),
                context: modelContext
            )
            print("[ShoppingFill][autoFill] ✅ fillShoppingList 完了")

            // 献立・レシピ・買い物リスト生成完了の通知を送信
            NotificationService.sendMealPlanReadyNotification(
                dishCount: dishes.count,
                shoppingItemCount: addedCount
            )
        } catch {
            print("[ShoppingFill][autoFill] ❌ 失敗: \(error)")
        }
    }

    // MARK: - レシピ生成完了バナー

    private var recipeReadyBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("レシピの生成が完了しました")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showRecipeReadyBanner = false
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.green.gradient)
                .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - 食事計画カード

struct MealPlanCard: View {
    let plan: MealPlan

    /// 献立名を「・」で分割した料理リスト
    private var dishes: [String] {
        plan.menuName
            .components(separatedBy: "・")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// この献立に含まれるいずれかの料理がレシピ生成中か
    private var isAnyDishGenerating: Bool {
        dishes.contains { IntelligenceService.shared.generatingDishes.contains($0) }
    }

    /// この献立のすべての料理のレシピが生成済みか
    private var allDishesHaveRecipe: Bool {
        dishes.allSatisfy { dish in
            plan.recipes?.contains { $0.dishName == dish } ?? false
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // 食事タイプアイコン
            ZStack {
                Circle()
                    .fill(mealTypeColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: mealTypeIcon)
                    .foregroundColor(mealTypeColor)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mealTypeLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(plan.menuName)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(2)
                // レシピ生成状態インジケーター
                if isAnyDishGenerating {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("レシピ生成中")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                } else if allDishesHaveRecipe {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("レシピ準備完了")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            MealPlanStatusBadge(status: plan.status)
        }
        .padding(.vertical, 4)
    }

    /// "2/11 朝食" 形式のラベル
    private var mealTypeLabel: String {
        let dateStr = plan.date.formatted(.dateTime.month().day())
        return "\(dateStr) \(plan.mealType.rawValue)"
    }

    private var mealTypeColor: Color {
        switch plan.mealType {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .indigo
        }
    }

    private var mealTypeIcon: String {
        switch plan.mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        }
    }
}

// MARK: - 食事計画ステータスバッジ

struct MealPlanStatusBadge: View {
    let status: MealPlanStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch status {
        case .planned: return .blue
        case .completed: return .green
        case .changed: return .orange
        }
    }
}

// MARK: - 食事計画詳細・アクション画面

struct MealPlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plan: MealPlan

    @State private var showCompletionSheet = false  // 完了報告 → 在庫連動シート
    @State private var showMenuEditSheet = false  // 献立変更シート（編集・内容変更を統合）
    @State private var editingMenuName = ""
    @State private var showDeleteConfirm = false
    @State private var showIngredientSheet = false  // 手動食材追加シート

    /// 献立名を「・」で分割した料理リスト
    private var dishes: [String] {
        plan.menuName
            .components(separatedBy: "・")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        List {
            // MARK: 計画内容
            Section("計画内容") {
                LabeledContent {
                    Text(plan.date.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.secondary)
                } label: {
                    Label("日付", systemImage: "calendar")
                }

                LabeledContent {
                    Text(plan.mealType.rawValue)
                        .foregroundColor(.secondary)
                } label: {
                    Label("食事", systemImage: "fork.knife")
                }

                LabeledContent {
                    Text(plan.menuName)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("献立", systemImage: "list.bullet.rectangle")
                }

                HStack {
                    Label("ステータス", systemImage: "checkmark.circle")
                    Spacer()
                    MealPlanStatusBadge(status: plan.status)
                }
            }

            // MARK: レシピ（インライン表示）
            ForEach(dishes, id: \.self) { dish in
                DishRecipeSection(
                    dishName: dish,
                    recipe: plan.recipes?.first(where: { $0.dishName == dish })?.toDetail,
                    isGenerating: IntelligenceService.shared.generatingDishes.contains(dish),
                    error: IntelligenceService.shared.recipeErrors[dish],
                    onGenerate: {
                        Task {
                            await IntelligenceService.shared.generateAndPersistRecipe(
                                for: dish, plan: plan, context: modelContext)
                        }
                    }
                )
            }

            // MARK: 報告アクション
            Section {
                // 完了報告 → 在庫連動シートを表示
                Button {
                    showCompletionSheet = true
                } label: {
                    Label("完了報告（計画通りに食べた）", systemImage: "checkmark.circle.fill")
                        .foregroundColor(plan.status == .completed ? .secondary : .green)
                }
                .disabled(plan.status == .completed)

                // 献立を変更（編集・内容変更報告を統合）
                Button {
                    editingMenuName = plan.menuName
                    showMenuEditSheet = true
                } label: {
                    Label("献立を変更", systemImage: "pencil")
                        .foregroundColor(plan.status == .completed ? .secondary : .orange)
                }
                .disabled(plan.status == .completed)

                // 買い物リストへ追加（手動）
                Button {
                    showIngredientSheet = true
                } label: {
                    Label("買い物リストへ追加", systemImage: "cart.badge.plus")
                        .foregroundColor(.blue)
                }
            } header: {
                Text("報告")
            } footer: {
                Text("報告すると食事履歴に記録されます")
            }

            // MARK: 削除
            Section("管理") {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Label("この計画を削除", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(plan.mealType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 未生成の品目のレシピ生成を開始（永続化済みはスキップ）
            let intelligence = IntelligenceService.shared
            let pending = dishes.filter { dish in
                let hasRecipe = plan.recipes?.contains { $0.dishName == dish } ?? false
                return !hasRecipe && !intelligence.generatingDishes.contains(dish)
            }
            if !pending.isEmpty {
                for dish in pending {
                    Task {
                        await intelligence.generateAndPersistRecipe(
                            for: dish, plan: plan, context: modelContext)
                    }
                }
            }
        }
        // 完了報告 → 在庫連動シート
        .sheet(isPresented: $showCompletionSheet) {
            StockUpdateSheet(plan: plan) {
                markAsCompleted()
            }
        }
        // 献立変更シート（編集・内容変更報告を統合）
        .sheet(isPresented: $showMenuEditSheet) {
            EditMenuSheet(
                originalMenuName: plan.menuName,
                menuName: $editingMenuName
            ) {
                editMenuName(to: editingMenuName)
            }
            .presentationDetents([.medium])
        }
        // 手動食材追加シート
        .sheet(isPresented: $showIngredientSheet) {
            IngredientSelectionSheet(mealPlans: [plan])
        }
        // 削除確認ダイアログ
        .confirmationDialog(
            "この食事計画を削除しますか？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) { deletePlan() }
            Button("キャンセル", role: .cancel) {}
        }
    }

    // MARK: - Actions

    /// 完了報告: 計画通りに食事した（在庫減算は StockUpdateSheet 側で実施済み）
    private func markAsCompleted() {
        plan.status = .completed
        let entry = MealHistory(date: plan.date, menuName: plan.menuName, mealType: plan.mealType)
        modelContext.insert(entry)
        try? modelContext.save()
    }

    /// 献立を変更: 名前を更新し、完了済みでなければステータスを「変更済」に更新する
    private func editMenuName(to newMenuName: String) {
        let trimmed = newMenuName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != plan.menuName else { return }
        plan.menuName = trimmed
        if plan.status != .completed {
            plan.status = .changed
        }
        try? modelContext.save()

        // 変更後の献立名に含まれる品目のレシピを生成・永続化
        let newDishes =
            trimmed
            .components(separatedBy: "・")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for dish in newDishes {
            Task {
                await IntelligenceService.shared.generateAndPersistRecipe(
                    for: dish, plan: plan, context: modelContext)
            }
        }
    }

    /// 食事計画を削除
    private func deletePlan() {
        modelContext.delete(plan)
        try? modelContext.save()
        dismiss()
    }

}

// MARK: - 献立変更シート（編集・内容変更報告を統合）

struct EditMenuSheet: View {
    let originalMenuName: String
    @Binding var menuName: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("現在の献立") {
                    Text(originalMenuName)
                        .foregroundColor(.secondary)
                }
                Section("変更後の献立") {
                    TextField("献立名を入力", text: $menuName)
                }
            }
            .navigationTitle("献立を変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onConfirm()
                        dismiss()
                    }
                    .disabled(menuName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 完了報告・在庫連動シート

struct StockUpdateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// カテゴリ順・名前順で在庫全件取得
    @Query(sort: \StockItem.name) private var stockItems: [StockItem]

    let plan: MealPlan
    let onConfirm: () -> Void  // 呼び出し元で plan.status 更新

    /// キー: StockItem.id, 値: 今回使う個数
    @State private var usageCounts: [UUID: Int] = [:]

    // 在庫が存在するカテゴリだけを表示順で返す
    private var availableCategories: [Category] {
        let withStock = stockItems.filter { $0.count > 0 }
        let present = Set(withStock.map { $0.category })
        return Category.allCases.filter { present.contains($0) }
    }

    private func items(in category: Category) -> [StockItem] {
        stockItems.filter { $0.category == category && $0.count > 0 }
    }

    /// 1件でも使用個数が入力されているか
    private var hasAnyUsage: Bool {
        usageCounts.values.contains { $0 > 0 }
    }

    var body: some View {
        NavigationStack {
            List {
                // --- ヘッダー情報 ---
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.menuName)
                                .font(.subheadline)
                                .bold()
                            Text(
                                plan.date.formatted(.dateTime.month().day())
                                    + " \(plan.mealType.rawValue)"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("完了報告する献立")
                } footer: {
                    Text("使用した食材の個数をタップで調整してください。変更しない食材はそのままで構いません。")
                }

                // --- 在庫一覧 ---
                if availableCategories.isEmpty {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "tray")
                                .foregroundColor(.secondary)
                            Text("在庫に登録された食材がありません")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    ForEach(availableCategories, id: \.self) { category in
                        Section(category.rawValue) {
                            ForEach(items(in: category)) { item in
                                StockUsageRow(
                                    item: item,
                                    usageCount: Binding(
                                        get: { usageCounts[item.id] ?? 0 },
                                        set: { usageCounts[item.id] = $0 }
                                    )
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("使用した食材を記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了報告する") {
                        applyStockChanges()
                        onConfirm()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    /// 入力された使用個数を在庫に反映する
    private func applyStockChanges() {
        for (id, usedCount) in usageCounts where usedCount > 0 {
            guard let item = stockItems.first(where: { $0.id == id }) else { continue }
            item.count = max(0, item.count - usedCount)
        }
        try? modelContext.save()
    }
}

// MARK: - 在庫使用個数コントロール行

struct StockUsageRow: View {
    let item: StockItem
    @Binding var usageCount: Int

    private var remaining: Int { item.count - usageCount }

    var body: some View {
        HStack(spacing: 12) {
            // 食材情報
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline)
                    .bold()
                HStack(spacing: 4) {
                    Text("在庫 \(item.count) 個")
                    if usageCount > 0 {
                        Text("→ 残 \(remaining) 個")
                            .foregroundColor(remaining == 0 ? .red : .orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                if let deadline = item.deadline {
                    Text(deadlineLabel(deadline))
                        .font(.caption2)
                        .foregroundColor(deadlineColor(deadline))
                }
            }

            Spacer()

            // ±ボタン + 個数表示
            HStack(spacing: 0) {
                Button {
                    if usageCount > 0 { usageCount -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(
                            usageCount > 0 ? .red.opacity(0.85) : .secondary.opacity(0.4))
                }
                .buttonStyle(.plain)

                Text("\(usageCount)")
                    .font(.title3)
                    .bold()
                    .monospacedDigit()
                    .frame(minWidth: 36)
                    .multilineTextAlignment(.center)
                    .foregroundColor(usageCount > 0 ? .primary : .secondary)

                Button {
                    if usageCount < item.count { usageCount += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(
                            usageCount < item.count ? .blue.opacity(0.85) : .secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func deadlineLabel(_ date: Date) -> String {
        let days =
            Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: Date()),
                to: Calendar.current.startOfDay(for: date)
            ).day ?? 0
        switch days {
        case ..<0: return "期限切れ"
        case 0: return "今日まで"
        case 1: return "あと 1 日"
        default: return "あと \(days) 日"
        }
    }

    private func deadlineColor(_ date: Date) -> Color {
        let days =
            Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: Date()),
                to: Calendar.current.startOfDay(for: date)
            ).day ?? 0
        switch days {
        case ..<1: return .red
        case 1...3: return .orange
        default: return .secondary
        }
    }
}

// MARK: - 期限表示行

struct ExpiryItemRow: View {
    let item: StockItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .bold()
                Text(item.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let deadline = item.deadline {
                    Text(daysLabel(deadline: deadline))
                        .font(.caption)
                        .bold()
                        .foregroundColor(daysColor(deadline: deadline))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(daysColor(deadline: deadline).opacity(0.12))
                        .clipShape(Capsule())
                }
                Text("残り \(item.count) 個")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func daysLabel(deadline: Date) -> String {
        let days =
            Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: Date()),
                to: Calendar.current.startOfDay(for: deadline)
            ).day ?? 0
        switch days {
        case ..<0: return "期限切れ"
        case 0: return "今日まで"
        case 1: return "あと1日"
        default: return "あと\(days)日"
        }
    }

    private func daysColor(deadline: Date) -> Color {
        let days =
            Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: Date()),
                to: Calendar.current.startOfDay(for: deadline)
            ).day ?? 0
        switch days {
        case ..<1: return .red
        case 1...3: return .orange
        default: return .yellow
        }
    }
}

// MARK: - 食事タイプバッジ

struct MealTypeBadge: View {
    let mealType: MealType

    var body: some View {
        Text(mealType.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self,
        configurations: config)
    DataMockService.seedMockData(context: container.mainContext)

    return DashBordView()
        .modelContainer(container)
}
