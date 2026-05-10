//
//  TopicView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct TopicView {
    @Environment(\.modelContext) private var modelContext
    @Bindable var category: Category
    @State var isOpacityEnabled: Bool = true
    @State private var showingAddTopic = false
    @State private var isEditing = false
    @State private var selection = Set<PersistentIdentifier>()
    @State private var topicToUpdate: Topic?
    @State private var showingHelp = false
}

extension TopicView: View {
    private var topics: [Topic] {
        category.topics ?? []
    }

    var body: some View {
        VStack {
            ZStack {
//                Image("question")
//                    .resizable()
//                    .ignoresSafeArea(.all)

                List(selection: $selection) {
                    Section {
                        LabeledContent("Category", value: category.title ?? "—")
                    } header: {
                        Text("Path")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
//                    Toggle("Increase opacity", isOn: $isOpacityEnabled)
                    Section {
                        ForEach(topics) { topic in
                            NavigationLink(destination: SubTopicView(topic: topic)) {
                                Text((topic.title?.isEmpty == false ? topic.title! : "Untitled"))
                                    .padding(10)
                                    .glassEffect(.clear.tint(.blue).interactive(), in: .buttonBorder)
                            }
                            .tag(topic.persistentModelID)
                        }
                        .onDelete(perform: deleteTopics)
                    } header: {
                        Text("Topics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
//                .opacity(isOpacityEnabled ? 0.75 : 0.5)
#if os(iOS) || os(visionOS)
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
#endif
                .sheet(isPresented: $showingAddTopic) {
                    AddTopicView(category: category)
                }
                .sheet(item: $topicToUpdate) { topic in
                    TopicUpdateView(topic: topic)
                }
                .sheet(isPresented: $showingHelp) {
                    TopicHelpView()
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button("Help", systemImage: "questionmark.circle") {
                            showingHelp = true
                        }
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation {
                                isEditing.toggle()
                                if !isEditing { selection.removeAll() }
                            }
                        }
                        Menu("Update") {
                            ForEach(topics) { topic in
                                Button(topic.title?.isEmpty == false ? topic.title! : "Untitled") {
                                    topicToUpdate = topic
                                }
                            }
                        }
                        .buttonStyle(.glass)
                        .disabled(isEditing || topics.isEmpty)
                        Button("Add Topic") { addTopic() }
                            .buttonStyle(.glass)
                            .disabled(isEditing)
                        if isEditing {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deleteSelected()
                            }
                            .disabled(selection.isEmpty)
                        }
                    }
                }
            }
            Spacer()
            GlassEffectContainer {
                HStack(spacing: 24) {
                    Button("Inherit") { }
                        .padding(10)
                        .buttonStyle(.glass)
                    Button("Download", systemImage: "square.and.arrow.down") { }
                        .padding(10)
                        .buttonStyle(.glass)
                        .tint(Color.green)
                    Button("Upload", systemImage: "square.and.arrow.up") { }
                        .padding(10)
                        .buttonStyle(.glass)
                        .tint(.blue)
                }
            }
            .tint(.red)
        }
        .opacity(1.0)
    }

    private func addTopic() {
        showingAddTopic = true
    }

    private func deleteTopics(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(topics[index])
            }
        }
    }

    private func deleteSelected() {
        withAnimation {
            for topic in topics where selection.contains(topic.persistentModelID) {
                modelContext.delete(topic)
            }
            selection.removeAll()
            isEditing = false
        }
    }
}
