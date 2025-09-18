//
//  Scanning.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 18/09/2025.
//


import Foundation
import RoomPlan
import UIKit

protocol Scanning {
    var finalRoom: CapturedRoom? { get }
    func start()
    func stop()
}

final class ScanController: Scanning {
    private let model: RoomCaptureModel

    init(model: RoomCaptureModel = .shared) {
        self.model = model
    }

    var finalRoom: CapturedRoom? { model.finalRoom }

    func start() {
        model.startSession()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func stop() {
        model.stopSession()
        UIApplication.shared.isIdleTimerDisabled = false
    }
}