//
//  MultiRoomCaptureRepresentable.swift
//  PlanSpace
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
