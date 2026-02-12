//
//  MealPlanScheduler.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import BackgroundTasks
import Foundation
import SwiftData

// MARK: - 自動献立生成スケジューラ
//
// ⚠️ Xcode セットアップ手順（初回のみ）:
// 1. Target → Signing & Capabilities → "＋ Capability" → "Background Modes" を追加し
//    "Background fetch" にチェックを入れる
// 2. Target → Info → カスタムiOSターゲットプロパティに以下を追加:
//    Key  : BGTaskSchedulerPermittedIdentifiers (Array)
//    Item 0: com.kotayamaguchi.SmartChef.dailyMealPlan

enum MealPlanScheduler {

    static let taskIdentifier = "com.kotayamaguchi.SmartChef.dailyMealPlan"

    // MARK: - 登録（アプリ起動時に一度だけ呼ぶ）

    static func registerHandler(modelContainer: ModelContainer) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleTask(refreshTask, modelContainer: modelContainer)
        }
    }

    // MARK: - 現在のモードに合わせて次回スケジュールを登録する

    static func scheduleNextGeneration() {
        let mode = AppSettings.shared.generationMode
        // 既存のスケジュールをキャンセルして再登録（モード変更時に確実に更新）
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = nextScheduledTime(for: mode)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[MealPlanScheduler] スケジュール失敗: \(error)")
        }
    }

    // MARK: - バックグラウンドタスク実行

    private static func handleTask(_ task: BGAppRefreshTask, modelContainer: ModelContainer) {
        // 次回をスケジュール（先に登録しておく）
        scheduleNextGeneration()

        let operation = Task {
            do {
                let context = ModelContext(modelContainer)
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                let allPlans = (try? context.fetch(FetchDescriptor<MealPlan>())) ?? []

                let mode = AppSettings.shared.generationMode

                switch mode {

                // MARK: 朝5時モード: 今日の朝食・昼食・夕食
                case .morning:
                    let todayPlans = allPlans.filter { $0.date >= today && $0.date < tomorrow }
                    guard todayPlans.isEmpty else {
                        task.setTaskCompleted(success: true)
                        return
                    }
                    let (stockItems, history) = try fetchStockAndHistory(from: context)
                    let suggestion = try await IntelligenceService.shared.generateDailyMealPlan(
                        stockItems: stockItems,
                        recentHistory: history
                    )
                    let newPlans: [MealPlan] = [
                        MealPlan(
                            date: calendar.date(byAdding: .hour, value: 8, to: today)!,
                            mealType: .breakfast, menuName: suggestion.breakfast),
                        MealPlan(
                            date: calendar.date(byAdding: .hour, value: 12, to: today)!,
                            mealType: .lunch, menuName: suggestion.lunch),
                        MealPlan(
                            date: calendar.date(byAdding: .hour, value: 19, to: today)!,
                            mealType: .dinner, menuName: suggestion.dinner),
                    ]
                    for plan in newPlans { context.insert(plan) }
                    try context.save()
                    prefetchDishes(from: suggestion)

                // MARK: 夕5時モード: 今夜の夕食 + 明日の朝食・昼食
                case .evening:
                    let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today)!
                    let todayDinner = allPlans.filter {
                        $0.date >= today && $0.date < tomorrow && $0.mealType == .dinner
                    }
                    let tomorrowBL = allPlans.filter {
                        $0.date >= tomorrow && $0.date < dayAfterTomorrow
                            && ($0.mealType == .breakfast || $0.mealType == .lunch)
                    }
                    guard todayDinner.isEmpty && tomorrowBL.count < 2 else {
                        task.setTaskCompleted(success: true)
                        return
                    }
                    let (stockItems, history) = try fetchStockAndHistory(from: context)
                    let suggestion = try await IntelligenceService.shared.generateEveningMealPlan(
                        stockItems: stockItems,
                        recentHistory: history
                    )
                    let newPlans: [MealPlan] = [
                        MealPlan(
                            date: calendar.date(byAdding: .hour, value: 19, to: today)!,
                            mealType: .dinner, menuName: suggestion.dinner),
                        MealPlan(
                            date: calendar.date(byAdding: .hour, value: 8, to: tomorrow)!,
                            mealType: .breakfast, menuName: suggestion.breakfast),
                        MealPlan(
                            date: calendar.date(byAdding: .hour, value: 12, to: tomorrow)!,
                            mealType: .lunch, menuName: suggestion.lunch),
                    ]
                    for plan in newPlans { context.insert(plan) }
                    try context.save()
                    prefetchDishes(from: suggestion)
                }

                // バックグラウンドで献立生成が完了したことを通知
                NotificationService.sendBackgroundMealPlanNotification(mode: mode)

                task.setTaskCompleted(success: true)
            } catch {
                print("[MealPlanScheduler] 生成失敗: \(error)")
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            operation.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - ヘルパー

    /// 在庫と食事履歴を取得する
    private static func fetchStockAndHistory(from context: ModelContext) throws -> (
        [StockItem], [MealHistory]
    ) {
        let stockItems =
            (try? context.fetch(
                FetchDescriptor<StockItem>(sortBy: [SortDescriptor(\StockItem.deadline)])
            )) ?? []
        let history =
            (try? context.fetch(
                FetchDescriptor<MealHistory>(sortBy: [
                    SortDescriptor(\MealHistory.date, order: .reverse)
                ])
            )) ?? []
        return (stockItems, history)
    }

    /// 献立の各品目レシピをプリフェッチする
    private static func prefetchDishes(from suggestion: DailyMealPlan) {
        let allDishes = [suggestion.breakfast, suggestion.lunch, suggestion.dinner]
            .flatMap { $0.components(separatedBy: "・") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        IntelligenceService.shared.prefetchRecipes(for: allDishes)
    }

    /// 現在のモードに合わせた次回スケジュール時刻を計算する
    private static func nextScheduledTime(for mode: MealPlanGenerationMode) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = mode.scheduledHour
        components.minute = 0
        components.second = 0
        guard let scheduledTime = calendar.date(from: components) else { return now }
        // すでに今日の実行時刻を過ぎていれば翌日にスケジュール
        return now >= scheduledTime
            ? calendar.date(byAdding: .day, value: 1, to: scheduledTime) ?? scheduledTime
            : scheduledTime
    }
}
