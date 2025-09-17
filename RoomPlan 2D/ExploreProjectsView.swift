//
//  ExploreProjectsView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 17/09/2025.
//

import SwiftUI

struct ExploreProjectsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Aucun projet pour le moment")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor").ignoresSafeArea())
    }
}


