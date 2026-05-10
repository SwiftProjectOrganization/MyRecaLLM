//
//  ItemDetailView.swift
//  MyRecaLLM
//

import SwiftUI

struct ItemDetailView: View {
    @Bindable var item: Item
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingLLMSettings = false
    @AppStorage("answerProvider") private var providerRaw = AnswerProviderID.foundationModels.rawValue
    @AppStorage("swama.baseURL") private var swamaBaseURL = AnswerProviderID.swama.defaultBaseURL
    @AppStorage("swama.model") private var swamaModel = AnswerProviderID.swama.defaultModel
    @AppStorage("ollama.baseURL") private var ollamaBaseURL = AnswerProviderID.ollama.defaultBaseURL
    @AppStorage("ollama.model") private var ollamaModel = AnswerProviderID.ollama.defaultModel

    private var questionBinding: Binding<String> {
        Binding(
            get: { item.question ?? "" },
            set: { item.question = $0 }
        )
    }

    private var trimmedQuestion: String {
        (item.question ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedProviderID: AnswerProviderID {
        AnswerProviderID(rawValue: providerRaw) ?? .foundationModels
    }

    private var selectedModelName: String? {
        switch selectedProviderID {
        case .foundationModels: nil
        case .swama: swamaModel.isEmpty ? AnswerProviderID.swama.defaultModel : swamaModel
        case .ollama: ollamaModel.isEmpty ? AnswerProviderID.ollama.defaultModel : ollamaModel
        }
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Category", value: item.subTopic?.topic?.category?.title ?? "—")
                LabeledContent("Topic", value: item.subTopic?.topic?.title ?? "—")
                LabeledContent("SubTopic", value: item.subTopic?.title ?? "—")
            } header: {
                Text("Path").font(.headline)
            }
            Section("Created") {
                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
            }
            Section("LLM") {
                LabeledContent("Provider", value: selectedProviderID.displayName)
                if let selectedModelName {
                    LabeledContent("Model", value: selectedModelName)
                }
            }
            Section("Question") {
                TextField("Enter a question", text: questionBinding, axis: .vertical)
                    .lineLimit(3...)
            }
            Section("Generated Answer") {
                Text(item.generatedAnswer ?? "")
                    .foregroundStyle((item.generatedAnswer ?? "").isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
            }
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingLLMSettings) {
            LLMSettingsView()
        }
        .safeAreaInset(edge: .bottom) {
            GlassEffectContainer(spacing: 20) {
                HStack(spacing: 12) {
                    Button {
                        Task { await generateAnswer() }
                    } label: {
                        HStack(spacing: 8) {
                            if isGenerating {
                                ProgressView()
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isGenerating ? "Generating…" : "Answer")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(isGenerating || trimmedQuestion.isEmpty)

                    Button {
                        showingLLMSettings = true
                    } label: {
                        Text("LLM")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
    }

    private func makeProvider() -> any AnswerProvider {
        switch selectedProviderID {
        case .foundationModels:
            return FoundationModelsProvider()
        case .swama:
            let url = URL(string: swamaBaseURL) ?? URL(string: AnswerProviderID.swama.defaultBaseURL)!
            let model = swamaModel.isEmpty ? AnswerProviderID.swama.defaultModel : swamaModel
            return OpenAICompatibleProvider(serviceName: AnswerProviderID.swama.displayName, baseURL: url, model: model)
        case .ollama:
            let url = URL(string: ollamaBaseURL) ?? URL(string: AnswerProviderID.ollama.defaultBaseURL)!
            let model = ollamaModel.isEmpty ? AnswerProviderID.ollama.defaultModel : ollamaModel
            return OpenAICompatibleProvider(serviceName: AnswerProviderID.ollama.displayName, baseURL: url, model: model)
        }
    }

    private func generateAnswer() async {
        let prompt = trimmedQuestion
        guard !prompt.isEmpty else { return }
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        do {
            let provider = makeProvider()
            item.generatedAnswer = try await provider.answer(prompt: prompt)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
