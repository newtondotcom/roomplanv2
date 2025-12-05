//
//  ExploreProjectsView.swift
//  PlanSpace
//
//  Created by Robin Augereau on 17/09/2025.
//

import SwiftUI
import Foundation

struct ExploreProjectsView: View {
    @ObservedObject private var controller = ProjectController.shared

    var projects: [Project]? = nil
    @Binding var newlyCreatedProjectId: UUID?

    @State private var sortOption: SortOption = .dateDesc
    @State private var selection: UUID? = nil // Pour NavigationLink
    @State private var showSettings = false
    @State private var showNewProjectSheet = false

    private enum SortOption: String, CaseIterable {
        case dateAsc
        case dateDesc
        case roomsAsc
        case roomsDesc
    }

    private var effectiveProjects: [Project] {
        projects ?? controller.projects
    }

    private var filteredProjects: [Project] { effectiveProjects }

    private var sortedProjects: [Project] {
        switch sortOption {
        case .dateAsc:
            return filteredProjects.sorted { $0.dateCreation < $1.dateCreation }
        case .dateDesc:
            return filteredProjects.sorted { $0.dateCreation > $1.dateCreation }
        case .roomsAsc:
            return filteredProjects.sorted { $0.rooms.count < $1.rooms.count }
        case .roomsDesc:
            return filteredProjects.sorted { $0.rooms.count > $1.rooms.count }
        }
    }

    var body: some View {
        Group {
            if effectiveProjects.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.grid.2x2")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Aucun projet pour le moment")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else {
                List(selection: $selection) {
                    ForEach(sortedProjects) { project in
                        NavigationLink(
                            destination:
                                ProjectWindowView(project: project)
                                    .onAppear {
                                        newlyCreatedProjectId = nil
                                    },
                            tag: project.id,
                            selection: $selection
                        ) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(project.name)
                                        .font(.headline)
                                    Text(project.dateCreation, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        // Swipe actions removed here. No .onDelete or .swipeActions.
                    }
                }
                .listStyle(.insetGrouped)
                .onAppear {
                    if let id = newlyCreatedProjectId {
                        // Reset selection first to avoid keeping the old project selected
                        selection = nil
                        // Delay needed to allow NavigationLink to close before reopening
                        DispatchQueue.main.async {
                            selection = id
                        }
                        // newlyCreatedProjectId will be reset in the detail view onAppear
                    }
                }
                .onChange(of: newlyCreatedProjectId) { newValue in
                    if let id = newValue {
                        // Reset selection first to avoid keeping the old project selected
                        selection = nil
                        // Delay needed to allow NavigationLink to close before reopening
                        DispatchQueue.main.async {
                            selection = id
                        }
                        // newlyCreatedProjectId will be reset in the detail view onAppear
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor").ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewProjectSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        sortOption = .dateAsc
                    } label: {
                        Label("Date ↑", systemImage: "calendar")
                    }
                    Button {
                        sortOption = .dateDesc
                    } label: {
                        Label("Date ↓", systemImage: "calendar")
                    }
                    Divider()
                    Button {
                        sortOption = .roomsAsc
                    } label: {
                        Label("Pièces ↑", systemImage: "square.grid.2x2")
                    }
                    Button {
                        sortOption = .roomsDesc
                    } label: {
                        Label("Pièces ↓", systemImage: "square.grid.2x2")
                    }
                } label: {
                    Label("Filtrer", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showNewProjectSheet) {
            ProjectNamingView { name in
                controller.addProject(name: name)
                if let project = controller.projects.last {
                    newlyCreatedProjectId = project.id
                }
                showNewProjectSheet = false
            }
        }
        .refreshable {
            ProjectController.shared.reload()
        }
    }
}

