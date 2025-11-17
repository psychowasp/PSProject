//
//  Shells.swift
//  Backends
//
import Foundation
import PathKit

extension YamlBackend.Script {
    @MainActor
    public func run() async throws {
        var env = ProcessInfo.processInfo.environment
        switch shell {
            case .python:
                try? await PythonRunnable(exec: exec, root: .current).run(env: env)
            default:
                try? await ShellRunnable(exec: exec, shell: shell).run(env: env)
        }
    }
    
    
    
    
}

extension YamlBackend.Script.ShellType {
    var path: Path {
        switch self {
            case .python:
                .hostPython + "bin/python3"
            case .sh:
                "/bin/sh"
            case .zsh:
                "/bin/zsh"
            case .bash:
                "/bin/bash"
            case .fish:
                "/bin/fish"
            case .ruby:
                "/usr/bin/ruby"
        }
    }
}

extension YamlBackend.Script {
    struct PythonRunnable {
        let exec: Execution
        let root: Path
        
        func run(env: [String:String]?) async throws {
            
            let proc = Process()
            proc.executablePath = (.hostPython + "bin/python3")
            proc.environment = env
            var arguments: [String]
            switch exec {
                case .file(let path):
                    let full_path = root + path
                    guard full_path.exists else {
                        print("\(full_path) not found")
                        return
                    }
                    arguments = [full_path.string]
                case .run(let code):
                   arguments = ["-c", code]
            }
            //print(arguments)
            proc.arguments = arguments
            try! proc.run()
            try proc.waitUntilExit()
        }
    }
    
    struct ShellRunnable {
        let exec: Execution
        let shell: ShellType
        func run(env: [String:String]?) async throws {
            
            let proc = Process()
            guard shell.path.exists else { return }
            proc.executablePath = shell.path
            proc.environment = env
            var arguments: [String]
            switch exec {
                case .file(let path):
                    //[path]
                    return
                case .run(let code):
                    if shell == .ruby {
                        arguments = ["-e", code]
                    } else {
                        arguments = ["-c", code]
                    }
            }
            //print(arguments)
            proc.arguments = arguments
            try! proc.run()
            try proc.waitUntilExit()
        }
    }
}
