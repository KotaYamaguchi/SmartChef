//
//  BarcodeCacheTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation
import Testing

@testable import SmartChef

// MARK: - BarcodeCache Tests

struct BarcodeCacheTests {

    /// 各テストの前にキャッシュをリセットする
    private func resetCache() {
        BarcodeCache.shared.reset()
    }

    @Test("BarcodeCache.shared がシングルトンインスタンスを返す")
    func sharedIsSingleton() {
        let a = BarcodeCache.shared
        let b = BarcodeCache.shared
        #expect(a === b)
    }

    @Test("存在しないバーコードに対して nil を返す")
    func getNonExistentBarcode() {
        resetCache()
        let result = BarcodeCache.shared.get("9999999999999")
        #expect(result == nil)
    }

    @Test("バーコードを保存して取得できる")
    func setAndGet() {
        resetCache()
        BarcodeCache.shared.set("4901234567890", name: "牛乳", category: .dairy)

        let result = BarcodeCache.shared.get("4901234567890")
        #expect(result != nil)
        #expect(result?.name == "牛乳")
        #expect(result?.category == .dairy)
    }

    @Test("同じバーコードを上書き更新できる")
    func overwriteExisting() {
        resetCache()
        BarcodeCache.shared.set("4901234567890", name: "牛乳", category: .dairy)
        BarcodeCache.shared.set("4901234567890", name: "低脂肪牛乳", category: .dairy)

        let result = BarcodeCache.shared.get("4901234567890")
        #expect(result?.name == "低脂肪牛乳")
    }

    @Test("複数のバーコードを保存できる")
    func multipleEntries() {
        resetCache()
        BarcodeCache.shared.set("1111111111111", name: "卵", category: .egg)
        BarcodeCache.shared.set("2222222222222", name: "醤油", category: .seasoning)
        BarcodeCache.shared.set("3333333333333", name: "鶏もも肉", category: .meat)

        #expect(BarcodeCache.shared.get("1111111111111")?.name == "卵")
        #expect(BarcodeCache.shared.get("2222222222222")?.name == "醤油")
        #expect(BarcodeCache.shared.get("3333333333333")?.name == "鶏もも肉")
    }

    @Test("reset でキャッシュが全てクリアされる")
    func resetClearsAll() {
        resetCache()
        BarcodeCache.shared.set("1111111111111", name: "卵", category: .egg)
        BarcodeCache.shared.set("2222222222222", name: "醤油", category: .seasoning)

        BarcodeCache.shared.reset()

        #expect(BarcodeCache.shared.get("1111111111111") == nil)
        #expect(BarcodeCache.shared.get("2222222222222") == nil)
    }

    @Test("BarcodeCacheEntry が Codable に準拠している")
    func entryCodable() throws {
        let entry = BarcodeCacheEntry(name: "テスト食材", category: .vegetables)
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(BarcodeCacheEntry.self, from: data)

        #expect(decoded.name == "テスト食材")
        #expect(decoded.category == .vegetables)
    }

    @Test("全カテゴリのエントリを保存・取得できる")
    func allCategories() {
        resetCache()
        for (index, category) in Category.allCases.enumerated() {
            let barcode = String(format: "%013d", index)
            BarcodeCache.shared.set(barcode, name: "テスト\(category.rawValue)", category: category)
        }

        for (index, category) in Category.allCases.enumerated() {
            let barcode = String(format: "%013d", index)
            let result = BarcodeCache.shared.get(barcode)
            #expect(result?.category == category)
        }

        resetCache()
    }
}
