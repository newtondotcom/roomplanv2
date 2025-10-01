//
//  ProjectController.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//

import Foundation

@MainActor
final class ProjectController: ObservableObject {
    static let shared = ProjectController()

    @Published private(set) var projects: [Project] = [] {
        didSet {
            print("[ProjectController] Projects updated. Count=\(projects.count)")
            persist()
        }
    }

    private let fileURL: URL

    private init() {
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = (appSupport ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!)
            .appendingPathComponent("RoomPlan2D", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        fileURL = dir.appendingPathComponent("projects.json")
        load()
    }

    func addProject(name: String) {
        var new = Project(name: name)
        new.isScannedByApp = true;
        print("[ProjectController] Adding project: \(new.name) (id=\(new.id))")
        projects.append(new)
    }

    func addProject(name: String, rooms: [ProjectRoom], isScannedByApp: Bool) {
        let project = Project(name: name, rooms: rooms, isScannedByApp: isScannedByApp)
        print("[ProjectController] Adding project: \(project.name) rooms=\(rooms.count) scanned=\(isScannedByApp) (id=\(project.id))")
        projects.append(project)
    }

    func updateProject(_ project: Project) {
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[idx] = project
    }

    func deleteProjects(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
    }

    func project(withId id: UUID) -> Project? {
        projects.first(where: { $0.id == id })
    }

    // MARK: - Persistence
    func reload() {
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Project].self, from: data) {
            projects = decoded
            print("[ProjectController] Loaded persisted projects: \(projects.count)")
        } else {
            print("[ProjectController] Failed to decode persisted projects at \(fileURL.path)")
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(projects) {
            do {
                try data.write(to: fileURL, options: [.atomic])
                print("[ProjectController] Persisted projects to \(fileURL.path)")
            } catch {
                print("[ProjectController] Failed to persist: \(error)")
            }
        }
    }
}


