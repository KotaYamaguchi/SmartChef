//
//  ShoppingAutoFillServiceTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/13.
//

import SwiftData
import XCTest

@testable import SmartChef

final class ShoppingAutoFillServiceLogicTests: XCTestCase {

    var modelContext: ModelContext!
    var container: ModelContainer!

    override func setUpWithError() throws {
        // In-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: ShoppingItem.self, StockItem.self, MealPlan.self, MealHistory.self,
            configurations: config)
        modelContext = container.mainContext
    }

    override func tearDownWithError() throws {
        modelContext = nil
        container = nil
    }

    // analyzeMissingIngredients のロジックテスト
    // IntelligenceService.mergeShoppingIngredients はモック化が難しい（シングルトンで直接呼び出しているため）
    // そのため、結合テストに近い形になるが、analyzeMissingIngredients のフィルタリングロジックを中心にテストする。
    // ※ IntelligenceService が実際のAPIを叩くとテストが不安定になるため、
    //   本来は IntelligenceService をプロトコル化して注入すべきだが、
    //   今回は構造上難しいため、ロジック部分（在庫・既存リストとの重複排除）が機能しているかを確認する。
    //   ただし、mergeShoppingIngredients が空を返すとテストにならないので、
    //   簡易的なテストに留めるか、可能ならリファクタリングが必要。

    // ここでは、analyzeMissingIngredients が空のレシピリストに対して空を返すか、
    // 入力が正しければエラーなく動作するかを確認するスモークテストを行う。

    func testAnalyzeMissingIngredients_EmpryInput() async throws {
        // needsMerging defaults to true in definition, but let's test explicit false since that's our new target usage
        let candidates = try await ShoppingAutoFillService.analyzeMissingIngredients(
            recipes: [:],
            mealPlans: [],
            stockItems: [],
            existingShoppingItems: [],
            needsMerging: false
        )
        XCTAssertTrue(candidates.isEmpty)
    }

    // analyzeMissingIngredients (merged: false) のスモークテスト
    func testAnalyzeMissingIngredients_NoMerge_EmpryInput() async throws {
        let candidates = try await ShoppingAutoFillService.analyzeMissingIngredients(
            recipes: [:],
            mealPlans: [],
            stockItems: [],
            existingShoppingItems: [],
            needsMerging: false
        )
        XCTAssertTrue(candidates.isEmpty)
    }

    // NOTE: IntelligenceService.shared.mergeShoppingIngredients をモックできないため、
    // これ以上の詳細なロジックテスト（重複排除など）は、実際のAPIコールが発生してしまう恐れがある。
    // 現状のアーキテクチャでは、Serviceの分離が必要。
    // 今回はリファクタリングの範囲を広げすぎないため、空入力のテストのみで最低限の動作確認とする。

    // addSelectedItems のテスト
    func testAddSelectedItems() throws {
        let candidate1 = ShoppingAutoFillService.ShoppingItemCandidate(
            name: "Carrot",
            ingredientAmount: "2",
            isSelected: true,
            sourceMenuName: "Curry",
            category: .vegetables
        )
        let candidate2 = ShoppingAutoFillService.ShoppingItemCandidate(
            name: "Beef",
            ingredientAmount: "300g",
            isSelected: false,  // Not selected
            sourceMenuName: "Curry",
            category: .meat
        )

        let count = try ShoppingAutoFillService.addSelectedItems(
            [candidate1, candidate2], context: modelContext)

        XCTAssertEqual(count, 1)

        let items = try modelContext.fetch(FetchDescriptor<ShoppingItem>())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Carrot")
        XCTAssertEqual(items.first?.category, .vegetables)
    }
}
