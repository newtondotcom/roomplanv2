//
//  WelcomeView.swift
//  RoomPlan 2D
//
//  Created by Dennis van Oosten on 24/02/2023.
//

import SwiftUI
import _SpriteKit_SwiftUI
import RoomPlan
import UniformTypeIdentifiers

struct WelcomeView: View {
    @StateObject private var controller = WelcomeController()

    var body: some View {
        VStack {
            Image(systemName: "house")
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .padding(.bottom, 8)

            Text("RoomPlan 2D")
                .font(.title)
                .fontWeight(.bold)
            Text("Scan your room and create a 2D floor plan.")

            Spacer().frame(height: 50)

            if #available(iOS 26.0, *) {
                NavigationLink("Start Scanning") {
                    RoomCaptureScanView()
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .tint(Color("AccentColor"))
                .sheet(isPresented: $controller.showFloorPlan) {
                    if let room = controller.importedRoom {
                        FloorPlanView(capturedRoom: room)
                    }
                }
                .fullScreenCover(isPresented: $controller.showScanner) {
                    RoomCaptureScanView()
                }
            } else {
                NavigationLink("Start Scanning") {
                    RoomCaptureScanView()
                }
                .controlSize(.large)
                .tint(Color("AccentColor"))
                .sheet(isPresented: $controller.showFloorPlan) {
                    if let room = controller.importedRoom {
                        FloorPlanView(capturedRoom: room)
                    }
                }
                .fullScreenCover(isPresented: $controller.showScanner) {
                    RoomCaptureScanView()
                }
            }

            Button {
                controller.isImportingJSON = true
            } label: {
                Text("Import Scan")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color("AccentColor"))
            .padding(.top, 8)
            .fileImporter(
                isPresented: $controller.isImportingJSON,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                controller.handleJSONImportResult(result)
            }

            Button {
                controller.isImportingUSDZ = true
            } label: {
                Text("Import USDZ")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.top, 8)
            .fileImporter(
                isPresented: $controller.isImportingUSDZ,
                allowedContentTypes: [UTType.usdz, UTType(filenameExtension: "usdz")!],
                allowsMultipleSelection: false
            ) { result in
                controller.handleUSDZImportResult(result)
            }

            if let error = controller.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal)
            }
        }
        .confirmationDialog(
            "Que souhaitez-vous afficher ?",
            isPresented: .constant(false), // no longer used; navigation is explicit
            titleVisibility: .visible
        ) {
            // Intentionally empty or remove if not needed
        }
        .sheet(isPresented: $controller.showUSDZ) {
            if let url = controller.usdzURL {
                USDZQuickLookSheet(url: url)
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WelcomeView()
        }
    }
}
