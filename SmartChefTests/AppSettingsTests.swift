//
//  AppSettingsTests.swift
//  SmartChefTests
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import Foundation
import Testing

@testable import SmartChef

// MARK: - AppSettings Tests

struct AppSettingsTests {

    @Test("AppSettings.shared がシングルトンインスタンスを返す")
    func sharedIsSingleton() {
        let a = AppSettings.shared
        let b = AppSettings.shared
        #expect(a === b)
    }

    @Test("servingsCount のデフォルト値が正しい")
    func defaultServingsCount() {
        let settings = AppSettings.shared
        #expect(settings.servingsCount >= 1)
        #expect(settings.servingsCount <= 8)
    }

    @Test("expiryWarningDays のデフォルト値が正の整数")
    func defaultExpiryWarningDays() {
        let settings = AppSettings.shared
        #expect(settings.expiryWarningDays > 0)
    }

    @Test("generationMode が有効な MealPlanGenerationMode である")
    func validGenerationMode() {
        let settings = AppSettings.shared
        #expect(MealPlanGenerationMode.allCases.contains(settings.generationMode))
    }
}

// MARK: - MealPlanGenerationMode Tests

struct MealPlanGenerationModeTests {

    @Test("MealPlanGenerationMode の全ケースが正しい rawValue を持つ")
    func rawValues() {
        #expect(MealPlanGenerationMode.morning.rawValue == "morning")
        #expect(MealPlanGenerationMode.evening.rawValue == "evening")
    }

    @Test("MealPlanGenerationMode.allCases が2つの要素を持つ")
    func allCases() {
        #expect(MealPlanGenerationMode.allCases.count == 2)
    }

    @Test("displayName が空でない")
    func displayName() {
        for mode in MealPlanGenerationMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
    }

    @Test("description が空でない")
    func descriptionNotEmpty() {
        for mode in MealPlanGenerationMode.allCases {
            #expect(!mode.description.isEmpty)
        }
    }

    @Test("scheduledHour が朝5時または夕方17時")
    func scheduledHour() {
        #expect(MealPlanGenerationMode.morning.scheduledHour == 5)
        #expect(MealPlanGenerationMode.evening.scheduledHour == 17)
    }
}
