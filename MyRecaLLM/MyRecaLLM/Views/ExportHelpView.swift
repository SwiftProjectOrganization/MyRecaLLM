//
//  ExportHelpView.swift
//  MyRecaLLM
//

import SwiftUI

struct ExportHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Export") {
                    Text("Export saves one or more Categories, Topics, or SubTopics to JSON files in ~/Documents/MyRecaLLM/. Each selected row becomes its own file — selecting three categories writes three independent files.")
                }
                Section("Scope") {
                    Text("The scope of an Export view is set by where you opened it from:")
                    Text("• From the Categories list: export Categories (each with all its Topics, SubTopics, and Questions).")
                    Text("• From the Topics list: export Topics inside the current Category.")
                    Text("• From the SubTopics list: export SubTopics inside the current Topic.")
                }
                Section("Selecting") {
                    Text("Tap **Edit** to enter selection mode, tap rows to pick them, then tap **Export Selected**. The view reports how many files were written and where.")
                }
                Section("File format") {
                    Text("Each file is a JSON envelope:")
                    Text("• **version** — schema version (currently 1).")
                    Text("• **exportedAt** — ISO-8601 timestamp.")
                    Text("• **kind** — `category`, `topic`, or `subTopic`.")
                    Text("• **item** — the full subtree, including generated answers.")
                }
                Section("Filename") {
                    Text("Files are named like `MyRecaLLM-category-Swift-2026-05-14.json`. If the same name already exists, ` (2)`, ` (3)`, … is appended.")
                }
                Section("Not in this phase") {
                    Text("Uploading these files to a server is a future phase. The User and Server settings (gear icon) are stored now so they're ready when the upload flow ships.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Export Help")
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
