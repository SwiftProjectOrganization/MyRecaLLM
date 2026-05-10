//
//  SubTopicUpdateView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct SubTopicUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var subTopic: SubTopic

    private var titleBinding: Binding<String> {
        Binding(get: { subTopic.title ?? "" },
                set: { subTopic.title = $0 })
    }

    private var subTitleBinding: Binding<String> {
        Binding(get: { subTopic.subTitle ?? "" },
                set: { subTopic.subTitle = $0 })
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
                    Toggle("Included in recall", isOn: $subTopic.includedInRecall)
                    Stepper("Cycles: \(subTopic.noOfRecallCycles)",
                            value: $subTopic.noOfRecallCycles,
                            in: 0...10_000)
                    DatePicker("Last recall",
                               selection: $subTopic.lastRecallCycle,
                               displayedComponents: [.date, .hourAndMinute])
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Update SubTopic")
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
