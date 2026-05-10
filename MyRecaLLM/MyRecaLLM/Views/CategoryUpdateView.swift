//
//  CategoryUpdateView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct CategoryUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var category: Category

    private var titleBinding: Binding<String> {
        Binding(get: { category.title ?? "" },
                set: { category.title = $0 })
    }

    private var subTitleBinding: Binding<String> {
        Binding(get: { category.subTitle ?? "" },
                set: { category.subTitle = $0 })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: titleBinding)
                }
                Section("Subtitle") {
                    TextField("Subtitle", text: subTitleBinding)
                }
                Section("Recall") {
                    Toggle("Included in recall", isOn: $category.includedInRecall)
                    Stepper("Cycles: \(category.noOfRecallCycles)",
                            value: $category.noOfRecallCycles,
                            in: 0...10_000)
                    DatePicker("Last recall",
                               selection: $category.lastRecallCycle,
                               displayedComponents: [.date, .hourAndMinute])
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Update Category")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
