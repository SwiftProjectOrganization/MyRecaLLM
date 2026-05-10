//
//  AddCategoryView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var subTitle: String = ""

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $title)
                }
                Section("Subtitle") {
                    TextField("Subtitle", text: $subTitle)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Category")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedTitle.isEmpty)
                }
            }
        }
    }

    private func save() {
        let category = Category()
        category.title = trimmedTitle
        let trimmedSubtitle = subTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        category.subTitle = trimmedSubtitle.isEmpty ? nil : trimmedSubtitle
        modelContext.insert(category)
        dismiss()
    }
}

#Preview {
    AddCategoryView()
        .modelContainer(for: [Category.self, Topic.self, SubTopic.self, Item.self], inMemory: true)
}
