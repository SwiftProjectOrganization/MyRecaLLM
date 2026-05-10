//
//  AnswerProviders.swift
//  MyRecaLLM
//

import Foundation
import FoundationModels

enum AnswerProviderID: String, CaseIterable, Identifiable {
    case foundationModels
    case swama
    case ollama

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .foundationModels: "Apple Intelligence"
        case .swama: "Swama"
        case .ollama: "Ollama"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .foundationModels: ""
        case .swama: "http://127.0.0.1:28100"
        case .ollama: "http://127.0.0.1:11434"
        }
    }

    var defaultModel: String {
        switch self {
        case .foundationModels: ""
        case .swama, .ollama: "llama3.2"
        }
    }

    var isRemoteHTTP: Bool {
        switch self {
        case .swama, .ollama: true
        case .foundationModels: false
        }
    }

    static var available: [AnswerProviderID] {
        [.foundationModels, .swama, .ollama]
    }
}

protocol AnswerProvider: Sendable {
    func answer(prompt: String) async throws -> String
}

struct FoundationModelsProvider: AnswerProvider {
    func answer(prompt: String) async throws -> String {
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return response.content
    }
}

struct OpenAICompatibleProvider: AnswerProvider {
    let serviceName: String
    let baseURL: URL
    let model: String

    enum ProviderError: LocalizedError {
        case http(service: String, status: Int, body: String)
        case emptyResponse(service: String)

        var errorDescription: String? {
            switch self {
            case .http(let service, let status, let body):
                "\(service) returned HTTP \(status): \(body)"
            case .emptyResponse(let service):
                "\(service) returned an empty response."
            }
        }
    }

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [Message]
        let stream: Bool
        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    private struct ChatResponse: Decodable {
        let choices: [Choice]
        struct Choice: Decodable { let message: Message }
        struct Message: Decodable { let content: String }
    }

    private struct ModelsResponse: Decodable {
        let data: [Model]
        struct Model: Decodable { let id: String }
    }

    static func listModels(serviceName: String, baseURL: URL) async throws -> [String] {
        var request = URLRequest(url: baseURL.appending(path: "v1/models"))
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(status) else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            throw ProviderError.http(service: serviceName, status: status, body: snippet)
        }
        let decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
        return decoded.data.map(\.id).sorted()
    }

    func answer(prompt: String) async throws -> String {
        var request = URLRequest(url: baseURL.appending(path: "v1/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        let body = ChatRequest(
            model: model,
            messages: [.init(role: "user", content: prompt)],
            stream: false
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(status) else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            throw ProviderError.http(service: serviceName, status: status, body: snippet)
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw ProviderError.emptyResponse(service: serviceName)
        }
        return content
    }
}
