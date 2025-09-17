//
//  RootTabView.swift
//  RoomPlan 2D
//
//  Created by Assistant on 17/09/2025.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ExploreProjectsView()
                    .navigationTitle("Explorer les projets")
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }
            .tabItem {
                Label("Explorer", systemImage: "folder")
            }

            NavigationStack {
                WelcomeView()
                    .navigationTitle("Nouveau projet")
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }
            .tabItem {
                Label("Nouveau", systemImage: "plus.circle")
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}


