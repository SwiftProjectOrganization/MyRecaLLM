//
//  SubTopicHelpView.swift
//  MyRecaLLM
//

import SwiftUI

struct SubTopicHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("SubTopics") {
                    Text("A SubTopic lives inside a Topic and groups related Questions. For example, under the \"Relativity\" topic you might have subtopics like \"Special Relativity\" and \"General Relativity\".")
                }
                Section("Add") {
                    Text("Tap **Add SubTopic** to create a new subtopic in the current topic. The sheet asks for a Title and an optional Subtitle.")
                }
                Section("Update") {
                    Text("Tap **Update** to pick one subtopic from the menu and edit all of its fields, including title, subtitle, and recall settings.")
                }
                Section("Edit & Delete") {
                    Text("Tap **Edit** to enter selection mode. Tap rows to select multiple subtopics, then tap **Delete** to remove them. Tap **Done** to leave selection mode.\n\nYou can also swipe a row to delete a single subtopic. Deleting a subtopic cascades to its questions.")
                }
                Section("Recall fields") {
                    Text("Each subtopic tracks recall metadata used for spaced-repetition flows:")
                    Text("• **Included in recall** — whether this subtopic participates in recall cycles.")
                    Text("• **Cycles** — how many recall cycles have run on this subtopic.")
                    Text("• **Last recall** — when it was last reviewed.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("SubTopic Help")
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
