//
//  PlanSpace_2DApp.swift
//  PlanSpace
//
//  Created by Dennis van Oosten on 24/02/2023.
//

import SwiftUI

@main
struct PlanSpace_2DApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        // Window for individual project
        WindowGroup("Project", for: UUID.self) { $projectId in
            if let id = projectId, let project = ProjectController.shared.project(withId: id) {
                ProjectWindowView(project: project)
            } else {
                Text("Projet introuvable")
            }
        }
    }
}
