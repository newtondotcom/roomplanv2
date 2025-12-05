//
//  NewProjectView.swift
//  RoomPlan 2D
//
//  Created by Dennis van Oosten on 24/02/2023.
//

import SwiftUI

struct NewProjectView: View {
    @ObservedObject private var projectController = ProjectController.shared

    @State private var showingNamingSheet = true
    @State private var newProjectName = ""
    @State private var createdProject: Project? = nil

    @Binding var newlyCreatedProjectId: UUID?

    init(newlyCreatedProjectId: Binding<UUID?>) {
        self._newlyCreatedProjectId = newlyCreatedProjectId
    }

    var body: some View {
        ZStack {
            if let project = createdProject {
                ProjectWindowView(project: project)
            } else {
                VStack {
                    Image(systemName: "house")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                        .padding(.bottom, 8)
                    Text("RoomPlan 2D")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    Text("Créez un projet pour commencer.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingNamingSheet, onDismiss: {
            if createdProject == nil {
                // Optionally pop/dismiss view here if part of navigation stack
            }
        }) {
            ProjectNamingView { name in
                projectController.addProject(name: name)
                if let project = projectController.projects.last {
                    createdProject = project
                    newlyCreatedProjectId = project.id // <-- Ici, stockage de l'id
                }
                showingNamingSheet = false
            }
        }
    }
}

struct NewProjectView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewProjectView(newlyCreatedProjectId: .constant(nil))
        }
    }
}
