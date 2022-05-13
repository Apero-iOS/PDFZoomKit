//
//  CaptureSession.swift
//  PDFZoomKit
//
//  Created by Trung on 11/08/2021.
//

import CoreMotion
import Foundation
import AVFoundation
import UIKit

/// A class containing global variables and settings for this capture session
final class CaptureSession {
    
    static let current = CaptureSession()
    
    /// The AVCaptureDevice used for the flash and focus setting
//    var device: CaptureDevice?
    
    /// Whether the user is past the scanning screen or not (needed to disable auto scan on other screens)
    var isEditing: Bool
    
    /// The status of auto scan. Auto scan tries to automatically scan a detected rectangle if it has a high enough accuracy.
    var isAutoScanEnabled: Bool
    
    /// The orientation of the captured image
    var editImageOrientation: CGImagePropertyOrientation
    
    private init(isAutoScanEnabled: Bool = true, editImageOrientation: CGImagePropertyOrientation = .up) {
//        self.device = AVCaptureDevice.default(for: .video)
        
        self.isEditing = false
        self.isAutoScanEnabled = isAutoScanEnabled
        self.editImageOrientation = editImageOrientation
    }
    
}

extension CaptureSession {
    /// Detect the current orientation of the device with CoreMotion and use it to set the `editImageOrientation`.
    func setImageOrientation() {
        let motion = CMMotionManager()
        
        /// This value should be 0.2, but since we only need one cycle (and stop updates immediately),
        /// we set it low to get the orientation immediately
        motion.accelerometerUpdateInterval = 0.01
        
        guard motion.isAccelerometerAvailable else { return }
        
        motion.startAccelerometerUpdates(to: OperationQueue()) { data, error in
            guard let data = data, error == nil else { return }
            
            /// The minimum amount of sensitivity for the landscape orientations
            /// This is to prevent the landscape orientation being incorrectly used
            /// Higher = easier for landscape to be detected, lower = easier for portrait to be detected
            let motionThreshold = 0.35
            
            if data.acceleration.x >= motionThreshold {
                self.editImageOrientation = .left
            } else if data.acceleration.x <= -motionThreshold {
                self.editImageOrientation = .right
            } else {
                /// This means the device is either in the 'up' or 'down' orientation, BUT,
                /// it's very rare for someone to be using their phone upside down, so we use 'up' all the time
                /// Which prevents accidentally making the document be scanned upside down
                self.editImageOrientation = .up
            }
            
            motion.stopAccelerometerUpdates()
            
            // If the device is reporting a specific landscape orientation, we'll use it over the accelerometer's update.
            // We don't use this to check for "portrait" because only the accelerometer works when portrait lock is enabled.
            // For some reason, the left/right orientations are incorrect (flipped) :/
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                self.editImageOrientation = .right
            case .landscapeRight:
                self.editImageOrientation = .left
            default:
                break
            }
        }
    }
}
