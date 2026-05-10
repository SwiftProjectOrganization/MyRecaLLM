//
//  QuestionHelpView.swift
//  MyRecaLLM
//

import SwiftUI

struct QuestionHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Questions") {
                    Text("A Question is the leaf of the hierarchy: Category → Topic → SubTopic → Question. Each question has an associated generated answer (from the LLM) and an optional user answer.")
                }
                Section("Add") {
                    Text("Tap **Add Question** to create a new question in the current subtopic. The sheet asks for the question text.")
                }
                Section("Update") {
                    Text("Tap **Update** to pick one question from the menu and edit all of its fields: question text, your answer, the generated answer, timestamps, and recall settings.\n\nFor LLM-driven answer generation, tap a row to open the question detail view and use the **Answer** button.")
                }
                Section("Edit & Delete") {
                    Text("Tap **Edit** to enter selection mode. Tap rows to select multiple questions, then tap **Delete** to remove them. Tap **Done** to leave selection mode.\n\nYou can also swipe a row to delete a single question.")
                }
                Section("Recall fields") {
                    Text("Each question tracks recall metadata used for spaced-repetition flows:")
                    Text("• **Included in recall** — whether this question participates in recall cycles.")
                    Text("• **Cycles** — how many recall cycles have run on this question.")
                    Text("• **Last recall** — when it was last reviewed.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Question Help")
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
