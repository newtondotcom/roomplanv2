//
//  Project.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//

import Foundation

struct ProjectRoom: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var fileURLJSON: URL?
    var fileURLUSDZ: URL?
    var data: Data?

    init(
        id: UUID = UUID(),
        name: String,
        fileURLJSON: URL? = nil,
        fileURLUSDZ: URL? = nil,
        data: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.fileURLJSON = fileURLJSON
        self.fileURLUSDZ = fileURLUSDZ
        self.data = data
    }
}

struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var rooms: [ProjectRoom]
    var dateCreation: Date
    var isScannedByApp: Bool

    init(
        id: UUID = UUID(),
        name: String,
        rooms: [ProjectRoom] = [],
        dateCreation: Date = Date(),
        isScannedByApp: Bool = false
    ) {
        self.id = id
        self.name = name
        self.rooms = rooms
        self.dateCreation = dateCreation
        self.isScannedByApp = isScannedByApp
    }
}



