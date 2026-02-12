//
//  ScannedItemTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation
import Testing

@testable import SmartChef

// MARK: - ScannedItem Tests

struct ScannedItemTests {

    @Test("ScannedItem の初期化でデフォルト値が正しく設定される")
    func initWithDefaults() {
        let item = ScannedItem(name: "鶏もも肉")

        #expect(item.name == "鶏もも肉")
        #expect(item.category == .other)
        #expect(item.count == 1)
        #expect(item.deadline == nil)
        #expect(item.hasDeadline == false)
    }

    @Test("ScannedItem の初期化で全プロパティを指定できる")
    func initWithAllProperties() {
        let deadline = Date().addingTimeInterval(86400 * 3)
        let item = ScannedItem(
            name: "牛乳",
            category: .dairy,
            count: 2,
            deadline: deadline,
            hasDeadline: true
        )

        #expect(item.name == "牛乳")
        #expect(item.category == .dairy)
        #expect(item.count == 2)
        #expect(item.deadline == deadline)
        #expect(item.hasDeadline == true)
    }

    @Test("ScannedItem が一意の UUID を持つ")
    func uniqueIds() {
        let item1 = ScannedItem(name: "トマト")
        let item2 = ScannedItem(name: "トマト")
        #expect(item1.id != item2.id)
    }

    @Test("ScannedItem のプロパティを変更できる")
    func mutableProperties() {
        var item = ScannedItem(name: "にんじん")
        item.name = "大根"
        item.category = .vegetables
        item.count = 3
        item.hasDeadline = true
        item.deadline = Date()

        #expect(item.name == "大根")
        #expect(item.category == .vegetables)
        #expect(item.count == 3)
        #expect(item.hasDeadline == true)
        #expect(item.deadline != nil)
    }

    @Test("ScannedItem が Identifiable に準拠している")
    func identifiable() {
        let item = ScannedItem(name: "テスト")
        // Identifiable プロトコルの id プロパティにアクセスできることを確認
        let _: UUID = item.id
    }
}
