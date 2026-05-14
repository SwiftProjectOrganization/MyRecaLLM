//
//  ExportImportSettingsView.swift
//  MyRecaLLM
//

import SwiftUI

struct ExportImportSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("exportImport.user") private var exportImportUser: String = "rob"
    @AppStorage("exportImport.serverURL") private var exportImportServerURL: String = "https://Rob-Travel-M5.local:8085"

    var body: some View {
        NavigationStack {
            Form {
                Section("User") {
                    TextField("User", text: $exportImportUser)
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                }
                Section("Server") {
                    TextField("Server URL", text: $exportImportServerURL)
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                }
                Section("Notes") {
                    Text("These values are stored now and will be used by the upload/download flow in a future phase. No network calls are made yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Export / Import")
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
