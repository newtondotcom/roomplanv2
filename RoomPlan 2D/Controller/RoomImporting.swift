//
//  RoomImporting.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//


import Foundation
import RoomPlan

protocol RoomImporting {
    func importCapturedRoom(from url: URL) throws -> CapturedRoom
}

final class RoomImportController: RoomImporting {
    enum ImportError: LocalizedError {
        case notReachable
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .notReachable:
                return "Le fichier n’est pas accessible."
            case .decodingFailed(let error):
                return "Impossible d’ouvrir le fichier : \(error.localizedDescription)"
            }
        }
    }

    func importCapturedRoom(from url: URL) throws -> CapturedRoom {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw ImportError.notReachable
        }

        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(CapturedRoom.self, from: data)
        } catch {
            throw ImportError.decodingFailed(error)
        }
    }
}