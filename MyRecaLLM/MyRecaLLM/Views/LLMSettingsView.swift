//
//  LLMSettingsView.swift
//  MyRecaLLM
//

import SwiftUI

struct LLMSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("answerProvider") private var providerRaw = AnswerProviderID.foundationModels.rawValue
    @AppStorage("swama.baseURL") private var swamaBaseURL = AnswerProviderID.swama.defaultBaseURL
    @AppStorage("swama.model") private var swamaModel = AnswerProviderID.swama.defaultModel
    @AppStorage("ollama.baseURL") private var ollamaBaseURL = AnswerProviderID.ollama.defaultBaseURL
    @AppStorage("ollama.model") private var ollamaModel = AnswerProviderID.ollama.defaultModel
    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var modelsError: String?

    private var selectedProviderID: AnswerProviderID {
        AnswerProviderID(rawValue: providerRaw) ?? .foundationModels
    }

    private var remoteBaseURLBinding: Binding<String> {
        switch selectedProviderID {
        case .swama: $swamaBaseURL
        case .ollama: $ollamaBaseURL
        case .foundationModels: .constant("")
        }
    }

    private var remoteModelBinding: Binding<String> {
        switch selectedProviderID {
        case .swama: $swamaModel
        case .ollama: $ollamaModel
        case .foundationModels: .constant("")
        }
    }

    private var remoteBaseURL: String {
        switch selectedProviderID {
        case .swama: swamaBaseURL
        case .ollama: ollamaBaseURL
        case .foundationModels: ""
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Provider") {
                    Picker("Provider", selection: $providerRaw) {
                        ForEach(AnswerProviderID.available) { id in
                            Text(id.displayName).tag(id.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if selectedProviderID.isRemoteHTTP {
                    Section("Server") {
                        TextField("Server URL", text: remoteBaseURLBinding)
                            .textFieldStyle(.roundedBorder)
#if os(iOS)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
#endif
                    }
                    Section("Model") {
                        HStack {
                            Picker("Model", selection: remoteModelBinding) {
                                let current = remoteModelBinding.wrappedValue
                                if !current.isEmpty && !availableModels.contains(current) {
                                    Text(current).tag(current)
                                }
                                ForEach(availableModels, id: \.self) { name in
                                    Text(name).tag(name)
                                }
                            }
                            if isLoadingModels {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Button {
                                    Task { await loadRemoteModels() }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .buttonStyle(.borderless)
                                .help("Reload models from \(selectedProviderID.displayName)")
                            }
                        }
                        if let modelsError {
                            Text(modelsError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("LLM")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task(id: "\(providerRaw)|\(remoteBaseURL)") {
                if selectedProviderID.isRemoteHTTP {
                    await loadRemoteModels()
                }
            }
        }
    }

    private func loadRemoteModels() async {
        let provider = selectedProviderID
        guard provider.isRemoteHTTP else { return }
        guard let url = URL(string: remoteBaseURL) else {
            modelsError = "Invalid server URL"
            availableModels = []
            return
        }
        isLoadingModels = true
        modelsError = nil
        defer { isLoadingModels = false }
        do {
            let models = try await OpenAICompatibleProvider.listModels(
                serviceName: provider.displayName,
                baseURL: url
            )
            availableModels = models
            let modelBinding = remoteModelBinding
            if !models.isEmpty, !models.contains(modelBinding.wrappedValue) {
                modelBinding.wrappedValue = models.first ?? modelBinding.wrappedValue
            }
        } catch {
            modelsError = error.localizedDescription
            availableModels = []
        }
    }
}
