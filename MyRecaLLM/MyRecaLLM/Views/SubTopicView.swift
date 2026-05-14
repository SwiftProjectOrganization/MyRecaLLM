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
    @State private var subTopicToUpdate: SubTopic?
    @State private var showingHelp = false
    @State private var navigateToExport = false
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
                        Text("Path")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
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
                        Text("SubTopics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .opacity(isOpacityEnabled ? 0.75 : 0.5)
#if os(iOS) || os(visionOS)
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
#endif
                .sheet(isPresented: $showingAddSubTopic) {
                    AddSubTopicView(topic: topic)
                }
                .sheet(item: $subTopicToUpdate) { subTopic in
                    SubTopicUpdateView(subTopic: subTopic)
                }
                .sheet(isPresented: $showingHelp) {
                    SubTopicHelpView()
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
                            ForEach(subTopics) { subTopic in
                                Button(subTopic.title?.isEmpty == false ? subTopic.title! : "Untitled") {
                                    subTopicToUpdate = subTopic
                                }
                            }
                        }
                        .buttonStyle(.glass)
                        .disabled(isEditing || subTopics.isEmpty)
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
                    Button("Export", systemImage: "square.and.arrow.up") {
                        navigateToExport = true
                    }
                    .padding(10)
                    .buttonStyle(.glass)
                    .tint(.blue)
                }
            }
            .tint(.red)
        }
        .opacity(1.0)
        .navigationDestination(isPresented: $navigateToExport) {
            ExportView(scope: .subTopics(parent: topic))
        }
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
