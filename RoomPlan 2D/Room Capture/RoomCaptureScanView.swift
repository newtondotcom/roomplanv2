//
//  RoomCaptureView.swift
//  RoomPlan 2D
//
//  Created by Dennis van Oosten on 24/02/2023.
//

import SwiftUI
import _SpriteKit_SwiftUI
import RoomPlan

struct RoomCaptureScanView: View {
    private let scanController = ScanController()
    private let model = RoomCaptureModel.shared

    @State private var isScanning = false
    @State private var isShowingFloorPlan = false
    @State private var showNamingSheet = false

    var body: some View {
        if #available(iOS 17.0, *) {
            ZStack {
                RoomCaptureRepresentable()
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Button(isScanning ? "Done" : "View 2D floor plan") {
                        if isScanning {
                            stopSession()
                        } else {
                            isShowingFloorPlan = true
                        }
                    }
                    .padding()
                    .background(Color("AccentColor"))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .fontWeight(.bold)
                    .padding(.bottom)
                }
            }
            .onAppear { startSession() }
            .fullScreenCover(isPresented: $isShowingFloorPlan) {
                if let room = model.finalRoom {
                    FloorPlanView(capturedRoom: room) {
                        // proceed to naming
                        let roomEntry = ProjectRoom(name: "Scan \(Date().formatted(date: .abbreviated, time: .shortened))", fileURLJSON: nil, fileURLUSDZ: nil, data: nil)
                        ProjectController.shared.addProject(name: roomEntry.name, rooms: [roomEntry], isScannedByApp: true)
                    }
                }
            }
            // No auto-naming on dismiss
        } else {
            ZStack {
                RoomCaptureRepresentable()
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Button(isScanning ? "Done" : "View 2D floor plan") {
                        if isScanning {
                            stopSession()
                        } else {
                            isShowingFloorPlan = true
                        }
                    }
                    .padding()
                    .background(Color("AccentColor"))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .fontWeight(.bold)
                    .padding(.bottom)
                }
            }
            .onAppear { startSession() }
            .fullScreenCover(isPresented: $isShowingFloorPlan) {
                if let room = model.finalRoom {
                    FloorPlanView(capturedRoom: room) {
                        let roomEntry = ProjectRoom(name: "Scan \(Date().formatted(date: .abbreviated, time: .shortened))", fileURLJSON: nil, fileURLUSDZ: nil, data: nil)
                        ProjectController.shared.addProject(name: roomEntry.name, rooms: [roomEntry], isScannedByApp: true)
                    }
                }
            }
            // No auto-naming on dismiss
        }
    }

    private func startSession() {
        isScanning = true
        scanController.start()
    }

    private func stopSession() {
        isScanning = false
        scanController.stop()
    }
}

struct RoomCaptureScanView_Previews: PreviewProvider {
    static var previews: some View {
        RoomCaptureScanView()
    }
}

// MARK: - RoomCaptureScanViewForProject
// Variant that adds scanned room to an existing project instead of creating a new project

struct RoomCaptureScanViewForProject: View {
    let projectId: UUID
    let onRoomScanned: (CapturedRoom, String) -> Void
    
    private let scanController = ScanController()
    private let model = RoomCaptureModel.shared
    
    @State private var isScanning = false
    @State private var roomName: String = ""
    @State private var showNamingInput = false
    @FocusState private var isNameFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if #available(iOS 17.0, *) {
            ZStack {
                RoomCaptureRepresentable()
                    .ignoresSafeArea()
                
                VStack {
                    if showNamingInput {
                        // Naming input overlay
                        VStack(spacing: 20) {
                            Text("Nommer la pièce")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Ex: Salon, Chambre, Cuisine...", text: $roomName)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                                .focused($isNameFieldFocused)
                                .onSubmit {
                                    proceedToFloorPlan()
                                }
                            
                            HStack(spacing: 16) {
                                Button("Annuler") {
                                    dismiss()
                                }
                                .foregroundColor(.white)
                                
                                Button("Enregistrer") {
                                    proceedToFloorPlan()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color("AccentColor"))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .fontWeight(.bold)
                                .disabled(roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Spacer()
                        Button(isScanning ? "Terminer le scan" : "Terminer") {
                            if isScanning {
                                stopSession()
                                // Show naming input after scan stops
                                roomName = "Pièce \(Date().formatted(date: .abbreviated, time: .omitted))"
                                withAnimation {
                                    showNamingInput = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isNameFieldFocused = true
                                }
                            } else {
                                proceedToFloorPlan()
                            }
                        }
                        .padding()
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .fontWeight(.bold)
                        .padding(.bottom)
                    }
                }
            }
            .onAppear { startSession() }
        } else {
            ZStack {
                RoomCaptureRepresentable()
                    .ignoresSafeArea()
                
                VStack {
                    if showNamingInput {
                        // Naming input overlay
                        VStack(spacing: 20) {
                            Text("Nommer la pièce")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Ex: Salon, Chambre, Cuisine...", text: $roomName)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                                .focused($isNameFieldFocused)
                                .onSubmit {
                                    proceedToFloorPlan()
                                }
                            
                            HStack(spacing: 16) {
                                Button("Annuler") {
                                    dismiss()
                                }
                                .foregroundColor(.white)
                                
                                Button("Enregistrer") {
                                    proceedToFloorPlan()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color("AccentColor"))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .fontWeight(.bold)
                                .disabled(roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Spacer()
                        Button(isScanning ? "Terminer le scan" : "Terminer") {
                            if isScanning {
                                stopSession()
                                // Show naming input after scan stops
                                roomName = "Pièce \(Date().formatted(date: .abbreviated, time: .omitted))"
                                withAnimation {
                                    showNamingInput = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isNameFieldFocused = true
                                }
                            } else {
                                proceedToFloorPlan()
                            }
                        }
                        .padding()
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .fontWeight(.bold)
                        .padding(.bottom)
                    }
                }
            }
            .onAppear { startSession() }
        }
    }
    
    private func proceedToFloorPlan() {
        guard !roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        // Instead of showing floor plan, directly add the room and dismiss
        if let room = model.finalRoom {
            let finalName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
            onRoomScanned(room, finalName)
            dismiss()
        }
    }
    
    private func startSession() {
        isScanning = true
        scanController.start()
    }
    
    private func stopSession() {
        isScanning = false
        scanController.stop()
    }
}
