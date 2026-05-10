//
//  CategoryHelpView.swift
//  MyRecaLLM
//

import SwiftUI

struct CategoryHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Categories") {
                    Text("A Category is the top of the hierarchy: Category → Topic → SubTopic → Question. Use categories to group related topics, e.g. \"Physics\", \"Languages\", \"Cooking\".")
                }
                Section("Add") {
                    Text("Tap **Add** to create a new category. The sheet asks for a Title and an optional Subtitle.")
                }
                Section("Update") {
                    Text("Tap **Update** to pick one category from the menu and edit all of its fields, including title, subtitle, and recall settings.")
                }
                Section("Edit & Delete") {
                    Text("Tap **Edit** to enter selection mode. Tap rows to select multiple categories, then tap **Delete** to remove them. Tap **Done** to leave selection mode.\n\nYou can also swipe a row to delete a single category. Deleting a category cascades to its topics, subtopics, and questions.")
                }
                Section("Recall fields") {
                    Text("Each category tracks recall metadata used for spaced-repetition flows:")
                    Text("• **Included in recall** — whether this category participates in recall cycles.")
                    Text("• **Cycles** — how many recall cycles have run on this category.")
                    Text("• **Last recall** — when it was last reviewed.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Category Help")
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
