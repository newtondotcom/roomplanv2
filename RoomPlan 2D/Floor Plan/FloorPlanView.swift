//
//  FloorPlanView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 17/09/2025.
//

import SwiftUI
import SpriteKit
import _SpriteKit_SwiftUI
import RoomPlan

struct FloorPlanView: View {
    @Environment(\.dismiss) private var dismiss
    let capturedRoom: CapturedRoom

    var body: some View {
        SpriteView(scene: FloorPlanScene(capturedRoom: capturedRoom))
            .ignoresSafeArea()
            .navigationTitle("Floor Plan")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                        .padding(12)
                }
                .buttonStyle(.plain)
            }
    }
}


