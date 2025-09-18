//
//  ExploreProjectsView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 17/09/2025.
//

import SwiftUI
import Foundation

struct ExploreProjectsView: View {
    @StateObject private var controller = ProjectController.shared

    // Optional external data source to allow parent to inject filtered results
    var projects: [Project]?

    @State private var newProjectName = ""
    @Environment(\.openWindow) private var openWindow

    private enum SortOption: String, CaseIterable {
        case dateAsc
        case dateDesc
        case roomsAsc
        case roomsDesc
    }

    @State private var sortOption: SortOption = .dateDesc
    // search handled by SearchPresentationModifier in RootTabView

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
                List {
                    ForEach(sortedProjects) { project in
                        Button {
                            openWindow(value: project.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(project.name)
                                        .font(.headline)
                                    Text(project.dateCreation, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete(perform: controller.deleteProjects)
                }
                .listStyle(.insetGrouped)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor").ignoresSafeArea())
        .toolbar {
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
    }
}

