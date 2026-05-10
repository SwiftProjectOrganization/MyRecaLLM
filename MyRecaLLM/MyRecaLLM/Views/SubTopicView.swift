//
//  SubTopicView.swift
//  MyRecaLLM
//

import SwiftUI
import SwiftData

struct SubTopicView {
    @Environment(\.modelContext) private var modelContext
    @Bindable var topic: Topic
    @State var isOpacityEnabled: Bool = true
    @State private var showingAddSubTopic = false
    @State private var isEditing = false
    @State private var selection = Set<PersistentIdentifier>()
}

extension SubTopicView: View {
    private var subTopics: [SubTopic] {
        topic.subTopics ?? []
    }

    var body: some View {
        VStack {
            ZStack {
//                Image("question")
//                    .resizable()
//                    .ignoresSafeArea(.all)

                List(selection: $selection) {
                    Section {
                        LabeledContent("Category", value: topic.category?.title ?? "—")
                        LabeledContent("Topic", value: topic.title ?? "—")
                    } header: {
                        Text("Path").font(.headline)
                    }
//                    Toggle("Increase opacity", isOn: $isOpacityEnabled)
                    Section {
                        ForEach(subTopics) { subTopic in
                            NavigationLink(destination: QuestionListView(subTopic: subTopic)) {
                                Text((subTopic.title?.isEmpty == false ? subTopic.title! : "Untitled"))
                                    .padding(10)
                                    .glassEffect(.clear.tint(.blue).interactive(), in: .buttonBorder)
                            }
                            .tag(subTopic.persistentModelID)
                        }
                        .onDelete(perform: deleteSubTopics)
                    } header: {
                        Text("SubTopics").font(.headline)
                    }
                }
                .opacity(isOpacityEnabled ? 0.75 : 0.5)
#if os(iOS) || os(visionOS)
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
#endif
                .sheet(isPresented: $showingAddSubTopic) {
                    AddSubTopicView(topic: topic)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation {
                                isEditing.toggle()
                                if !isEditing { selection.removeAll() }
                            }
                        }
                        Button("Add SubTopic") { addSubTopic() }
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
                    Button("TBD", systemImage: "square.and.arrow.up.fill") { }
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

    private func addSubTopic() {
        showingAddSubTopic = true
    }

    private func deleteSubTopics(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(subTopics[index])
            }
        }
    }

    private func deleteSelected() {
        withAnimation {
            for subTopic in subTopics where selection.contains(subTopic.persistentModelID) {
                modelContext.delete(subTopic)
            }
            selection.removeAll()
            isEditing = false
        }
    }
}
