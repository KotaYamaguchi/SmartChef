//
//  SmartChefApp.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/05.
//

import BackgroundTasks
import SwiftData
import SwiftUI

@main
struct SmartChefApp: App {

    // BGTaskScheduler へ渡すためにコンテナを手動生成する
    private let container: ModelContainer = {
        let schema = Schema([StockItem.self, ShoppingItem.self, MealHistory.self, MealPlan.self])
        return try! ModelContainer(for: schema)
    }()

    init() {
        // バックグラウンドタスクのハンドラ登録（起動完了前に必須）
        MealPlanScheduler.registerHandler(modelContainer: container)
        // 次回の午前5時自動生成をスケジュール
        MealPlanScheduler.scheduleNextGeneration()
        // ローカル通知の許可をリクエスト
        NotificationService.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
