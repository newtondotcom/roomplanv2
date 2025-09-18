//
//  RoomCaptureView.swift
//  RoomPlan 2D
//
//  Created by Dennis van Oosten on 24/02/2023.
//

import SwiftUI
import _SpriteKit_SwiftUI

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
