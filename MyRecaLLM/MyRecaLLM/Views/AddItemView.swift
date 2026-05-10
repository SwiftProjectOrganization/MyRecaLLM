//
//  AddItemView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let subTopic: SubTopic
    @State private var question: String = ""

    private var trimmedQuestion: String {
        question.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("Enter a question", text: $question, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Question")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedQuestion.isEmpty)
                }
            }
        }
    }

    private func save() {
        let item = Item()
        item.question = trimmedQuestion
        item.subTopic = subTopic
        modelContext.insert(item)
        dismiss()
    }
}
