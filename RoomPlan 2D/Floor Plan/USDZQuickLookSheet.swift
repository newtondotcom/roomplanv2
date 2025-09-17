//
//  USDZQuickLookSheet.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 17/09/2025.
//


import SwiftUI

struct USDZQuickLookSheet: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    var body: some View {
        ZStack(alignment: .topTrailing) {
            USDZQuickLookView(url: url)
                .ignoresSafeArea()

            HStack(spacing: 12) {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                }

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
            }
            .padding(12)
        }
    }
}


