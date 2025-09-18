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

    private var effectiveProjects: [Project] {
        projects ?? controller.projects
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
                    ForEach(effectiveProjects) { project in
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
                }
                .listStyle(.insetGrouped)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor").ignoresSafeArea())
    }
}

