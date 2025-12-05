//
//  MultiRoomCaptureModel.swift
//  PlanSpace
//
//  Created by Robin Augereau on 18/09/2025.
//

import Foundation
import RoomPlan

/// Model for scanning multiple rooms in a single structure with continuous AR session
class MultiRoomCaptureModel: ObservableObject, RoomCaptureSessionDelegate {
    
    // Singleton
    static let shared = MultiRoomCaptureModel()
    
    // The capture view
    let roomCaptureView: RoomCaptureView
    
    // Capture configuration for continuous scanning
    private let captureSessionConfig: RoomCaptureSession.Configuration
    private let roomBuilder: RoomBuilder
    
    // Collected rooms from the multi-room scan
    @Published var capturedRooms: [CapturedRoom] = []
    
    // Current room being scanned
    @Published var currentRoomData: CapturedRoomData?
    @Published var isScanning = false
    
    // Required functions to conform to NSCoding protocol
    func encode(with coder: NSCoder) {
    }
    
    required init?(coder: NSCoder) {
        fatalError("Error when initializing MultiRoomCaptureModel")
    }
    
    // Private initializer. Accessed by shared.
    private init() {
        roomCaptureView = RoomCaptureView(frame: .zero)
        captureSessionConfig = RoomCaptureSession.Configuration()
        // Enable continuous scanning mode
        roomBuilder = RoomBuilder(options: [.beautifyObjects])
        
        roomCaptureView.captureSession.delegate = self
    }
    
    // Start the continuous capture session
    @MainActor
    func startSession() {
        guard !isScanning else {
            print("[MultiRoomCaptureModel] Session already running, skipping start")
            return
        }
        print("[MultiRoomCaptureModel] Starting session...")
        isScanning = true
        roomCaptureView.captureSession.run(configuration: captureSessionConfig)
        print("[MultiRoomCaptureModel] Session started")
    }
    
    // Stop the current room scan (but keep AR session active for next room)
    @MainActor
    func stopCurrentRoomScan() {
        guard isScanning else { return }
        print("[MultiRoomCaptureModel] Stopping current room scan...")
        isScanning = false
        // pauseARSession:false means the AR session will continue to run in the background
        roomCaptureView.captureSession.stop(pauseARSession:false)
        // Note: After stop(), the delegate will be called with the room data
        // We'll restart the session immediately after processing to maintain continuity
    }
    
    // Restart the session for the next room scan
    @MainActor
    func restartSessionForNextRoom() {
        guard !isScanning else {
            print("[MultiRoomCaptureModel] Session already running, skipping restart")
            return
        }
        print("[MultiRoomCaptureModel] Restarting session for next room...")
        isScanning = true
        // Use the same configuration to maintain AR session continuity
        roomCaptureView.captureSession.run(configuration: captureSessionConfig)
        print("[MultiRoomCaptureModel] Session restarted for next room")
    }
    
    // Complete the multi-room scan and close the AR session
    @MainActor
    func endSession() {
        print("[MultiRoomCaptureModel] Ending session. Current rooms count: \(capturedRooms.count)")
        isScanning = false
        // pauseARSession:true means the AR session will be stopped and the AR session removed
        roomCaptureView.captureSession.stop(pauseARSession:true)
        capturedRooms.removeAll()
        currentRoomData = nil
        print("[MultiRoomCaptureModel] Session ended, rooms cleared")
    }
    
    // Reset scanning state without clearing captured rooms
    @MainActor
    func resetScanningState() {
        isScanning = false
        currentRoomData = nil
    }
    
    // Process the current room scan and add it to the collection
    @MainActor
    func processCurrentRoom() async throws {
        guard let data = currentRoomData else {
            print("[MultiRoomCaptureModel] Error: No currentRoomData available")
            throw MultiRoomCaptureError.noRoomData
        }
        
        print("[MultiRoomCaptureModel] Processing room data...")
        let capturedRoom = try await roomBuilder.capturedRoom(from: data)
        capturedRooms.append(capturedRoom)
        print("[MultiRoomCaptureModel] Room added. Total rooms: \(capturedRooms.count)")
        currentRoomData = nil
    }
    
    // RoomCaptureSessionDelegate - must be nonisolated
    nonisolated func captureSession(
        _ session: RoomCaptureSession,
        didEndWith data: CapturedRoomData,
        error: Error?
    ) {
        if let error {
            print("Error ending capture session; \(error)")
            Task { @MainActor [weak self] in
                self?.isScanning = false
            }
            return
        }
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            print("[MultiRoomCaptureModel] Room data received, processing...")
            self.currentRoomData = data
            self.isScanning = false
            print("[MultiRoomCaptureModel] currentRoomData set, isScanning = false. Total rooms: \(self.capturedRooms.count)")
        }
    }
}

enum MultiRoomCaptureError: LocalizedError {
    case noRoomData
    case sessionNotActive
    
    var errorDescription: String? {
        switch self {
        case .noRoomData:
            return "Aucune donnée de pièce disponible."
        case .sessionNotActive:
            return "La session de scan n'est pas active."
        }
    }
}
