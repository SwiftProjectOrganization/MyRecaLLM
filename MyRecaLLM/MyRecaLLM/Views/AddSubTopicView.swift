//
//  AddSubTopicView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct AddSubTopicView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let topic: Topic
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
            .navigationTitle("New SubTopic")
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
        let subTopic = SubTopic()
        subTopic.title = trimmedTitle
        let trimmedSubtitle = subTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        subTopic.subTitle = trimmedSubtitle.isEmpty ? nil : trimmedSubtitle
        subTopic.topic = topic
        modelContext.insert(subTopic)
        dismiss()
    }
}
