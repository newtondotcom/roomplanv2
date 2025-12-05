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
    var onProceed: (() -> Void)? = nil

    var body: some View {
        ZStack {
            USDZQuickLookView(url: url)
                .ignoresSafeArea()

            // Dismiss top-left
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(12)

            // Share + proceed top-right
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.title)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.6))
                        }
                    }
                }
                Spacer()
            }
            .padding(12)
        }
    }
}


