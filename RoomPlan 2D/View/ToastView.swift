//
//  ToastView 2.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 05/12/2025.
//


//
//  ToastView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//

import SwiftUI

struct ToastView: ViewModifier {
    @Binding var message: String?
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = message, isVisible {
                    Text(message)
                        .padding()
                        .background(.ultraThinMaterial)
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            withAnimation(.spring()) {
                                isVisible = true
                            }
                            // Auto-dismiss after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation(.spring()) {
                                    isVisible = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.message = nil
                                }
                            }
                        }
                }
            }
            .onChange(of: message) { newValue in
                if newValue != nil {
                    isVisible = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring()) {
                            isVisible = true
                        }
                    }
                }
            }
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastView(message: message))
    }
}
