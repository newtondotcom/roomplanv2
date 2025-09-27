//
//  ProjectWindowView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//

import SwiftUI
import RoomPlan

struct ProjectWindowView: View {
    let project: Project

    @State private var showUSDZSheet = false
    @State private var usdzURL: URL?
    @State private var showFloorPlan = false
    @State private var capturedRoom: CapturedRoom?
    @State private var rooms: [ProjectRoom]
    @State private var roomToDelete: ProjectRoom?
    @State private var isShowingDeleteConfirmation = false

    init(project: Project) {
        self.project = project
        self._rooms = State(initialValue: project.rooms)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Informations") {
                    Text(project.name)
                    Text(project.dateCreation, style: .date)
                    Text(project.isScannedByApp ? "Scanné par l'app" : "Non scanné par l'app")
                    Text("\(project.hashValue)")
                }
                Section("Pièces") {
                    if rooms.isEmpty {
                        Text("Aucune pièce")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(rooms) { room in
                            VStack(alignment: .leading) {
                                Text(room.name)
                                if let json = room.fileURLJSON {
                                    Text(json.lastPathComponent).font(.caption).foregroundStyle(.secondary)
                                }
                                if let usdz = room.fileURLUSDZ {
                                    Text(usdz.lastPathComponent).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            // Only allow deleting for project scanned by app
                            .if(project.isScannedByApp) { view in
                                view.swipeActions {
                                    Button(role: .destructive) {
                                        roomToDelete = room
                                        isShowingDeleteConfirmation = true
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(project.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let (room, jsonURL) = firstRoomWithJSON {
                            Button("Floor Plan") {
                                if let roomData = try? Data(contentsOf: jsonURL),
                                   let captured = try? JSONDecoder().decode(CapturedRoom.self, from: roomData) {
                                    capturedRoom = captured
                                    showFloorPlan = true
                                }
                            }
                        }
                        if let (_, usdzURL) = firstRoomWithUSDZ {
                            Button("3D Preview") {
                                self.usdzURL = usdzURL
                                showUSDZSheet = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showUSDZSheet) {
                if let url = usdzURL {
                    USDZQuickLookSheet(url: url)
                }
            }
            .sheet(isPresented: $showFloorPlan) {
                if let room = capturedRoom {
                    FloorPlanView(capturedRoom: room)
                }
            }
            .confirmationDialog("Supprimer la pièce ?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    if let toDelete = roomToDelete, let idx = rooms.firstIndex(of: toDelete) {
                        rooms.remove(at: idx)
                        // Update project in ProjectController
                        var updatedProject = project
                        updatedProject.rooms = rooms
                        ProjectController.shared.updateProject(updatedProject)
                    }
                    roomToDelete = nil
                }
                Button("Annuler", role: .cancel) {
                    roomToDelete = nil
                }
            } message: {
                if let room = roomToDelete {
                    Text("Êtes-vous sûr de vouloir supprimer la pièce « \(room.name) » ?")
                }
            }
        }
    }

    // MARK: - Helpers

    private var firstRoomWithJSON: (ProjectRoom, URL)? {
        for room in rooms {
            if let url = room.fileURLJSON { return (room, url) }
        }
        return nil
    }

    private var firstRoomWithUSDZ: (ProjectRoom, URL)? {
        for room in rooms {
            if let url = room.fileURLUSDZ { return (room, url) }
        }
        return nil
    }
}

// MARK: - Conditional View Modifier

private extension View {
    @ViewBuilder
    func `if`<V: View>(_ condition: Bool, transform: (Self) -> V) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
