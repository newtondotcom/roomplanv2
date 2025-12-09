//
//  ProjectWindowView.swift
//  PlanSpace
//
//  Created by Robin Augereau on 18/09/2025.
//

import SwiftUI
import RoomPlan
import UniformTypeIdentifiers

struct ProjectWindowView: View {
    @ObservedObject private var controller = ProjectController.shared
    let project: Project

    @State private var showUSDZSheet = false
    @State private var usdzURL: URL?
    @State private var showFloorPlan = false
    @State private var capturedRoom: CapturedRoom?
    @State private var rooms: [ProjectRoom]
    @State private var isShowingMultiRoomScanView = false
    @State private var roomToDelete: ProjectRoom?
    @State private var isShowingDeleteConfirmation = false
    @State private var isMerging = false
    @State private var mergeError: String?

    // For importing JSON(s)
    @State private var isImportingJSON = false

    // For renaming rooms
    @State private var roomToRename: ProjectRoom?
    @State private var newRoomName: String = ""
    @State private var isShowingRenameAlert: Bool = false

    // For renaming/deleting project
    @State private var isShowingProjectRenameAlert: Bool = false
    @State private var isShowingProjectDeleteConfirmation: Bool = false
    @State private var newProjectNameForAlert: String = ""

    // For navigation after project deletion
    @Environment(\.dismiss) private var dismiss

    init(project: Project) {
        self.project = project
        self._rooms = State(initialValue: project.rooms)
    }

    // Computed property: count of unmerged rooms
    private var unmergedRoomsCount: Int {
        rooms.filter { !$0.merged }.count
    }
    
