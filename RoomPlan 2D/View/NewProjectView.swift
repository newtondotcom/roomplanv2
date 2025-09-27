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

    var body: some View {
        ZStack {
            if let project = createdProject {
                ProjectWindowView(project: project)
            } else {
                // Show a placeholder or branding while waiting for project naming
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
            // If the sheet is dismissed without a name, navigate back
            if createdProject == nil {
                // Optionally pop/dismiss view here if part of navigation stack
            }
        }) {
            ProjectNamingView { name in
                // Create and select the new project
                projectController.addProject(name: name)
                if let project = projectController.projects.last {
                    createdProject = project
                }
                showingNamingSheet = false
            }
        }
    }
}

struct NewProjectView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewProjectView()
        }
    }
}
