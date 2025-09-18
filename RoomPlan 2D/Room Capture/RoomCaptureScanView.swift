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

    var body: some View {
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
                SpriteView(scene: FloorPlanScene(capturedRoom: room))
                    .ignoresSafeArea()
            }
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
