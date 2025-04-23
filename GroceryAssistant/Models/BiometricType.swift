// MARK: - Biometric Authentication

import Foundation

/// Represents the available types of biometric authentication on the device.
enum BiometricType {
    /// No biometric authentication available
    case none
    
    /// Touch ID authentication
    case touchID
    
    /// Face ID authentication
    case faceID
}
