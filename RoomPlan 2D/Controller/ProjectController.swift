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
        didSet { persist() }
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
        projects.append(new)
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
    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(projects) {
            try? data.write(to: fileURL, options: [.atomic])
        }
    }
}


