//
//  MultiRoomCaptureRepresentable.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//

import RoomPlan
import SwiftUI

struct MultiRoomCaptureRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> RoomCaptureView {
        return MultiRoomCaptureModel.shared.roomCaptureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
    }
    
}
