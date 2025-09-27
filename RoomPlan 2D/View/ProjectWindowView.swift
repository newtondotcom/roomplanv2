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
                    if project.rooms.isEmpty {
                        Text("Aucune pièce")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(project.rooms) { room in
                            VStack(alignment: .leading) {
                                Text(room.name)
                                if let json = room.fileURLJSON {
                                    Text(json.lastPathComponent).font(.caption).foregroundStyle(.secondary)
                                }
                                if let usdz = room.fileURLUSDZ {
                                    Text(usdz.lastPathComponent).font(.caption).foregroundStyle(.secondary)
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
                        // Show Floor Plan if any room has a JSON and we can load it
                        if let (room, jsonURL) = firstRoomWithJSON {
                            Button("Floor Plan") {
                                if let roomData = try? Data(contentsOf: jsonURL),
                                   let captured = try? JSONDecoder().decode(CapturedRoom.self, from: roomData) {
                                    capturedRoom = captured
                                    showFloorPlan = true
                                }
                            }
                        }
                        // Show 3D Preview if any room has a USDZ file
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
        }
    }

    // MARK: - Helpers

    // Returns the first room and its JSON URL if available (or any if scannedByApp)
    private var firstRoomWithJSON: (ProjectRoom, URL)? {
        for room in project.rooms {
            if let url = room.fileURLJSON { return (room, url) }
        }
        return nil
    }

    // Returns the first room and its USDZ URL if available (or any if scannedByApp)
    private var firstRoomWithUSDZ: (ProjectRoom, URL)? {
        for room in project.rooms {
            if let url = room.fileURLUSDZ { return (room, url) }
        }
        return nil
    }
}

