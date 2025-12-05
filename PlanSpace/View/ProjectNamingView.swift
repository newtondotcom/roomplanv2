//
//  ProjectNamingView.swift
//  PlanSpace
//
//  Created by Robin Augereau on 18/09/2025.
//


import SwiftUI

struct ProjectNamingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var projectName: String = ""

    let onConfirm: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Nom du projet")
                    .font(.headline)
                TextField("Ex: Appartement T2", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("BackgroundColor").ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        let trimmed = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onConfirm(trimmed)
                        dismiss()
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Nouveau projet")
            .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}