    // Computed property: count of unmerged rooms with JSON files
    private var unmergedRoomsWithJSONCount: Int {
        rooms.filter { !$0.merged && $0.fileURLJSON != nil }.count
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
            .onChange(of: controller.projects.first(where: { $0.id == project.id })) { updatedProject in
                if let updated = updatedProject {
                    rooms = updated.rooms
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Scan new room button
                    if project.isScannedByApp {
                        Button {
                            isShowingMultiRoomScanView = true
                        } label: {
                            Label("Scanner plusieurs pièces", systemImage: "camera.fill")
                        }
                    }
                    // Merge/Convert button: if scanned and has at least one unmerged room with JSON
                    if project.isScannedByApp && unmergedRoomsWithJSONCount >= 1 {
                        Button {
                            Task {
                                await mergeRooms()
                            }
                        } label: {
                            Label(unmergedRoomsCount > 1 ? "Fusionner les pièces" : "Convertir en USDZ", systemImage: "square.stack.3d.down.right")
                        }
                        .disabled(isMerging)
                    }
                    // Upload JSON Room(s)
                    /*
                    if project.isScannedByApp {
                        Button {
                            isImportingJSON = true
                        } label: {
                            Label("Importer des pièces JSON", systemImage: "square.and.arrow.down")
                        }
                    }
                    */
                    Menu {
                        if let (_, jsonURL) = firstRoomWithJSON {
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
                        Divider()
                        Button {
                            newProjectNameForAlert = project.name
                            isShowingProjectRenameAlert = true
                        } label: {
                            Label("Renommer le projet", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            isShowingProjectDeleteConfirmation = true
                        } label: {
                            Label("Supprimer le projet", systemImage: "trash")
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
            .alert("Supprimer la pièce ?", isPresented: $isShowingDeleteConfirmation, actions: {
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
            }, message: {
                if let room = roomToDelete {
                    Text("Êtes-vous sûr de vouloir supprimer la pièce « \(room.name) » ?")
                }
            })
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
            .alert("Renommer le projet", isPresented: $isShowingProjectRenameAlert, actions: {
                TextField("Nom du projet", text: $newProjectNameForAlert)
                Button("Enregistrer") {
                    let trimmed = newProjectNameForAlert.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        var updated = project
                        updated.name = trimmed
                        ProjectController.shared.updateProject(updated)
                    }
                    isShowingProjectRenameAlert = false
                }
                Button("Annuler", role: .cancel) {
                    isShowingProjectRenameAlert = false
                }
            }, message: {
                Text("Entrer le nouveau nom du projet.")
            })
            .alert("Supprimer le projet ?", isPresented: $isShowingProjectDeleteConfirmation, actions: {
                Button("Supprimer le projet", role: .destructive) {
                    // Suppression du projet via ProjectController
                    if let idx = ProjectController.shared.projects.firstIndex(where: { $0.id == project.id }) {
                        ProjectController.shared.deleteProjects(at: IndexSet(integer: idx))
                    }
                    // Revenir à l'écran précédent
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            }, message: {
                Text("Êtes-vous sûr de vouloir supprimer le projet « \(project.name) » ? Cette action est irréversible.")
            })
            .alert("Erreur", isPresented: .constant(mergeError != nil), actions: {
                Button("OK", role: .cancel) { mergeError = nil }
            }, message: {
                if let mergeError { Text(mergeError) }
            })
            .fullScreenCover(isPresented: $isShowingMultiRoomScanView) {
                MultiRoomCaptureScanView(projectId: project.id) { capturedRooms, roomNames in
                    addMultipleScannedRooms(capturedRooms, names: roomNames)
                    isShowingMultiRoomScanView = false
                }
            }
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

    // MARK: - Add multiple scanned rooms
    private func addMultipleScannedRooms(_ capturedRooms: [CapturedRoom], names: [String]) {
        // Safety check: ensure we have names for all rooms
        guard !capturedRooms.isEmpty else {
            mergeError = "Aucune pièce à ajouter."
            return
        }
        
        // Ensure names array matches rooms count
        var finalNames = names
        while finalNames.count < capturedRooms.count {
            let index = finalNames.count
            finalNames.append("Pièce \(index + 1)")
        }
        
        // Trim if too many names (shouldn't happen, but safety check)
        if finalNames.count > capturedRooms.count {
            finalNames = Array(finalNames.prefix(capturedRooms.count))
        }
        
        guard capturedRooms.count == finalNames.count else {
            mergeError = "Erreur: Le nombre de pièces (\(capturedRooms.count)) et de noms (\(finalNames.count)) ne correspond pas."
            return
        }
        
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let baseDir = (appSupport ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!)
            .appendingPathComponent("PlanSpace2D", isDirectory: true)
        let projectDir = baseDir.appendingPathComponent(project.id.uuidString, isDirectory: true)
        
        if !fm.fileExists(atPath: projectDir.path) {
            try? fm.createDirectory(at: projectDir, withIntermediateDirectories: true)
        }
        
        var newRooms: [ProjectRoom] = []
        var errors: [String] = []
        
        for (index, capturedRoom) in capturedRooms.enumerated() {
            let roomName = finalNames[index]
            
            // Generate filename based on room name
            let sanitizedName = roomName
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: "/", with: "-")
            let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: ":", with: "-")
            let fileName = "\(sanitizedName)_\(timestamp)_\(index).json"
            let jsonURL = projectDir.appendingPathComponent(fileName)
            
            // Encode and save JSON
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonData = try encoder.encode(capturedRoom)
                try jsonData.write(to: jsonURL, options: [.atomic])
                
                // Create ProjectRoom
                let newRoom = ProjectRoom(
                    name: roomName,
                    fileURLJSON: jsonURL,
                    fileURLUSDZ: nil,
                    data: jsonData
                )
                newRooms.append(newRoom)
            } catch {
                // Collect error but continue processing other rooms
                errors.append("\(roomName): \(error.localizedDescription)")
            }
        }
        
        // Add all successfully saved rooms to project
        if !newRooms.isEmpty {
            rooms.append(contentsOf: newRooms)
            var updatedProject = project
            updatedProject.rooms = rooms
            ProjectController.shared.updateProject(updatedProject)
        }
        
        // Show error message if there were any failures, but don't prevent adding successful rooms
        if !errors.isEmpty {
            if newRooms.isEmpty {
                // All rooms failed
                mergeError = "Erreur lors de la sauvegarde des pièces :\n" + errors.joined(separator: "\n")
            } else {
                // Some rooms succeeded, some failed
                mergeError = "\(newRooms.count) pièce(s) ajoutée(s) avec succès. Erreurs :\n" + errors.joined(separator: "\n")
            }
        }
    }
    
    // MARK: - Merge rooms or convert single room to USDZ
    @MainActor
    private func mergeRooms() async {
        // Get all unmerged rooms with JSON files
        let unmergedRooms = rooms.filter { !$0.merged && $0.fileURLJSON != nil }
        
        guard !unmergedRooms.isEmpty else {
            mergeError = "Aucune pièce avec fichier JSON disponible."
            return
        }
        
        isMerging = true
        mergeError = nil
        
        do {
            // Load all CapturedRoom objects from JSON files
            var capturedRooms: [CapturedRoom] = []
            for room in unmergedRooms {
                guard let jsonURL = room.fileURLJSON else { continue }
                let data = try Data(contentsOf: jsonURL)
                let capturedRoom = try JSONDecoder().decode(CapturedRoom.self, from: data)
                capturedRooms.append(capturedRoom)
            }
            
            guard !capturedRooms.isEmpty else {
                mergeError = "Impossible de charger les données des pièces."
                isMerging = false
                return
            }
            
            let fm = FileManager.default
            let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let baseDir = (appSupport ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!)
                .appendingPathComponent("PlanSpace2D", isDirectory: true)
            let projectDir = baseDir.appendingPathComponent(project.id.uuidString, isDirectory: true)
            
            if !fm.fileExists(atPath: projectDir.path) {
                try? fm.createDirectory(at: projectDir, withIntermediateDirectories: true)
            }
            
            let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: ":", with: "-")
            
            if capturedRooms.count == 1 {
                // Single room: just convert JSON to USDZ
                let capturedRoom = capturedRooms[0]
                let roomName = unmergedRooms[0].name
                let sanitizedName = roomName
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: ":", with: "-")
                    .replacingOccurrences(of: "/", with: "-")
                let usdzFileName = "\(sanitizedName)_\(timestamp).usdz"
                let usdzURL = projectDir.appendingPathComponent(usdzFileName)
                
                // Export single room to USDZ
                try capturedRoom.export(to: usdzURL, exportOptions: .parametric)
                
                // Update the room to include USDZ URL
                var updatedRooms = rooms
                if let index = updatedRooms.firstIndex(where: { $0.id == unmergedRooms[0].id }) {
                    updatedRooms[index].fileURLUSDZ = usdzURL
                }
                
                // Update project
                rooms = updatedRooms
                var updatedProject = project
                updatedProject.rooms = rooms
                ProjectController.shared.updateProject(updatedProject)
            } else {
                // Multiple rooms: merge them
                // Create StructureBuilder and merge rooms
                // StructureBuilder is available in iOS 17+
                let structureBuilder = StructureBuilder(options: [.beautifyObjects])
                let capturedStructure = try await structureBuilder.capturedStructure(from: capturedRooms)
                
                // Export to USDZ
                let usdzFileName = "Merged_\(timestamp).usdz"
                let usdzURL = projectDir.appendingPathComponent(usdzFileName)
                
                try capturedStructure.export(to: usdzURL)
                
                // Convert CapturedStructure back to CapturedRoom for JSON storage
                // Note: We'll store the structure data, but for compatibility we create a merged room entry
                let mergedRoomName = "Pièces fusionnées (\(unmergedRooms.count))"
                
                // Create a merged ProjectRoom
                let mergedRoom = ProjectRoom(
                    name: mergedRoomName,
                    fileURLJSON: nil, // Merged structures don't have JSON representation
                    fileURLUSDZ: usdzURL,
                    data: nil,
                    merged: true
                )
                
                // Mark original rooms as merged
                var updatedRooms = rooms
                let unmergedRoomIds = Set(unmergedRooms.map { $0.id })
                for i in 0..<updatedRooms.count {
                    if unmergedRoomIds.contains(updatedRooms[i].id) {
                        updatedRooms[i].merged = true
                    }
                }
                
                // Add the merged room
                updatedRooms.append(mergedRoom)
                
                // Update project
                rooms = updatedRooms
                var updatedProject = project
                updatedProject.rooms = rooms
                ProjectController.shared.updateProject(updatedProject)
            }
            
            isMerging = false
        } catch {
            isMerging = false
            mergeError = "Erreur lors de la conversion : \(error.localizedDescription)"
        }
    }
    
    // MARK: - Import multiple JSON rooms
    private func importJSONRooms(from urls: [URL]) {
        var newRooms: [ProjectRoom] = []
        let targetDir = rooms.first?.fileURLJSON?.deletingLastPathComponent()
        for url in urls {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }
            guard didAccess else {
                mergeError = "Impossible d'accéder au fichier sécurisé : \(url.lastPathComponent)"
                continue
            }
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

