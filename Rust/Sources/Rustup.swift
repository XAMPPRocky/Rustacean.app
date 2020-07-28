import Foundation
import Toml

enum InstallProfile {
   case Minimal
   case Default
   case Complete
   
    /// Create install profile from string if matches.
    init?(string: String) {
        switch string {
        case "minimal":
            self = .Minimal
        case "default":
            self = .Default
        case "complete":
            self = .Complete
        default:
            return nil
        }
    }
    
    var description: String {
        switch self {
        case .Minimal:
            return "minimal"
        case .Default:
            return "default"
        case .Complete:
            return "complete"
        }
    }
}

// MARK: Rustup
class Rustup {
    
    static func output(_ channel: ToolchainChannel?, _ args: [String], callback: @escaping (String) -> ()) {
        Process.outputRustup(nil, channel, args, callback: callback)
    }
    
    static func output(_ args: [String], callback: @escaping (String) -> ()) {
        Process.outputRustup(nil, nil, args, callback: callback)
    }
    
    static func syncOutput(_ channel: ToolchainChannel?, _ args: [String]) throws -> String {
        return try Process.syncRustup(nil, channel, args)
    }
    
    static func syncOutput(_ args: [String]) throws -> String {
        return try syncOutput(nil, args)
    }

    static func initialise(profile: InstallProfile, noModifyPath: Bool, handler: @escaping (String) -> (), finally: @escaping (Int32) -> ()) throws {
        var args = ["-y"]
        
        args.append("--profile")
        args.append(profile.description)
        
        if noModifyPath {
            args.append("--no-modify-path")
        }
        
        Process.handleRustup("rustup-init", nil, args, handler: handler, finally: finally)
    }
    
    static func isPresent() -> Bool {
        return (try? syncOutput(["-h"])) != nil
    }
    
    static func getSettings() throws -> Toml? {
        return try? Toml(withString: String(contentsOf: appDir().appendingPathComponent("settings.toml")))
    }
    
    // MARK: Channel

    /// Returns the currently set channel from rustup.
    static func channel() -> ToolchainChannel {
        let settings = try! getSettings()
        let value = settings?.string("default_toolchain") ?? (try! Rustc.syncOutput(["-V"]))

        if value.contains(ToolchainChannel.beta.slug) {
            return .beta
        } else if value.contains(ToolchainChannel.nightly.slug) {
            return .nightly
        } else {
            return .stable
        }
    }

    static func set(channel: ToolchainChannel, _ callback: @escaping (String) -> ()) {
        Rustup.output(channel, ["default", "\(channel.slug)"], callback: callback)
    }

    // MARK: Target

    struct Target {
        let name: String;
        let installed: Bool;
    }

    static func targets(_ callback: @escaping ([Target]) -> ()) {
        return Rustup.targets(nil, callback)
    }

    static func targets(_ channel: ToolchainChannel?, _ callback: @escaping ([Target]) -> ()) {
        Rustup.output(channel, ["target", "list"]) {
            output in
            
            var targets: [Target] = []

            for line in output.components(separatedBy: .newlines) {
                let array = line.components(separatedBy: .whitespaces)
                targets.append(Target(name: array[0], installed: array.count == 2))
            }

            callback(targets)
        }
    }

    static func installedTargets(_ callback: @escaping ([Target]) -> ()) {
        Rustup.targets({ callback($0.filter({ $0.installed })) })
    }

    static func installedTargets(_ channel: ToolchainChannel?, _ callback: @escaping ([Target]) -> ()) {
        Rustup.targets(channel, { callback($0.filter({ $0.installed })) })
    }

    // MARK: Documentation
    static func documentationDirectory() -> URL {
        return URL(fileURLWithPath: try! syncOutput(["doc", "--std", "--path"])).deletingLastPathComponent()
    }

}

// MARK: Rustc
class Rustc {
    static func output(_ channel: ToolchainChannel?, _ args: [String], callback: @escaping (String) -> ()) {
        Process.outputRustup("rustc", channel, args, callback: callback)
    }
    
    static func output(_ args: [String], callback: @escaping (String) -> ()) {
        output(nil, args, callback: callback)
    }
    
    static func syncOutput(_ channel: ToolchainChannel?, _ args: [String]) throws -> String {
        return try Process.syncRustup("rustc", channel, args)
    }
    
    static func syncOutput(_ args: [String]) throws -> String {
        return try syncOutput(nil, args)
    }

    // MARK: Version
    /// Get current version number from the environment
    static func version() -> String {
        return version(nil)
    }
    /// Return the current version of a specific toolchain, or using the currently set toolchain if `nil`.
    static func version(_ channel: ToolchainChannel?) -> String {
        let output = try! syncOutput(channel, ["-V"])
        let regex = try! NSRegularExpression.init(pattern: "(\\d+.\\d+.\\d+)", options: [])
        let match = regex.firstMatch(in: output, options: [], range: .init(location: 0, length: output.lengthOfBytes(using: .utf8)))!

        return (output as NSString).substring(with: match.range(at: 0))
    }
}

// MARK: Cargo
class Cargo {
    static func output(_ channel: ToolchainChannel?, _ args: [String], callback: @escaping (String) -> ()) {
        Process.outputRustup("cargo", channel, args, callback: callback)
    }
    
    static func output(_ args: [String], callback: @escaping (String) -> ()) {
        output(nil, args, callback: callback)
    }
    
    static func syncOutput(_ channel: ToolchainChannel?, _ args: [String]) throws -> String {
        return try Process.syncRustup("cargo", channel, args)
    }
    
    static func syncOutput(_ args: [String]) throws -> String {
        return try syncOutput(nil, args)
    }

    // MARK: Version
    /// Get current version number from the environment
    static func version() -> String {
        return version(nil)
    }
    /// Return the current version of a specific toolchain, or using the currently set toolchain if `nil`.
    static func version(_ channel: ToolchainChannel?) -> String {
        let output = try! syncOutput(channel, ["-V"])
        let regex = try! NSRegularExpression.init(pattern: "(\\d+.\\d+.\\d+)", options: [])
        let match = regex.firstMatch(in: output, options: [], range: .init(location: 0, length: output.lengthOfBytes(using: .utf8)))!

        return (output as NSString).substring(with: match.range(at: 0))
    }
}

// MARK: URL Location Functions

func rustupUrl() -> URL {
    return Bundle.main.url(forResource: "rustup", withExtension: nil)!
}

func rustcUrl() -> URL {
    return cargoHome()
        .appendingPathComponent("bin", isDirectory: true)
        .appendingPathComponent("rustc", isDirectory: false)
}

func appDir() -> URL {
    return FileManager.default.homeDirectoryForCurrentUser
}

func rustupHome() -> URL {
    return appDir().appendingPathComponent(".rustup", isDirectory: true)
}

func cargoHome() -> URL {
    return appDir().appendingPathComponent(".cargo", isDirectory: true)
}
