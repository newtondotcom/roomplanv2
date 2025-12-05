//
//  SettingsView.swift
//  PlanSpace
//
//  Created by Robin Augereau on 18/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var enableHaptics = true
    @State private var useMetricUnits = true
    @State private var autosaveScans = false
    @State private var exportQuality: Double = 0.8

    var body: some View {
        NavigationStack {
            Form {
                Section("Général") {
                    Toggle("Haptique", isOn: $enableHaptics)
                    Toggle("Unités métriques", isOn: $useMetricUnits)
                }

                Section("Scans") {
                    Toggle("Enregistrer automatiquement", isOn: $autosaveScans)
                    HStack {
                        Text("Qualité d'export")
                        Spacer()
                        Slider(value: $exportQuality, in: 0.1...1.0, step: 0.1)
                            .frame(maxWidth: 200)
                    }
                }

                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://example.com")!) {
                        Label("Site web", systemImage: "link")
                    }
                }
            }
            .navigationTitle("Réglages")
            .scrollContentBackground(.hidden)
            .background(Color("BackgroundColor").ignoresSafeArea())
            .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .background(Color("BackgroundColor").ignoresSafeArea())
    }
}


