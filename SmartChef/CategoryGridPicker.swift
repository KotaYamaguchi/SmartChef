//
//  CategoryGridPicker.swift
//  SmartChef
//
//  Created by Kota Yamaguchi on 2026/02/12.
//

import SwiftUI

struct CategoryGridPicker: View {
    @Binding var selection: FoodCategory

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(FoodCategory.allCases, id: \.self) { category in
                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        selection = category
                    }
                } label: {
                    VStack(spacing: 8) {
                        // アイコン部分
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(selection == category ? 0.2 : 0.08))
                                .frame(width: 50, height: 50)

                            if let iconName = category.iconName {
                                Image(iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            } else {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(category.color)
                            }
                        }

                        Text(category.rawValue)
                            .font(
                                .system(size: 13, weight: selection == category ? .bold : .medium)
                            )
                            .foregroundStyle(selection == category ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selection == category ? Color.primary.opacity(0.05) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selection == category ? category.color.opacity(0.5) : Color.clear,
                                lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    @State var category: FoodCategory = .vegetables
    return CategoryGridPicker(selection: $category)
        .padding()
}
