//
//  MyRecaLLMApp.swift
//  MyRecaLLM
//
//  Created by Robert Goedman on 5/4/26.
//

import SwiftUI
import SwiftData

@main
struct MyRecaLLMApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
          Category.self, Topic.self, SubTopic.self, Item.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            CategoryView()
        }
        .modelContainer(sharedModelContainer)
    }
}
