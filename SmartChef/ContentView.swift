//
//  ContentView.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/05.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashBordView()
                .tabItem {
                    Label("ダッシュボード", systemImage: "chart.bar.fill")
                }

            ItemStockView()
                .tabItem {
                    Label("冷蔵庫", systemImage: "refrigerator")
                }

            ShoppingListView()
                .tabItem {
                    Label("買い物リスト", systemImage: "cart.fill")
                }

            HistoryView()
                .tabItem {
                    Label("食事履歴", systemImage: "fork.knife")
                }

            NutritionView()
                .tabItem {
                    Label("栄養分析", systemImage: "heart.text.clipboard")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: StockItem.self, ShoppingItem.self, MealHistory.self,
        configurations: config)

    DataMockService.seedMockData(context: container.mainContext)

    return ContentView()
        .modelContainer(container)
}
