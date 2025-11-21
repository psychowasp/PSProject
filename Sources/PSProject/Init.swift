//
//  Init.swift
//  PSProject
//
import ArgumentParser
import PathKit
import TOMLKit
import PyProjectToml
import PSTools

extension PSProject {
    struct Init: AsyncParsableCommand {
        
        static var configuration: CommandConfiguration {
            .init(
                abstract: abstractInfo,
            )
        }
        
        @Argument var path: Path
        //@Option var name: String?
        @Option var buildozer: Path?
        @Flag var cythonized: Bool = false
        
        func run() async throws {
            
            if !Validation.hostPython() { return }
            
            let btoml: TOMLTable? = if let buildozer {
                try BuildozerSpecReader(path: buildozer).export()
            } else { nil }
            let buildozer_app = btoml?["buildozer-app"]?.table
            let uv_name = buildozer_app?["package"]?["name"]?.string
            
            try await PyProjectToml.newToml(
                path: path,
                uv_name: uv_name,
                cythonized: cythonized
            )
            
        }
        
        
        
        
    }
}

