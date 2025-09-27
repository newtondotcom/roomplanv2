//
//  ProjectWindowView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//

import SwiftUI
import RoomPlan
import UniformTypeIdentifiers

struct ProjectWindowView: View {
    let project: Project

    @State private var showUSDZSheet = false
    @State private var usdzURL: URL?
    @State private var showFloorPlan = false
    @State private var capturedRoom: CapturedRoom?
    @State private var rooms: [ProjectRoom]
    @State private var roomToDelete: ProjectRoom?
    @State private var isShowingDeleteConfirmation = false
    @State private var isMerging = false
    @State private var mergeError: String?

    // For importing JSON(s)
    @State private var isImportingJSON = false

    // For renaming
    @State private var roomToRename: ProjectRoom?
    @State private var newRoomName: String = ""
    @State private var isShowingRenameAlert: Bool = false

    init(project: Project) {
        self.project = project
        self._rooms = State(initialValue: project.rooms)
    }

    // Computed property: count of unmerged rooms
    private var unmergedRoomsCount: Int {
        rooms.filter { !$0.merged }.count
    }

    // Computed property: true if exactly one merged room
    private var hasSingleMergedRoom: Bool {
        rooms.filter { $0.merged }.count == 1
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
                            Button {
                                if let usdz = room.fileURLUSDZ {
                                    usdzURL = usdz
                                    showUSDZSheet = true
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(room.name + (room.merged ? " (fusionnée)" : ""))
                                    if let json = room.fileURLJSON {
                                        Text(json.lastPathComponent).font(.caption).foregroundStyle(.secondary)
                                    }
                                    if let usdz = room.fileURLUSDZ {
                                        Text(usdz.lastPathComponent).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .if(project.isScannedByApp) { view in
                                view.swipeActions(edge: .trailing) {
                                    // Delete action
                                    Button(role: .destructive) {
                                        roomToDelete = room
                                        isShowingDeleteConfirmation = true
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                    // Rename action
                                    Button {
                                        roomToRename = room
                                        newRoomName = room.name
                                        isShowingRenameAlert = true
                                    } label: {
                                        Label("Renommer", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(project.name)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Merge button: only if scanned and more than one *unmerged* room
                    if project.isScannedByApp && unmergedRoomsCount > 1 {
                        Button {
                            Task { await mergeRooms() }
                        } label: {
                            Label("Fusionner les pièces", systemImage: "square.stack.3d.down.right")
                        }
                        .disabled(isMerging)
                    }
                    // Upload JSON Room(s)
                    if project.isScannedByApp {
                        Button {
                            isImportingJSON = true
                        } label: {
                            Label("Importer des pièces JSON", systemImage: "square.and.arrow.down")
                        }
                    }
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
            .fileImporter(
                isPresented: $isImportingJSON,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    importJSONRooms(from: urls)
                case .failure(let error):
                    mergeError = "Erreur d'import : \(error.localizedDescription)"
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
            .alert("Renommer la pièce", isPresented: $isShowingRenameAlert, actions: {
                TextField("Nom de la pièce", text: $newRoomName)
                Button("Enregistrer") {
                    if let toRename = roomToRename, let idx = rooms.firstIndex(of: toRename) {
                        rooms[idx].name = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
                        // Persist change
                        var updatedProject = project
                        updatedProject.rooms = rooms
                        ProjectController.shared.updateProject(updatedProject)
                    }
                    roomToRename = nil
                    newRoomName = ""
                }
                Button("Annuler", role: .cancel) {
                    roomToRename = nil
                    newRoomName = ""
                }
            }, message: {
                Text("Entrer un nouveau nom pour la pièce.")
            })
            .alert("Erreur", isPresented: .constant(mergeError != nil), actions: {
                Button("OK", role: .cancel) { mergeError = nil }
            }, message: {
                if let mergeError { Text(mergeError) }
            })
            .overlay {
                if isMerging {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Fusion des pièces…").padding().background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 16))
                    }
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

    // MARK: - Merge Logic

    private func mergeRooms() async {
        isMerging = true
        defer { isMerging = false }
        do {
            // Load CapturedRoom for all rooms with fileURLJSON
            let capturedRooms: [CapturedRoom] = try rooms.compactMap { room in
                guard let url = room.fileURLJSON else { return nil }
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(CapturedRoom.self, from: data)
            }
            guard capturedRooms.count > 1 else { mergeError = "Pas assez de pièces à fusionner."; return }
            // Merge using RoomPlan
            let merged = try await CapturedRoom.merged(from: capturedRooms)
            // Save merged room to a new file in the same directory as the first room
            guard let firstURL = rooms.first?.fileURLJSON else { mergeError = "Impossible de déterminer l'emplacement du fichier."; return }
            let dir = firstURL.deletingLastPathComponent()
            let mergedName = "Fusion-\(Date().ISO8601Format())"
            let mergedURL = dir.appendingPathComponent("\(mergedName).json")
            
            let mergedData = try JSONEncoder().encode(merged)
            try mergedData.write(to: mergedURL)
            // Add as a new ProjectRoom
            let mergedRoom = ProjectRoom(
                name: mergedName,
                fileURLJSON: mergedURL,
                fileURLUSDZ: nil,
                data: nil,
                merged: true
            )
            rooms.append(mergedRoom)
            // Persist update
            var updatedProject = project
            updatedProject.rooms = rooms
            ProjectController.shared.updateProject(updatedProject)
        } catch {
            mergeError = "Erreur lors de la fusion : \(error.localizedDescription)"
        }
    }

    // MARK: - Import multiple JSON rooms
    private func importJSONRooms(from urls: [URL]) {
        var newRooms: [ProjectRoom] = []
        let targetDir = rooms.first?.fileURLJSON?.deletingLastPathComponent()
        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                _ = try JSONDecoder().decode(CapturedRoom.self, from: data)
                let roomName = url.deletingPathExtension().lastPathComponent
                let destURL: URL
                if let dir = targetDir {
                    destURL = dir.appendingPathComponent(url.lastPathComponent)
                    if destURL != url {
                        try? FileManager.default.copyItem(at: url, to: destURL)
                    }
                } else {
                    destURL = url
                }
                let newRoom = ProjectRoom(
                    name: roomName,
                    fileURLJSON: destURL,
                    fileURLUSDZ: nil,
                    data: data
                )
                newRooms.append(newRoom)
            } catch {
                mergeError = "Un des fichiers n'a pas pu être importé : \(url.lastPathComponent) (\(error.localizedDescription))"
            }
        }
        if !newRooms.isEmpty {
            rooms.append(contentsOf: newRooms)
            var updatedProject = project
            updatedProject.rooms = rooms
            ProjectController.shared.updateProject(updatedProject)
        }
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
