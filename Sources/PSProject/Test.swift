//
//  Test.swift
//  PSProject
//


import ArgumentParser
import XcodeProjectBuilder
import PathKit
import Backends
import PSTools
import PyProjectToml
import Yams


extension PSProject {
    struct Test: AsyncParsableCommand {
        static var configuration: CommandConfiguration {
            .init(subcommands: [
                Backend.self
            ])
        }
    }
}

extension PSProject.Test {
    struct Backend: AsyncParsableCommand {
        @Argument var path: Path
        
        @MainActor
        func run() async throws {
            
            let backend_file = if path.isDirectory {
                path + "backend.yml"
            } else { path }
            
            guard backend_file.exists else {
                fatalError("\(path) has no backend.yml")
            }
            let backend_data = try backend_file.read()
            let yml_backend = try! YAMLDecoder().decode(YamlBackend.self, from: backend_data)
            
            print(try yml_backend.exclude_dependencies())
            print(try await yml_backend.frameworks())
            print(try await yml_backend.target_dependencies(platform: .auto))
            print(try await yml_backend.packages())
            
            print(try yml_backend.wrapper_imports(platform: .iOS))
            print(try yml_backend.wrapper_imports(platform: .macOS))
            
            try await yml_backend.install(support: .temporary, platform: .iOS)
            try await yml_backend.copy_to_site_packages(site_path: .temporary, platform: .iOS, py_platform: "")
        }
    }
}
