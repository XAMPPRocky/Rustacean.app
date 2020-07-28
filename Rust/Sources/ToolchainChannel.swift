import Foundation
import AppKit

@objc enum ToolchainChannel: Int {
    case stable
    case beta
    case nightly
    
    static var all = [ToolchainChannel.stable, .beta, .nightly]
    
    var slug: String {
        switch self {
        case .stable:
            return "stable"
        case .beta:
            return "beta"
        case .nightly:
            return "nightly"
        }
    }
    
    var description: String {
        switch self {
        case .stable:
            return "Stable (\(Rustc.version(.stable)))"
        case .beta:
            return "Beta"
        case .nightly:
            return "Nightly"
        }
    }
    
    var shortcutKey: String {
        switch self {
        case .stable:
            return "s"
        case .beta:
            return "b"
        case .nightly:
            return "t"
        }
    }
}
