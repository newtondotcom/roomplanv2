//
//  MultiRoomCaptureScanView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//

import SwiftUI
import RoomPlan

struct MultiRoomCaptureScanView: View {
    let projectId: UUID
    let onRoomsScanned: ([CapturedRoom], [String]) -> Void
    
    @StateObject private var model = MultiRoomCaptureModel.shared
    @State private var roomNames: [String] = []
    @State private var currentRoomIndex: Int = 0
    @State private var showNamingInput = false
    @State private var currentRoomName: String = ""
    @FocusState private var isNameFieldFocused: Bool
    @State private var toastMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Show AR view only when scanning, otherwise show gradient background
            if model.isScanning {
                MultiRoomCaptureRepresentable()
                    .ignoresSafeArea()
            } else {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.15, blue: 0.3),
                        Color(red: 0.15, green: 0.2, blue: 0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            VStack {
                // Back button and header
                HStack {
                    // Back button - only show when not scanning and no rooms scanned yet
                    if !model.isScanning && model.capturedRooms.isEmpty {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(.leading)
                    } else {
                        Spacer()
                            .frame(width: 44)
                            .padding(.leading)
                    }
                    
                    Spacer()
                    
                    // Header with room count
                    VStack(spacing: 8) {
                        Text("Scan multi-pièces")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(model.capturedRooms.count) pièce(s) scannée(s)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                    
                    // Balance spacer
                    Spacer()
                        .frame(width: 44)
                        .padding(.trailing)
                }
                .padding(.top)
                
                Spacer()
                
                if showNamingInput {
                    // Show naming input only (no 3D preview)
                    VStack(spacing: 16) {
                        Text("Nommer la pièce \(currentRoomIndex + 1)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Ex: Salon, Chambre, Cuisine...", text: $currentRoomName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .focused($isNameFieldFocused)
                            .onSubmit {
                                saveCurrentRoom()
                            }
                        
                        HStack(spacing: 16) {
                            Button("Annuler") {
                                model.endSession()
                                dismiss()
                            }
                            .foregroundColor(.white)
                            
                            Button("Suivant") {
                                saveCurrentRoom()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(currentRoomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color("AccentColor"))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .fontWeight(.bold)
                            .disabled(currentRoomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Scanning controls
                    VStack(spacing: 16) {
                        if model.isScanning {
                            Button("Terminer cette pièce") {
                                Task { @MainActor in
                                    toastMessage = "Arrêt du scan de la pièce en cours..."
                                    model.stopCurrentRoomScan()
                                    // Wait for delegate to set currentRoomData
                                    await waitForRoomData()
                                    await processRoomData()
                                }
                            }
                            .padding()
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .fontWeight(.bold)
                        } else {
                            if model.capturedRooms.isEmpty {
                            Button("Commencer le scan") {
                                Task { @MainActor in
                                    toastMessage = "Démarrage du scan de la première pièce..."
                                    model.startSession()
                                }
                            }
                                .padding()
                                .background(Color("AccentColor"))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .fontWeight(.bold)
                            } else {
                                Button("Scanner la pièce suivante") {
                                    Task { @MainActor in
                                        let nextRoomNumber = model.capturedRooms.count + 1
                                        toastMessage = "Démarrage du scan de la pièce \(nextRoomNumber)..."
                                        model.startSession()
                                    }
                                }
                                .padding()
                                .background(Color("AccentColor"))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .fontWeight(.bold)
                                Button("Terminer le scan") {
                                    finishScan()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .fontWeight(.bold)
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .onChange(of: toastMessage) { newValue in
            if newValue != nil {
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    toastMessage = nil
                }
            }
        }
        .onAppear {
            // Reset any previous session but keep captured rooms if any
            Task { @MainActor in
                // Only reset if we're starting fresh (no rooms yet)
                if model.capturedRooms.isEmpty {
                    model.endSession()
                } else {
                    // Keep existing rooms but reset scanning state
                    model.isScanning = false
                    model.currentRoomData = nil
                }
            }
        }
        .onDisappear {
            if !showNamingInput {
                Task { @MainActor in
                    model.endSession()
                }
            }
        }
    }
    
    private func waitForRoomData() async {
        // Wait for delegate to set currentRoomData (max 3 seconds)
        let maxWaitTime: TimeInterval = 3.0
        let startTime = Date()
        
        while model.currentRoomData == nil && Date().timeIntervalSince(startTime) < maxWaitTime {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        await MainActor.run {
            if model.currentRoomData == nil {
                toastMessage = "⚠️ Aucune donnée reçue après l'arrêt du scan"
                print("Warning: No room data received after stopping scan")
            } else {
                toastMessage = "✓ Données de la pièce reçues"
            }
        }
    }
    
    private func processRoomData() async {
        await MainActor.run {
            let message = "Traitement de la pièce... (\(model.capturedRooms.count + 1) pièce(s) au total)"
            toastMessage = message
            print("[MultiRoomCaptureScanView] Processing room data. Current rooms: \(model.capturedRooms.count), has data: \(model.currentRoomData != nil)")
        }
        
        do {
            try await model.processCurrentRoom()
            
            // Show naming input after room is processed
            await MainActor.run {
                let totalRooms = model.capturedRooms.count
                toastMessage = "Pièce traitée avec succès! (\(totalRooms) pièce(s))"
                print("[MultiRoomCaptureScanView] Room processed successfully. Total rooms: \(totalRooms)")
                
                guard totalRooms > 0 else {
                    toastMessage = "Erreur: Aucune pièce après traitement!"
                    print("[MultiRoomCaptureScanView] Error: No rooms after processing!")
                    return
                }
                
                let newRoomIndex = model.capturedRooms.count - 1
                currentRoomIndex = newRoomIndex
                
                // Ensure roomNames array is large enough
                while roomNames.count <= newRoomIndex {
                    roomNames.append("")
                }
                
                // Set default name if not already set
                if roomNames[newRoomIndex].isEmpty {
                    currentRoomName = "Pièce \(newRoomIndex + 1)"
                } else {
                    currentRoomName = roomNames[newRoomIndex]
                }
                
                withAnimation {
                    showNamingInput = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isNameFieldFocused = true
                }
            }
        } catch {
            print("[MultiRoomCaptureScanView] Error processing room: \(error)")
            await MainActor.run {
                let errorMsg = "Erreur: \(error.localizedDescription)"
                toastMessage = errorMsg
                // Even if there's an error, try to continue if we have rooms
                print("[MultiRoomCaptureScanView] After error, rooms count: \(model.capturedRooms.count)")
                if model.capturedRooms.count > 0 {
                    let newRoomIndex = model.capturedRooms.count - 1
                    currentRoomIndex = newRoomIndex
                    while roomNames.count <= newRoomIndex {
                        roomNames.append("")
                    }
                    currentRoomName = "Pièce \(newRoomIndex + 1)"
                    withAnimation {
                        showNamingInput = true
                    }
                } else {
                    print("[MultiRoomCaptureScanView] No rooms available after error. Cannot continue.")
                }
            }
        }
    }
    
    private func continueToNextRoom() {
        // After saving the room name, restart scanning for the next room immediately
        Task { @MainActor in
            let nextRoomNumber = model.capturedRooms.count + 1
            toastMessage = "Démarrage du scan de la pièce \(nextRoomNumber)..."
            print("[MultiRoomCaptureScanView] Continuing to next room...")
            // Minimal delay to ensure UI is ready, then restart immediately
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if !model.isScanning {
                print("[MultiRoomCaptureScanView] Restarting session for next room")
                model.restartSessionForNextRoom()
                toastMessage = "Scan de la pièce \(nextRoomNumber) en cours..."
            } else {
                print("[MultiRoomCaptureScanView] Session already running, skipping restart")
                toastMessage = "Session déjà active"
            }
        }
    }
    
    private func saveCurrentRoom() {
        let trimmedName = currentRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Ensure we have enough room names array
        while roomNames.count < model.capturedRooms.count {
            roomNames.append("")
        }
        
        // Update the name for the current room index
        if currentRoomIndex < roomNames.count {
            roomNames[currentRoomIndex] = trimmedName
        } else {
            roomNames.append(trimmedName)
        }
        
        // Hide naming input, return to scanning controls
        // User must explicitly choose to scan next room or finish scan
        withAnimation {
            showNamingInput = false
        }
        currentRoomName = ""
        
        toastMessage = "Pièce \"\(trimmedName)\" enregistrée"
    }
    
    private func finishScan() {
        // First, save current room name if we're in naming mode
        if showNamingInput {
            let trimmedName = currentRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                // Ensure we have enough room names array
                while roomNames.count < model.capturedRooms.count {
                    roomNames.append("")
                }
                if currentRoomIndex < roomNames.count {
                    roomNames[currentRoomIndex] = trimmedName
                }
            }
        }
        
        // Process any pending room data that hasn't been processed yet
        if model.currentRoomData != nil {
            Task {
                do {
                    try await model.processCurrentRoom()
                    // After processing, ensure we have a name for this new room
                    await MainActor.run {
                        let newIndex = model.capturedRooms.count - 1
                        while roomNames.count <= newIndex {
                            roomNames.append("")
                        }
                        if roomNames[newIndex].isEmpty {
                            roomNames[newIndex] = "Pièce \(newIndex + 1)"
                        }
                        completeScan()
                    }
                } catch {
                    await MainActor.run {
                        print("Error processing final room: \(error)")
                        completeScan()
                    }
                }
            }
        } else {
            completeScan()
        }
    }
    
    private func completeScan() {
        // IMPORTANT: Save the rooms data BEFORE calling endSession() which clears it
        let roomsToSave = model.capturedRooms
        let roomsCount = roomsToSave.count
        
        toastMessage = "Finalisation du scan... \(roomsCount) pièce(s)"
        print("[MultiRoomCaptureScanView] Completing scan with \(roomsCount) rooms")
        
        // Ensure we have names for all rooms - this is critical
        while roomNames.count < roomsCount {
            let index = roomNames.count
            roomNames.append("Pièce \(index + 1)")
        }
        
        // Trim the array if it's longer than needed (shouldn't happen, but safety check)
        if roomNames.count > roomsCount {
            roomNames = Array(roomNames.prefix(roomsCount))
        }
        
        // Verify we have the correct count before calling the callback
        if roomNames.count != roomsCount {
            toastMessage = "⚠️ Correction des noms: \(roomsCount) pièces"
            print("Error: Mismatch between rooms (\(roomsCount)) and names (\(roomNames.count))")
            // Still try to complete with default names
            roomNames = (0..<roomsCount).map { "Pièce \($0 + 1)" }
        }
        
        // Call the callback with the rooms data BEFORE clearing them
        toastMessage = "✓ \(roomsCount) pièce(s) enregistrée(s)"
        onRoomsScanned(roomsToSave, roomNames)
        
        // Now we can safely end the session and clear the data
        model.endSession()
        dismiss()
    }
}
