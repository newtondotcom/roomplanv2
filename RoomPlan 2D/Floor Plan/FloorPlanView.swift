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
    var onProceed: (() -> Void)? = nil

    var body: some View {
        SpriteView(scene: FloorPlanScene(capturedRoom: capturedRoom))
            .ignoresSafeArea()
            .navigationTitle("Floor Plan")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .topLeading) {
                Button {
                    // Dismiss only, do not proceed to naming
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
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                    onProceed?()
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                        .padding(12)
                }
                .buttonStyle(.plain)
            }
    }
}


