//
//  TopicUpdateView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct TopicUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var topic: Topic

    private var titleBinding: Binding<String> {
        Binding(get: { topic.title ?? "" },
                set: { topic.title = $0 })
    }

    private var subTitleBinding: Binding<String> {
        Binding(get: { topic.subTitle ?? "" },
                set: { topic.subTitle = $0 })
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
                    Toggle("Included in recall", isOn: $topic.includedInRecall)
                    Stepper("Cycles: \(topic.noOfRecallCycles)",
                            value: $topic.noOfRecallCycles,
                            in: 0...10_000)
                    DatePicker("Last recall",
                               selection: $topic.lastRecallCycle,
                               displayedComponents: [.date, .hourAndMinute])
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Update Topic")
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
