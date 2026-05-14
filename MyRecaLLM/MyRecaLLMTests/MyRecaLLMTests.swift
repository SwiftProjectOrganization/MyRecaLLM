//
//  MyRecaLLMTests.swift
//  MyRecaLLMTests
//
//  Created by Robert Goedman on 5/4/26.
//

import Testing
import Foundation
import SwiftData
@testable import MyRecaLLM

@MainActor
struct MyRecaLLMTests {

    @Test func categoryEnvelopeRoundTrip() async throws {
        let container = try ModelContainer(
            for: Category.self, Topic.self, SubTopic.self, Item.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let category = Category("Swift", "Language fundamentals")
        context.insert(category)

        for topicIndex in 0..<2 {
            let topic = Topic("Topic \(topicIndex)", "Topic subtitle \(topicIndex)")
            topic.category = category
            context.insert(topic)
            for subIndex in 0..<2 {
                let subTopic = SubTopic("Sub \(topicIndex)-\(subIndex)", "Sub subtitle")
                subTopic.topic = topic
                context.insert(subTopic)
                for itemIndex in 0..<3 {
                    let item = Item()
                    item.question = "Q \(topicIndex)-\(subIndex)-\(itemIndex)"
                    item.generatedAnswer = "A \(topicIndex)-\(subIndex)-\(itemIndex)"
                    item.subTopic = subTopic
                    context.insert(item)
                }
            }
        }

        let data = try ExportService.encode(category: category)

        let decoder = ExportService.makeDecoder()
        let envelope = try decoder.decode(RecallExportEnvelope<MyRecaLLM.Category>.self, from: data)

        #expect(envelope.version == 1)
        #expect(envelope.kind == .category)
        #expect(envelope.item.title == "Swift")

        let decodedTopics = envelope.item.topics ?? []
        #expect(decodedTopics.count == 2)

        for topic in decodedTopics {
            let subs = topic.subTopics ?? []
            #expect(subs.count == 2)
            for sub in subs {
                #expect((sub.questions ?? []).count == 3)
            }
        }

        let allQuestions = decodedTopics
            .flatMap { $0.subTopics ?? [] }
            .flatMap { $0.questions ?? [] }
        #expect(allQuestions.contains { $0.generatedAnswer == "A 0-0-0" })
    }

    @Test func topicEnvelopeRoundTrip() async throws {
        let container = try ModelContainer(
            for: Category.self, Topic.self, SubTopic.self, Item.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let topic = Topic("Concurrency", "Async / actors")
        context.insert(topic)
        let subTopic = SubTopic("Actors", "")
        subTopic.topic = topic
        context.insert(subTopic)
        let item = Item()
        item.question = "What is an actor?"
        item.generatedAnswer = "An actor is …"
        item.subTopic = subTopic
        context.insert(item)

        let data = try ExportService.encode(topic: topic)
        let envelope = try ExportService.makeDecoder().decode(RecallExportEnvelope<Topic>.self, from: data)

        #expect(envelope.kind == .topic)
        #expect(envelope.item.title == "Concurrency")
        #expect((envelope.item.subTopics ?? []).count == 1)
        #expect((envelope.item.subTopics?.first?.questions ?? []).first?.generatedAnswer == "An actor is …")
    }

    @Test func subTopicEnvelopeRoundTrip() async throws {
        let container = try ModelContainer(
            for: Category.self, Topic.self, SubTopic.self, Item.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let subTopic = SubTopic("Actors", "")
        context.insert(subTopic)
        let item = Item()
        item.question = "What is an actor?"
        item.subTopic = subTopic
        context.insert(item)

        let data = try ExportService.encode(subTopic: subTopic)
        let envelope = try ExportService.makeDecoder().decode(RecallExportEnvelope<SubTopic>.self, from: data)

        #expect(envelope.kind == .subTopic)
        #expect(envelope.item.title == "Actors")
        #expect((envelope.item.questions ?? []).count == 1)
    }

    @Test func dateRoundTripIsISO8601() async throws {
        let known = ISO8601DateFormatter().date(from: "2026-04-15T12:00:00Z")!
        let category = Category("Dates", "")
        category.lastRecallCycle = known
        category.recallTimeStamps = [known]

        let data = try ExportService.encode(category: category)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        #expect(jsonString.contains("2026-04-15T12:00:00Z"))

        let envelope = try ExportService.makeDecoder().decode(RecallExportEnvelope<MyRecaLLM.Category>.self, from: data)
        #expect(envelope.item.lastRecallCycle == known)
    }

    @Test func defaultFilenameSlugifies() {
        let name = ExportService.defaultFilename(kind: .category, title: "Swift 6.1 / Concurrency!")
        #expect(name.hasPrefix("MyRecaLLM-category-Swift-6-1-Concurrency-"))
        #expect(name.hasSuffix(".json"))
    }
}
