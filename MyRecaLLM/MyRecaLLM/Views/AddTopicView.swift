//
//  AddTopicView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct AddTopicView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let category: Category
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
            .navigationTitle("New Topic")
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
        let topic = Topic()
        topic.title = trimmedTitle
        let trimmedSubtitle = subTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        topic.subTitle = trimmedSubtitle.isEmpty ? nil : trimmedSubtitle
        topic.category = category
        modelContext.insert(topic)
        dismiss()
    }
}
