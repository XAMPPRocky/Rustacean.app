import Foundation

fileprivate func launchProcess(tool: String? = "rustup", channel: ToolchainChannel?, args: [String], pipe: Pipe) -> Process {
    let process = Process()
    var args = args
    var environment = ProcessInfo.processInfo.environment

    if let channel = channel {
        args.insert("+\(channel.slug)", at: 0)
    }

    environment["RUSTUP_HOME"] = rustupHome().path
    environment["CARGO_HOME"] = cargoHome().path
    environment["RUSTUP_FORCE_ARG0"] = tool
    environment["RUSTUP_INIT_SKIP_SUDO_CHECK"] = "1"

    let url: URL!
    switch tool {
    case .some("rustc"):
        url =  rustcUrl()
        break
    case .some("cargo"):
        url =  cargoUrl()
        break
    default:
        url = rustupUrl()
    }
    
    process.executableURL = url
    process.environment = environment
    process.arguments = args
    process.standardOutput = pipe
    process.standardError = pipe
    return process
}

extension Process {
    /// Runs rustup in a asynchronous manner, calling `handler` on each line returned from the process, and then runs `finally` once the process has been terminated, with rustup's status code.
    static func handleRustup(_ tool: String? = "rustup", _ channel: ToolchainChannel?, _ args: [String], handler: @escaping (String) -> (), finally: @escaping (Int32) -> ()) {
        DispatchQueue.global().async {
            let pipe = Pipe()

            pipe.fileHandleForReading.readabilityHandler = { (fileHandle) -> Void in
                let availableData = fileHandle.availableData
                
                if !availableData.isEmpty {
                    let newOutput = String.init(data: availableData, encoding: .utf8)!
                    handler(newOutput)
                    #if DEBUG
                        print(newOutput)
                    #endif
                }

            }

            let process = launchProcess(tool: tool, channel: channel, args: args, pipe: pipe)
            process.launch()
            process.waitUntilExit()
            finally(process.terminationStatus)
        }
    }
    
    /// Same as `handleRustup` except that it waits for whole output to be available first.
    static func outputRustup(_ tool: String? = "rustup", _ channel: ToolchainChannel?, _ args: [String], callback: @escaping (String) -> ()) {
        DispatchQueue.global().async {
            var bigOutputString: String = ""

            handleRustup(tool, channel, args) {
                bigOutputString.append($0)
            } finally: { _ in
                DispatchQueue.main.async {
                    callback(bigOutputString)
                }
            }
        }
    }

    static func syncRustup(_ tool: String? = "rustup", _ channel: ToolchainChannel?, _ args: [String]) throws -> String {
        let pipe = Pipe()
        let process = launchProcess(tool: tool, channel: channel, args: args, pipe: pipe)
        try! process.run()

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
        #if DEBUG
            print(output)
        #endif
        return output
    }
}
