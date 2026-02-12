//
//  NotificationService.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation
import UserNotifications

// MARK: - ローカル通知サービス

enum NotificationService {

    // MARK: - 通知カテゴリ識別子

    private static let mealPlanReadyCategoryId = "MEAL_PLAN_READY"

    // MARK: - 通知許可リクエスト

    /// アプリ起動時に一度呼び出して通知の許可を要求する
    static func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("[Notification] 許可リクエスト失敗: \(error)")
            } else {
                print("[Notification] 許可状態: \(granted ? "許可" : "拒否")")
            }
        }
    }

    // MARK: - 献立・買い物リスト生成完了通知

    /// 献立生成 → レシピ生成 → 買い物リスト自動補充が完了したことをユーザーに通知する
    /// - Parameters:
    ///   - dishCount: 生成された料理の品目数
    ///   - shoppingItemCount: 買い物リストに追加された食材数
    static func sendMealPlanReadyNotification(dishCount: Int, shoppingItemCount: Int) {
        let center = UNUserNotificationCenter.current()

        // 通知が許可されているか確認
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("[Notification] 通知が許可されていないためスキップ")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "🍽️ 今日の献立が準備できました"

            if shoppingItemCount > 0 {
                content.body = "\(dishCount)品の献立とレシピを生成し、\(shoppingItemCount)件の食材を買い物リストに追加しました。"
            } else {
                content.body = "\(dishCount)品の献立とレシピを生成しました。買い物リストに追加する食材はありませんでした。"
            }

            content.sound = .default
            content.categoryIdentifier = mealPlanReadyCategoryId

            // 即時通知（1秒後）
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "mealPlanReady-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error {
                    print("[Notification] 通知送信失敗: \(error)")
                } else {
                    print("[Notification] ✅ 献立準備完了通知を送信しました")
                }
            }
        }
    }

    /// バックグラウンドタスクで献立が自動生成された場合の通知を送信する
    /// - Parameter mode: 生成モード（朝 or 夕）
    static func sendBackgroundMealPlanNotification(mode: MealPlanGenerationMode) {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = "🍽️ 献立を自動生成しました"

            switch mode {
            case .morning:
                content.body = "今日の朝食・昼食・夕食の献立が準備できました。アプリを開いて確認してください。"
            case .evening:
                content.body = "今夜の夕食と明日の朝食・昼食の献立が準備できました。アプリを開いて確認してください。"
            }

            content.sound = .default
            content.categoryIdentifier = mealPlanReadyCategoryId

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "bgMealPlan-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error {
                    print("[Notification] バックグラウンド通知送信失敗: \(error)")
                } else {
                    print("[Notification] ✅ バックグラウンド献立通知を送信しました")
                }
            }
        }
    }
}
