//
//  WelcomeController.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//


import Foundation
import RoomPlan
import UniformTypeIdentifiers

@MainActor
final class WelcomeController: ObservableObject {
    // File importer presentation
    @Published var isImportingJSON = false
    @Published var isImportingUSDZ = false

    // Navigation / presentation
    @Published var importedRoom: CapturedRoom?
    @Published var showFloorPlan = false
    @Published var showScanner = false
    @Published var showUSDZ = false
    @Published var usdzURL: URL?

    // Errors
    @Published var errorMessage: String?

    private let importer: RoomImporting

    init(importer: RoomImporting = RoomImportController()) {
        self.importer = importer
    }

    func handleJSONImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                errorMessage = "Aucun fichier sélectionné."
                return
            }
            do {
                let room = try importer.importCapturedRoom(from: url)
                importedRoom = room
                showFloorPlan = true
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        case .failure(let error):
            errorMessage = "Échec de l'import: \(error.localizedDescription)"
        }
    }

    func handleUSDZImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                errorMessage = "Aucun fichier sélectionné."
                return
            }
            usdzURL = url
            showUSDZ = true
        case .failure(let error):
            errorMessage = "Échec de l'import USDZ: \(error.localizedDescription)"
        }
    }
}


