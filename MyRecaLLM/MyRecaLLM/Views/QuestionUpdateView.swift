//
//  QuestionUpdateView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct QuestionUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: Item

    private var questionBinding: Binding<String> {
        Binding(get: { item.question ?? "" },
                set: { item.question = $0 })
    }

    private var userAnswerBinding: Binding<String> {
        Binding(get: { item.userAnswer ?? "" },
                set: { item.userAnswer = $0 })
    }

    private var generatedAnswerBinding: Binding<String> {
        Binding(get: { item.generatedAnswer ?? "" },
                set: { item.generatedAnswer = $0 })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("Question", text: questionBinding, axis: .vertical)
                        .lineLimit(3...)
                }
                Section("User Answer") {
                    TextField("Your answer", text: userAnswerBinding, axis: .vertical)
                        .lineLimit(3...)
                }
                Section("Generated Answer") {
                    TextField("Generated answer", text: generatedAnswerBinding, axis: .vertical)
                        .lineLimit(3...)
                }
                Section("Created") {
                    DatePicker("Timestamp",
                               selection: $item.timestamp,
                               displayedComponents: [.date, .hourAndMinute])
                }
                Section("Recall") {
                    Toggle("Included in recall", isOn: $item.includedInRecall)
                    Stepper("Cycles: \(item.noOfRecallCycles)",
                            value: $item.noOfRecallCycles,
                            in: 0...10_000)
                    DatePicker("Last recall",
                               selection: $item.lastRecallCycle,
                               displayedComponents: [.date, .hourAndMinute])
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Update Question")
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
