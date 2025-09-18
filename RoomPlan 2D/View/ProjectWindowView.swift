//
//  ProjectWindowView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//


//
//  ProjectWindowView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//


import SwiftUI

struct ProjectWindowView: View {
    let project: Project

    var body: some View {
        NavigationStack {
            List {
                Section("Informations") {
                    Text(project.name)
                    Text(project.dateCreation, style: .date)
                }
                Section("Pièces") {
                    if project.rooms.isEmpty {
                        Text("Aucune pièce")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(project.rooms) { room in
                            VStack(alignment: .leading) {
                                Text(room.name)
                                if let json = room.fileURLJSON { Text(json.lastPathComponent).font(.caption).foregroundStyle(.secondary) }
                                if let usdz = room.fileURLUSDZ { Text(usdz.lastPathComponent).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                }
            }
            .navigationTitle(project.name)
        }
    }
}


