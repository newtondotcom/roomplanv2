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
    @State private var isImporting = false
    @State private var importedRoom: CapturedRoom?
    @State private var navigateToPlan = false
    @State private var errorMessage: String?
    @State private var showImportOptions = false
    @State private var showScanner = false
    @State private var isImportingUSDZ = false
    @State private var usdzURL: URL?
    @State private var showUSDZ = false

    var body: some View {
        VStack {
            Image(systemName: "house")
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .padding(.bottom, 8)
            
            Text("RoomPlan 2D")
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                .fontWeight(.bold)
            Text("Scan your room and create a 2D floor plan.")
            
            Spacer()
                .frame(height: 50)
            
            if #available(iOS 26.0, *) {
                NavigationLink("Start Scanning") {
                    RoomCaptureScanView()
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .tint(Color("AccentColor"))
                
                // Sheet is triggered when choosing Floor Plan
                .sheet(isPresented: $navigateToPlan) {
                    if let importedRoom {
                        FloorPlanView(capturedRoom: importedRoom)
                    }
                }
                
                // Full screen cover for scanner option
                .fullScreenCover(isPresented: $showScanner) {
                    RoomCaptureScanView()
                }
            } else {
                NavigationLink("Start Scanning") {
                    RoomCaptureScanView()
                }
                .controlSize(.large)
                .tint(Color("AccentColor"))
                
                // Sheet is triggered when choosing Floor Plan
                .sheet(isPresented: $navigateToPlan) {
                    if let importedRoom {
                        FloorPlanView(capturedRoom: importedRoom)
                    }
                }
                
                // Full screen cover for scanner option
                .fullScreenCover(isPresented: $showScanner) {
                    RoomCaptureScanView()
                }
            }

            Button {
                isImporting = true
            } label: {
                Text("Import Scan")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color("AccentColor"))
            .padding(.top, 8)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else {
                        self.errorMessage = "Aucun fichier sélectionné."
                        return
                    }
                    importCapturedRoom(from: url)
                case .failure(let error):
                    self.errorMessage = "Échec de l'import: \(error)"
                }
            }

            Button {
                isImportingUSDZ = true
            } label: {
                Text("Import USDZ")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.top, 8)
            .fileImporter(
                isPresented: $isImportingUSDZ,
                allowedContentTypes: [UTType.usdz, UTType(filenameExtension: "usdz")!],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else {
                        self.errorMessage = "Aucun fichier sélectionné."
                        return
                    }
                    self.usdzURL = url
                    self.showUSDZ = true
                case .failure(let error):
                    self.errorMessage = "Échec de l'import USDZ: \(error)"
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal)
            }
        }
        .confirmationDialog(
            "Que souhaitez-vous afficher ?",
            isPresented: $showImportOptions,
            titleVisibility: .visible
        ) {
            Button("Voir le plan 2D") {
                navigateToPlan = true
            }
            Button("Ouvrir l'appareil de scan") {
                showScanner = true
            }
            Button("Annuler", role: .cancel) {}
        }
        .sheet(isPresented: $showUSDZ) {
            if let usdzURL {
                USDZQuickLookSheet(url: usdzURL)
            }
        }
    }

private func importCapturedRoom(from url: URL) {
    var didAccess = url.startAccessingSecurityScopedResource()
    defer {
        if didAccess {
            url.stopAccessingSecurityScopedResource()
        }
    }

    do {
        // Ensure file is reachable
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            self.errorMessage = "Le fichier n’est pas accessible."
            return
        }

        // Read contents
        let data = try Data(contentsOf: url)
        let capturedRoom = try JSONDecoder().decode(CapturedRoom.self, from: data)

        self.importedRoom = capturedRoom
        // Directly present the 2D floor plan after successful import
        self.navigateToPlan = true

    } catch {
        self.errorMessage = "Impossible d’ouvrir le fichier : \(error)"
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
