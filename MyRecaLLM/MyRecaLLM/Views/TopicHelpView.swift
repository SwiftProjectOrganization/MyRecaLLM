//
//  TopicHelpView.swift
//  MyRecaLLM
//

import SwiftUI

struct TopicHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Topics") {
                    Text("A Topic lives inside a Category and groups related SubTopics. For example, the \"Physics\" category may contain topics like \"Relativity\", \"Mechanics\", or \"Thermodynamics\".")
                }
                Section("Add") {
                    Text("Tap **Add Topic** to create a new topic in the current category. The sheet asks for a Title and an optional Subtitle.")
                }
                Section("Update") {
                    Text("Tap **Update** to pick one topic from the menu and edit all of its fields, including title, subtitle, and recall settings.")
                }
                Section("Edit & Delete") {
                    Text("Tap **Edit** to enter selection mode. Tap rows to select multiple topics, then tap **Delete** to remove them. Tap **Done** to leave selection mode.\n\nYou can also swipe a row to delete a single topic. Deleting a topic cascades to its subtopics and questions.")
                }
                Section("Recall fields") {
                    Text("Each topic tracks recall metadata used for spaced-repetition flows:")
                    Text("• **Included in recall** — whether this topic participates in recall cycles.")
                    Text("• **Cycles** — how many recall cycles have run on this topic.")
                    Text("• **Last recall** — when it was last reviewed.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Topic Help")
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
